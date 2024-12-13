#!/bin/bash


CUR_DIR=`pwd`
LIB_SRC="${CUR_DIR}/src"
OUTPUT="${CUR_DIR}/output"
V_CFLAGS="-O3 -D__STDC_INT64__ -fno-exceptions -fno-short-wchar -fno-short-enums -fembed-bitcode"
V_CONFIG_PREFIX="--enable-static=yes --enable-shared=no"

function buildiOS {
	
	unset CXX
	unset CC
	unset CFLAGS
	unset CXXFLAGS
	unset LDFLAGS
	DEVELOPER="$(xcode-select --print-path)"
	SDKROOT="$(xcodebuild -version -sdk $4 | grep -E '^Path' | sed 's/Path: //')"
	ARCH=$2
	V_CXXFLAGS="${V_CFLAGS} -std=gnu++11"
	export CXX="${DEVELOPER}/usr/bin/g++"
	export CC="${DEVELOPER}/usr/bin/gcc"
	export CFLAGS="-isysroot ${SDKROOT} -I${SDKROOT}/usr/include/ -I./include/ -arch ${ARCH} -fembed-bitcode -miphoneos-version-min=9.0 ${V_CFLAGS}"
	export CXXFLAGS="${V_CXXFLAGS} -stdlib=libc++ -fembed-bitcode -isysroot ${SDKROOT} -I${SDKROOT}/usr/include/ -I./include/ -arch ${ARCH} -miphoneos-version-min=9.0"
	export LDFLAGS="-stdlib=libc++ -L${SDKROOT}/usr/lib/ -fembed-bitcode -isysroot ${SDKROOT} -Wl,-dead_strip -miphoneos-version-min=9.0 -lstdc++"
	cd ${LIB_SRC}
	make clean
	./configure --host=$3 ${V_CONFIG_PREFIX} --prefix=${CUR_DIR}/prefix/${2}
	make -silent
	make install
	cd ${CUR_DIR}
}

function combine {
	mkdir ${OUTPUT}
	DEVELOPER="$(xcode-select --print-path)"
	DEVROOT=${DEVELOPER}/Toolchains/XcodeDefault.xctoolchain
	${DEVROOT}/usr/bin/lipo -arch x86_64 ${CUR_DIR}/prefix/x86_64/lib/libmcrypt.a -arch arm64 ${CUR_DIR}/prefix/arm64/lib/libmcrypt.a -arch armv7 ${CUR_DIR}/prefix/armv7/lib/libmcrypt.a -output ${OUTPUT}/libmcrypt.a -create
}


buildiOS "x86_64" "x86_64" "i386-apple-darwin" "iphonesimulator"
buildiOS "armv7" "armv7" "arm-apple-darwin" "iphoneos"
buildiOS "arm64" "arm64" "arm-apple-darwin" "iphoneos"
combine