: ${IPHONE_SDKVERSION:=`xcodebuild -showsdks | grep iphoneos | egrep "[[:digit:]]+\.[[:digit:]]+" -o | tail -1`}
: ${MIN_IPHONE_SDKVERSION:=9.0}
: ${XCODE_ROOT:=`xcode-select -print-path`}
DEVROOT=${XCODE_ROOT}/Toolchains/XcodeDefault.xctoolchain
: ${PREFIXDIR:=`pwd`/prefix}
LIB_SRC=`pwd`/src
ROOT=`pwd`
build(){
	cd $LIB_SRC
    make clean
	make distclean
	ARCH=$1
	HOST=$2
	PLATFORM=$3
	export DEVROOT="$XCODE_ROOT/Platforms/$PLATFORM.platform/Developer"
	export SDKROOT="${DEVROOT}/SDKs/${PLATFORM}${IPHONE_SDKVERSION}.sdk"
	export LD=${DEVROOT}/usr/bin/ld
	export CC=${XCODE_ROOT}/usr/bin/gcc
	export CXX=${XCODE_ROOT}/usr/bin/g++
	export AR=${XCODE_ROOT}/Toolchains/XcodeDefault.xctoolchain/usr/bin/ar
	export AS=${XCODE_ROOT}/Toolchains/XcodeDefault.xctoolchain/usr/bin/as
	export NM=${XCODE_ROOT}/Toolchains/XcodeDefault.xctoolchain/usr/bin/nm
	export RANLIB=${XCODE_ROOT}/Toolchains/XcodeDefault.xctoolchain/usr/bin/ranlib
	export LDFLAGS="-arch ${ARCH} -pipe -no-cpp-precomp -isysroot ${SDKROOT} -miphoneos-version-min=${MIN_IPHONE_SDKVERSION}"
	export CFLAGS="-arch ${ARCH} -pipe -no-cpp-precomp -fembed-bitcode -isysroot ${SDKROOT} -miphoneos-version-min=${MIN_IPHONE_SDKVERSION}"
	export CPPFLAGS="-arch ${ARCH} -pipe -no-cpp-precomp -isysroot ${SDKROOT} -miphoneos-version-min=${MIN_IPHONE_SDKVERSION}"
	./configure --host=${HOST} --prefix=$PREFIXDIR/${ARCH} --disable-shared --enable-static --enable-utf8 --enable-unicode
	make -silent
	make install
	echo "================================================================="
	echo "Done"
	echo "================================================================="
}

makeOutput(){
	cp -Rf "$PREFIXDIR/arm64/" "$ROOT/output"
	find "$ROOT/output/lib/" -name '*.a' -delete
	${DEVROOT}/usr/bin/lipo \
	-arch x86_64 ${PREFIXDIR}/x86_64/lib/libpcre2-8.a \
	-arch arm64 ${PREFIXDIR}/arm64/lib/libpcre2-8.a \
	-arch armv7 ${PREFIXDIR}/armv7/lib/libpcre2-8.a \
	-output $ROOT/output/lib/libpcre2-8.a -create
	
	${DEVROOT}/usr/bin/lipo \
	-arch x86_64 ${PREFIXDIR}/x86_64/lib/libpcre2-posix.a \
	-arch arm64 ${PREFIXDIR}/arm64/lib/libpcre2-posix.a \
	-arch armv7 ${PREFIXDIR}/armv7/lib/libpcre2-posix.a \
	-output $ROOT/output/lib/libpcre2-posix.a -create
	
}

build x86_64 i386-apple-darwin10 iPhoneSimulator
build armv7 arm-apple-darwin iPhoneOS
build arm64 arm-apple-darwin iPhoneOS
makeOutput

#cd $LIB_SRC
#make clean
#make distclean