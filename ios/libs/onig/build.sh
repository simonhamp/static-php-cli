: ${IPHONE_SDKVERSION:=`xcodebuild -showsdks | grep iphoneos | egrep "[[:digit:]]+\.[[:digit:]]+" -o | tail -1`}
: ${MIN_IPHONE_SDKVERSION:=9.0}
: ${XCODE_ROOT:=`xcode-select -print-path`}
DEVROOT=${XCODE_ROOT}/Toolchains/XcodeDefault.xctoolchain
: ${PREFIXDIR:=`pwd`/prefix}
LIB_SRC=`pwd`/src
ROOT=`pwd`
build(){
	ARCH=$1
	HOST=$2
	PLATFORM=$3
	cd $LIB_SRC
	#CC=$XCODE_ROOT/Platforms/$PLATFORM.platform/Developer/usr/bin/gcc
	#CPP=$XCODE_ROOT/Platforms/$PLATFORM.platform/Developer/usr/bin/cpp
	#AR=$XCODE_ROOT/Platforms/$PLATFORM.platform/Developer/usr/bin/ar
	
	export CC="$XCODE_ROOT/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang"
	export AR="$XCODE_ROOT/Toolchains/XcodeDefault.xctoolchain/usr/bin/ar"

	
	export CFLAGS="-arch $ARCH -fembed-bitcode -isysroot $XCODE_ROOT/Platforms/$PLATFORM.platform/Developer/SDKs/$PLATFORM${IPHONE_SDKVERSION}.sdk -miphoneos-version-min=${MIN_IPHONE_SDKVERSION} -Wno-error-implicit-function-declaration -D_REENTRANT"
	make clean
	make distclean
	./configure --prefix=$PREFIXDIR/${ARCH} --host=$HOST --disable-shared --enable-static
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
	-arch x86_64 ${PREFIXDIR}/x86_64/lib/libonig.a \
	-arch arm64 ${PREFIXDIR}/arm64/lib/libonig.a \
	-arch armv7 ${PREFIXDIR}/armv7/lib/libonig.a \
	-output $ROOT/output/lib/libonig.a -create
}

cd $LIB_SRC
autoreconf -vfi
build x86_64 i386-apple-darwin10 iPhoneSimulator
build armv7 arm-apple-darwin iPhoneOS
build arm64 arm-apple-darwin iPhoneOS
makeOutput


