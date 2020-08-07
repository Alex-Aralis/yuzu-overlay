# Copyright 2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="A Nintendo Switch emulator"
HOMEPAGE="https://yuzu-emu.org/"
SRC_URI=""
LICENSE="GPL-2+"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="+compat-list compat-reporting +system-xbyak +system-opus +system-qt5 early-access mainline gui desktop cli test qt-translations generic abi_x86_32 abi_x86_64 +sdl2 qt-webengine qt5 +boxcat +webservice +discord +cubeb vulkan"
REQUIRED_USE="
	!qt5? ( !qt-webengine  !qt-translations !system-qt5 )
	!gui? ( !desktop !qt5 )
	|| ( gui cli test )
	^^ ( mainline early-access )
"
RESTRICT="
	!early-access? ( !mainline? ( fetch ) )
	!test? ( test )
"

DEPEND=""
BDEPEND="
	early-access? (
		app-misc/jq
		net-misc/curl
	)
	mainline? (
		app-misc/jq
		net-misc/curl
	)
	gnome-base/librsvg
"
RDEPEND="
	system-qt5? (
		qt5? ( >=dev-qt/qtwidgets-5.9:5 )
		qt-translations? ( >=dev-qt/qttranslations-5.9:5 )
		qt-webengine? ( >=dev-qt/qtwebengine-5.9:5[widgets] )
	)
	system-xbyak? (
		abi_x86_64? ( !generic? ( >=dev-libs/xbyak-5.91 ) )
		abi_x86_32? ( !generic? ( >=dev-libs/xbyak-5.91 ) )
	)
	discord? ( >=dev-libs/rapidjson-1.1.0 )
	system-opus? ( >=media-libs/opus-1.3.1 )
	sdl2? ( media-libs/libsdl2 )
	>=app-arch/lz4-1.8
	>=dev-cpp/catch-2.13
	>=dev-cpp/nlohmann_json-3.8
	>=app-arch/zstd-1.4
	>=sys-libs/zlib-1.2
	>=dev-libs/libfmt-7.0
	>=dev-libs/boost-1.73[context]
	>=dev-libs/libzip-1.5
	${DEPEND}
"

PYTHON_COMPAT=( python2_7 )

inherit xdg cmake python-single-r1 git-r3

EGIT_REPO_URI="https://github.com/yuzu-emu/yuzu.git"
EGIT_SUBMODULES=( '*' )
YUZU_VARIANT=${PN##*-}

if [[ ${PV} == 9999 ]]; then
	EGIT_BRANCH="master"
else
	EGIT_COMMIT=${PV}
fi

src_unpack() {
	git-r3_src_unpack

	pushd "${S}"

	if use early-access; then
		mkdir "${T}/patches"
		local patches=$(curl -s https://api.github.com/repos/yuzu-emu/yuzu/pulls?per_page=1000 | jq ".[] | [.number, .labels[].name]" -c | awk -F',' '/(mainline-merge|early-access-merge)/ {print substr($1,2)}' | sort)

		for p in $patches; do
			einfo "Fetching PR #$p \n"
			curl -sL https://github.com/yuzu-emu/yuzu/pull/$p.diff > "${T}/patches/${p}.patch"
		done
	fi

	if use mainline; then
		mkdir "${T}/patches"
		local patches=$(curl -s https://api.github.com/repos/yuzu-emu/yuzu/pulls?per_page=1000 | jq ".[] | [.number, .labels[].name]" -c | awk -F',' '/mainline-merge/ {print substr($1,2)}' | sort)

		for p in $patches; do
			einfo "Fetching PR #$p \n"
			curl -Ls https://github.com/yuzu-emu/yuzu/pull/$p.diff > "${T}/patches/${p}.patch"
		done
	fi

	if use compat-list; then
		local compat_path="${BUILD_DIR}/dist/compatibility_list"
		mkdir -p "${compat_path}"
		curl -Ls https://api.yuzu-emu.org/gamedb/ > "${compat_path}/compatibility_list.json"
	fi

	popd
}

src_prepare() {
	eapply "${FILESDIR}"/{fix-cmake,static-externals,inject-git-info}.patch

	if use desktop; then
		eapply "${FILESDIR}/mime-type.patch"
	fi

	if [[ $YUZU_VARIANT == dev ]] && use desktop; then
		eapply "${FILESDIR}"/{dev-metadata,gentoo-icon}.patch

		# Regenerate the yuzu.png from the svg icon after patching with gentoo-icon.patch
		rsvg-convert -h 256 -w 256 "${S}/dist/yuzu.svg" > "${S}/dist/qt_themes/default/icons/256x256/yuzu.png"
	fi

	if use system-xbyak; then
		eapply "${FILESDIR}/unbundle-xbyak.patch"
	fi

	if use system-opus; then
		eapply "${FILESDIR}/unbundle-opus.patch"
	fi

	if use discord; then
		eapply "${FILESDIR}/unbundle-rapidjson.patch"
	fi

	if use vulkan; then
		eapply "${FILESDIR}/fix-vulkan.patch"
	fi

	if use early-access; then
		rm "${T}"/patches/{4352,4397}.patch || true
	fi

	if use early-access || use mainline; then
		# Apply all patches stored in tmp
		eapply "${T}"/patches/*.patch
	fi

	cmake_src_prepare
	xdg_src_prepare
}

src_configure() {
	local mycmakeargs=(
		-DGIT_REV="${PV}"
		-DBUILD_FULLNAME="${EGIT_BRANCH:-$EGIT_COMMIT}"
		-DGIT_BRANCH="${PN}"
		-DGIT_DESC="${PV}"
		-DCMAKE_INSTALL_PREFIX="${D}/usr"
		-DUSE_DISCORD_PRESENCE=$(usex discord ON OFF)
		-DENABLE_CUBEB=$(usex cubeb ON OFF)
		-DENABLE_WEB_SERVICE=$(usex webservice ON OFF)
		-DENABLE_VULKAN=$(usex vulkan ON OFF)
		-DENABLE_SDL2=$(usex sdl2 ON OFF)
		-DYUZU_ENABLE_BOXCAT=$(usex boxcat ON OFF)
		-DYUZU_USE_BUNDLED_UNICORN=ON
		-DENABLE_QT=$(usex qt5 ON OFF)
		-DYUZU_USE_BUNDLED_QT=$(usex !system-qt5 ON OFF)
		-DYUZU_USE_QT_WEB_ENGINE=$(usex qt-webengine ON OFF)
		-DENABLE_QT_TRANSLATION=$(usex qt-translations ON OFF)
		-DENABLE_COMPATIBILITY_LIST_DOWNLOAD=$(usex compat-list ON OFF)
		-DYUZU_ENABLE_COMPATIBILITY_REPORTING=$(usex compat-reporting ON OFF)
	)

	cmake_src_configure
}

src_compile() {
	cmake_src_compile $(usex gui yuzu "") $(usex cli yuzu-cmd "") $(usex test "tests yuzu-tester" "")
}

src_install() {
	debug-print-function ${FUNCNAME} "$@"

	_cmake_check_build_dir
	pushd "${BUILD_DIR}" > /dev/null || die

	local install_component="$CMAKE_BINARY --install . --component "

	# Do component installs
	use gui && $install_component yuzu
	use desktop && $install_component desktop
	use cli && $install_component yuzu-cmd
	use test && $install_component yuzu-tester

	popd > /dev/null || die

	# Rename files if varaint.
	if [[ -n $YUZU_VARIANT ]]; then
		for f in $(find "${D}" -type f); do
			local file_name=${f##*/}
			local file_path=${f%/*}
			local file_base=${file_name%.*}
			local file_ext=${file_name##*.}
			local variant_suffix=${YUZU_VARIANT:+-}${YUZU_VARIANT}

			# Special case for dot files
			if [[ $file_name =~ ^\.[^\.]*$ ]]; then
				local destination="${file_path}/${file_name}${variant_suffix}"

			# If has ext
			elif [[ $file_name =~ \. ]]; then
				local destination="${file_path}/${file_base}${variant_suffix}.${file_ext}"

			# Not dot, no extension
			else
				local destination="${file_path}/${file_name}${variant_suffix}"
			fi

			mv "$f" "$destination"
		done
	fi

	# Try to install docs
	pushd "${S}" > /dev/null || die
	einstalldocs
	popd > /dev/null || die
}
