#!/bin/bash

FILE="icu-release-57-1"
CUR_DIR=`pwd`
ICU_SRC="${CUR_DIR}/src/source"
OUTPUT="${CUR_DIR}/output"
V_CFLAGS="-O3 -D__STDC_INT64__ -fno-exceptions -fno-short-wchar -fno-short-enums -fembed-bitcode"
V_CONFIG_PREFIX=" --enable-extras=no \
--enable-tools=yes \
--enable-icuio=yes \
--enable-strict=no \
--enable-static \
--enable-shared=no \
--enable-tests=no \
--disable-renaming \
--enable-samples=no \
--enable-dyload=no \
--with-data-packaging=static"
function extractAndPatch {
	#will set value to 1
	defines_config_set_1=( \
	"U_DISABLE_RENAMING" \
	"UCONFIG_NO_LEGACY_CONVERSION" \
	"CONFIG_NO_CONVERSION" \
	)
	#will set value to 0
	defines_config_set_0=( \
	"U_HAVE_NL_LANGINFO_CODESET" \
	"UCONFIG_NO_TRANSLITERATION" \
	"U_USING_ICU_NAMESPACE" \
	"UCONFIG_NO_COLLATION" \
	"UCONFIG_NO_FORMATTING" \
	"UCONFIG_NO_REGULAR_EXPRESSIONS" \
	"UCONFIG_NO_BREAK_ITERATION" \
	)
	#will set value to 1
	defines_utypes=( \
	"U_CHARSET_IS_UTF8" \
	)
	rm -rf "${CUR_DIR}/src"
	
	if [ ! -d "${CUR_DIR}/srcAll" ] ; then
		unzip -q -d "${CUR_DIR}/srcAll" "${FILE}.zip"
	fi
	
	cp -r "${CUR_DIR}/srcAll/${FILE}/icu4c" "${CUR_DIR}/src"
	cp "${ICU_SRC}/common/unicode/uconfig" "${ICU_SRC}/common/unicode/uconfig.h" 2>/dev/null
	cp "${ICU_SRC}/common/unicode/uconfig.h" "${ICU_SRC}/common/unicode/uconfig" 2>/dev/null
	for var in "${defines_config_set_1[@]}"
	do
	sed "/define __UCONFIG_H__/a \\
	#ifndef ${var} \\
	#define ${var} 1 \\
	#endif \\
	" "${ICU_SRC}/common/unicode/uconfig.h" > "${ICU_SRC}/common/unicode/uconfig.tmp"
	mv "${ICU_SRC}/common/unicode/uconfig.tmp" "${ICU_SRC}/common/unicode/uconfig.h"
	done
	for var in "${defines_config_set_0[@]}"
	do
	sed "/define __UCONFIG_H__/a \\
	#ifndef ${var} \\
	#define ${var} 0 \\
	#endif \\
	" "${ICU_SRC}/common/unicode/uconfig.h" > "${ICU_SRC}/common/unicode/uconfig.tmp"
	mv "${ICU_SRC}/common/unicode/uconfig.tmp" "${ICU_SRC}/common/unicode/uconfig.h"
	done
	cp "${ICU_SRC}/common/unicode/utypes" "${ICU_SRC}/common/unicode/utypes.h" 2>/dev/null
	cp "${ICU_SRC}/common/unicode/utypes.h" "${ICU_SRC}/common/unicode/utypes" 2>/dev/null
	for var in "${defines_utypes[@]}"
	do
	sed "/define UTYPES_H/a \\
	#ifndef ${var} \\
	#define ${var} 1 \\
	#endif \\
	" "${ICU_SRC}/common/unicode/utypes.h" > "${ICU_SRC}/common/unicode/utypes.tmp"
	mv "${ICU_SRC}/common/unicode/utypes.tmp" "${ICU_SRC}/common/unicode/utypes.h"
	done
	cp "${ICU_SRC}/tools/pkgdata/pkgdata" "${ICU_SRC}/tools/pkgdata/pkgdata.cpp" 2>/dev/null
	cp "${ICU_SRC}/tools/pkgdata/pkgdata.cpp" "${ICU_SRC}/tools/pkgdata/pkgdata" 2>/dev/null
	sed "s/int result = system(cmd);/ \\
	#if defined(IOS_SYSTEM_FIX) \\
	pid_t pid; \\
	char * argv[2]; argv[0] = cmd; argv[1] = NULL; \\
	posix_spawn(\&pid, argv[0], NULL, NULL, argv, environ); \\
	waitpid(pid, NULL, 0); \\
	int result = 0; \\
	#else \\
	int result = system(cmd); \\
	#endif \\
	/g" "${ICU_SRC}/tools/pkgdata/pkgdata.cpp" > "${ICU_SRC}/tools/pkgdata/pkgdata.tmp"

	sed "/#include <stdlib.h>/a \\
	#if defined(IOS_SYSTEM_FIX) \\
	#include <spawn.h> \\
	extern char **environ; \\
	#endif \\
	" "${ICU_SRC}/tools/pkgdata/pkgdata.tmp" > "${ICU_SRC}/tools/pkgdata/pkgdata.cpp"
}

function buildMac {
	rm -rf ${OUTPUT}
	export PLATFORM_PREFIX="${OUTPUT}/mac"
	export CPPFLAGS=${V_CFLAGS}
	export CXXFLAGS="${V_CFLAGS} -std=gnu++11"
	PREBUILD="${OUTPUT}/macPrebuild"
	mkdir -p ${PREBUILD}
	cd ${PREBUILD}
	export ICU_DATA_FILTER_FILE="${CUR_DIR}/filters.json"
	sh ${ICU_SRC}/runConfigureICU MacOSX --prefix=${PLATFORM_PREFIX} ${V_CONFIG_PREFIX}
	make clean
	make -j4
	#make install
	cd ${CUR_DIR}
}

function buildiOS {
	PREBUILD="${OUTPUT}/iosPrebuild-${2}"
	rm -rf ${PREBUILD}
	unset CXX
	unset CC
	unset CFLAGS
	unset CXXFLAGS
	unset LDFLAGS
	DEVELOPER="$(xcode-select --print-path)"
	SDKROOT="$(xcodebuild -version -sdk $4 | grep -E '^Path' | sed 's/Path: //')"
	ARCH=$2
	ICU_FLAGS="-I${ICU_SRC}/common/ -I${ICU_SRC}/tools/tzcode/ "
	V_CXXFLAGS="${V_CFLAGS} -std=gnu++11"
	export ICU_DATA_FILTER_FILE="${CUR_DIR}/filters.json"
	export ADDITION_FLAG="-DIOS_SYSTEM_FIX"
	export CXX="${DEVELOPER}/usr/bin/g++"
	export CC="${DEVELOPER}/usr/bin/gcc"
	export CFLAGS="-isysroot ${SDKROOT} -I${SDKROOT}/usr/include/ -I./include/ -arch ${ARCH} -fembed-bitcode -miphoneos-version-min=9.0 ${ICU_FLAGS} ${V_CFLAGS} ${ADDITION_FLAG}"
	export CXXFLAGS="${V_CXXFLAGS} -stdlib=libc++ -fembed-bitcode -isysroot ${SDKROOT} -I${SDKROOT}/usr/include/ -I./include/ -arch ${ARCH} -miphoneos-version-min=9.0 ${ICU_FLAGS} ${ADDITION_FLAG}"
	export LDFLAGS="-stdlib=libc++ -L${SDKROOT}/usr/lib/ -fembed-bitcode -isysroot ${SDKROOT} -Wl,-dead_strip -miphoneos-version-min=9.0 -lstdc++ ${ADDITION_FLAG}"
	mkdir -p ${PREBUILD}
	cd ${PREBUILD}
	sh ${ICU_SRC}/configure --host=$3 --with-cross-build=${OUTPUT}/macPrebuild ${V_CONFIG_PREFIX} --prefix=${CUR_DIR}/prefix/${2}
	make clean
	make -j4
	make install
	cd ${CUR_DIR}
}

function combine {
	DEVELOPER="$(xcode-select --print-path)"
	DEVROOT=${DEVELOPER}/Toolchains/XcodeDefault.xctoolchain
	${DEVROOT}/usr/bin/lipo -arch x86_64 ${CUR_DIR}/prefix/x86_64/lib/libicudata.a -arch arm64 ${CUR_DIR}/prefix/arm64/lib/libicudata.a -arch armv7 ${CUR_DIR}/prefix/armv7/lib/libicudata.a -output ${OUTPUT}/libicudata.a -create
	${DEVROOT}/usr/bin/lipo -arch x86_64 ${CUR_DIR}/prefix/x86_64/lib/libicui18n.a -arch arm64 ${CUR_DIR}/prefix/arm64/lib/libicui18n.a -arch armv7 ${CUR_DIR}/prefix/armv7/lib/libicui18n.a -output ${OUTPUT}/libicui18n.a -create
	${DEVROOT}/usr/bin/lipo -arch x86_64 ${CUR_DIR}/prefix/x86_64/lib/libicuio.a -arch arm64 ${CUR_DIR}/prefix/arm64/lib/libicuio.a -arch armv7 ${CUR_DIR}/prefix/armv7/lib/libicuio.a -output ${OUTPUT}/libicuio.a -create
	${DEVROOT}/usr/bin/lipo -arch x86_64 ${CUR_DIR}/prefix/x86_64/lib/libicuuc.a -arch arm64 ${CUR_DIR}/prefix/arm64/lib/libicuuc.a -arch armv7 ${CUR_DIR}/prefix/armv7/lib/libicuuc.a -output ${OUTPUT}/libicuuc.a -create	
}

function clean {
	rm -rf "${CUR_DIR}/src"
	rm -rf "${CUR_DIR}/srcAll"
	rm -rf "${CUR_DIR}/output/iosPrebuild-x86_64"
	rm -rf "${CUR_DIR}/output/iosPrebuild-armv7"
	rm -rf "${CUR_DIR}/output/iosPrebuild-arm64"
	#rm -rf "${CUR_DIR}/output/mac"
	rm -rf "${CUR_DIR}/output/macPrebuild"
}

extractAndPatch
buildMac
buildiOS "x86_64" "x86_64" "i386-apple-darwin" "iphonesimulator"
buildiOS "armv7" "armv7" "arm-apple-darwin" "iphoneos"
buildiOS "arm64" "arm64" "arm-apple-darwin" "iphoneos"
combine
# clean


#buildiOS "armv7" "armv7" "armv7-apple-darwin" "iphoneos"
#buildiOS "arm64" "arm64" "aarch64-apple-darwin" "iphoneos"
