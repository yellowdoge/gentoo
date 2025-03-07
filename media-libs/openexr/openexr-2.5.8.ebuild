# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

CMAKE_ECLASS=cmake
inherit cmake-multilib

DESCRIPTION="ILM's OpenEXR high dynamic-range image file format libraries"
HOMEPAGE="https://www.openexr.com/"
SRC_URI="https://github.com/AcademySoftwareFoundation/openexr/archive/v${PV}.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}/${P}/OpenEXR"

LICENSE="BSD"
SLOT="0/25" # based on SONAME
# -ppc -sparc because broken on big endian, bug #818424
KEYWORDS="amd64 ~arm arm64 ~ia64 -ppc ~ppc64 ~riscv -sparc x86 ~amd64-linux ~x86-linux ~x64-macos ~x86-solaris"
IUSE="cpu_flags_x86_avx doc examples static-libs utils test"
RESTRICT="!test? ( test )"

RDEPEND="
	~media-libs/ilmbase-${PV}:=[static-libs?,${MULTILIB_USEDEP}]
	sys-libs/zlib[${MULTILIB_USEDEP}]
"
DEPEND="${RDEPEND}"
BDEPEND="virtual/pkgconfig"

DOCS=( PATENTS README.md )

src_prepare() {
	# Fix path for testsuite
	sed -i -e "s:/var/tmp/:${T}:" "${S}"/IlmImfTest/tmpDir.h || die "failed to set temp path for tests"

	# disable failing tests on various arches
	if use test; then
		if use abi_x86_32; then
			eapply "${FILESDIR}/${PN}-2.5.2-0001-IlmImfTest-main.cpp-disable-tests.patch"
		fi

		# Technically this doesn't disable anything, it just gives this test time to complete.
		# Could probably be applied unconditionally but will leave this to the maintainers.
		if use riscv; then
			eapply "${FILESDIR}/${P}-0002-increase-IlmImfTest-timeout.patch"
		fi

		if use sparc; then
			eapply "${FILESDIR}/${P}-0001-disable-testRgba-on-sparc.patch"
		fi
	fi

	multilib_foreach_abi cmake_src_prepare
}

multilib_src_configure() {
	local mycmakeargs=(
		-DBUILD_TESTING=$(usex test)
		-DINSTALL_OPENEXR_DOCS=$(usex doc)
		-DINSTALL_OPENEXR_EXAMPLES=$(usex examples)
		-DOPENEXR_BUILD_BOTH_STATIC_SHARED=$(usex static-libs)
		-DOPENEXR_BUILD_UTILS=$(usex utils)
		-DOPENEXR_INSTALL_PKG_CONFIG=ON
		-DOPENEXR_USE_CLANG_TIDY=OFF		# don't look for clang-tidy
	)

	cmake_src_configure
}

multilib_src_install_all() {
	if use doc; then
		DOCS+=( doc/*.pdf )
	fi
	einstalldocs

	use examples && docompress -x /usr/share/doc/${PF}/examples
}
