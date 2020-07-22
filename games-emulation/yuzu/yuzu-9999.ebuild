# Copyright 2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="A Nintendo Switch emulator"
HOMEPAGE="https://yuzu-emu.org/"
SRC_URI="https://github.com/yuzu-emu/yuzu-mainline/releases/download/mainline-0-317/yuzu-linux-20200716-67db767dc.tar.xz"

LICENSE="GPL-2+"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="+gui +desktop cli test qt-translations bundled-qt5 generic static abi_x86_32 abi_x86_64 +sdl2 qt-webengine +qt5 +boxcat +webservice discord +cubeb vulkan"
REQUIRED_USE="
	!qt5? ( !bundled-qt5 ( !qt-webengine  !qt-translations ) )
	!gui? ( !desktop !qt5 !bundled-qt5 )
	|| ( gui cli test )
"
DEPEND=""

RDEPEND="
	!bundled-qt5? (
		qt5? ( >=dev-qt/qtwidgets-5.9:5 )
		qt-translations? ( >=dev-qt/qttranslations-5.9:5 )
		qt-webengine? ( >=dev-qt/qtwebengine-5.9:5[widgets] )
	)
	sdl2? ( media-libs/libsdl2 )
	abi_x86_64? ( !generic? ( >=dev-libs/xbyak-5.91 ) )
	abi_x86_32? ( !generic? ( >=dev-libs/xbyak-5.91 ) )
	>=media-libs/opus-1.3.1
	>=app-arch/lz4-1.8
	>=dev-cpp/catch-2.11
	>=dev-cpp/nlohmann_json-3.7
	>=app-arch/zstd-1.4
	>=sys-libs/zlib-1.2
	>=dev-libs/libfmt-7.0
	>=dev-libs/boost-1.71[context]
	>=dev-libs/libzip-1.5
	${DEPEND}
"

BDEPEND="
	sys-devel/make
"

PYTHON_COMPAT=( python2_7 )

inherit xdg cmake python-single-r1 git-r3

EGIT_REPO_URI="https://github.com/yuzu-emu/yuzu-mainline.git"

if [[ ${PV} == "9999" ]]; then
	EGIT_BRANCH="master"
else
	EGIT_COMMIT="${PV}"
fi

src_prepare() {
	eapply "${FILESDIR}/cmake.patch"
	use static && append-fflags -static && append-ldflags -static

	pushd "${S}/externals/unicorn"
		emake clean
	popd

	cmake_src_prepare
	xdg_src_prepare
}

src_configure() {
	CMAKE_BUILD_TYPE=Release

	local mycmakeargs=(
		-DCMAKE_INSTALL_PREFIX="${D}/usr"
		-DUSE_DISCORD_PRESENCE=$(usex discord ON OFF)
		-DENABLE_CUBEB=$(usex cubeb ON OFF)
		-DENABLE_WEB_SERVICE=$(usex webservice ON OFF)
		-DENABLE_VULKAN=$(usex vulkan ON OFF)
		-DENABLE_SDL2=$(usex sdl2 ON OFF)
		-DYUZU_ENABLE_BOXCAT=$(usex boxcat ON OFF)
		-DYUZU_USE_BUNDLED_UNICORN=ON
		-DENABLE_QT=$(usex qt5 ON OFF)
		-DYUZU_USE_BUNDLED_QT=$(usex bundled-qt5 ON OFF)
		-DYUZU_USE_QT_WEB_ENGINE=$(usex qt-webengine ON OFF)
		-DENABLE_QT_TRANSLATION=$(usex qt-translations ON OFF)
	)

	cmake_src_configure
}

src_compile() {
	cmake_src_compile $(usex gui yuzu "") $(usex cli yuzu-cmd "") $(usex test yuzu-tester "")
}

src_install() {
	debug-print-function ${FUNCNAME} "$@"

	_cmake_check_build_dir
	pushd "${BUILD_DIR}" > /dev/null || die

	install_component="$CMAKE_BINARY --install . --component "

	# Do component installs
	use gui && $install_component yuzu
	use desktop && $install_component desktop
	use cli && $install_component yuzu-cmd
	use test && $install_component yuzu-tester

	popd > /dev/null || die

	# Try to install docs
	pushd "${S}" > /dev/null || die
	einstalldocs
	popd > /dev/null || die

	unset install_component
}
