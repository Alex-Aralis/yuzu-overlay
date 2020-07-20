# Copyright 2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="A Nintendo Switch emulator"
HOMEPAGE="https://yuzu-emu.org/"
SRC_URI="https://github.com/yuzu-emu/yuzu-mainline/releases/download/mainline-0-317/yuzu-linux-20200716-67db767dc.tar.xz"

LICENSE="GPL-2+"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="qt_translation docs bundled_qt generic abi_x86_32 abi_x86_64 +sdl2 +qt_web_engine +qt +boxcat +webservice discord +cubeb vulkan"
REQUIRED_USE="!qt? ( !bundled_qt ( !qt_web_engine  !qt_translation ) )"
DEPEND=""

RDEPEND="
	!bundled_qt? (
		qt? ( >=dev-qt/qtwidgets-5.9:5 )
		qt_translation? ( >=dev-qt/qttranslations-5.9:5 )
		qt_web_engine? ( >=dev-qt/qtwebengine-5.9:5[widgets] )
	)
	sdl2? ( media-libs/libsdl2 )
	abi_x86_64? ( !generic? ( >=dev-libs/xbyak-5.91 ) )
	abi_x86_32? ( !generic? ( >=dev-libs/xbyak-5.91 ) )
	docs? ( app-doc/doxygen[dot] )
	>=media-libs/opus-1.3.1
	>=app-arch/lz4-1.8
	>=dev-cpp/catch-2.11
	>=dev-cpp/nlohmann_json-3.7
	>=sys-libs/zlib-1.2
	>=app-arch/zstd-1.4
	>=dev-libs/libfmt-7.0
	>=dev-libs/boost-1.71[context]
	>=dev-libs/libzip-1.5
	${DEPEND}
"

BDEPEND="
	sys-devel/make
"

PYTHON_COMPAT=( python2_7 )

inherit cmake python-single-r1

if [[ ${PV} == "9999" ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/yuzu-emu/yuzu-mainline.git"
	EGET_BRANCH="master"
	SRC_URI=""
fi

src_prepare() {
	eapply "${FILESDIR}/cmake.patch"

	pushd "${S}/externals/unicorn"
		emake clean
	popd

	cmake_src_prepare
}

src_configure() {
	local mycmakeargs=(
		-DUSE_DISCORD_PRESENCE=$(usex discord ON OFF)
		-DENABLE_QT=$(usex qt ON OFF)
		-DENABLE_CUBEB=$(usex cubeb ON OFF)
		-DENABLE_WEB_SERVICE=$(usex webservice ON OFF)
		-DENABLE_VULKAN=$(usex vulkan ON OFF)
		-DENABLE_SDL2=$(usex sdl2 ON OFF)
		-DYUZU_ENABLE_BOXCAT=$(usex boxcat ON OFF)
		-DYUZU_USE_QT_WEB_ENGINE=$(usex qt_web_engine ON OFF)
		-DYUZU_USE_BUNDLED_UNICORN=ON
		-DYUZU_USE_BUNDLED_QT=$(usex bundled_qt ON OFF)
	)

	cmake_src_configure
}
