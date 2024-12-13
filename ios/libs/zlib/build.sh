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
	export CC=$XCODE_ROOT/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang
	export CC_BASENAME=clang
	export CXX=$XCODE_ROOT/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang++
	export CXX_BASENAME=clang++
	export LDFLAGS=""
	cd $LIB_SRC

	export CFLAGS="-O3 -arch $ARCH -fembed-bitcode -isysroot $XCODE_ROOT/Platforms/$PLATFORM.platform/Developer/SDKs/$PLATFORM${IPHONE_SDKVERSION}.sdk -miphoneos-version-min=${MIN_IPHONE_SDKVERSION} -Wno-error-implicit-function-declaration"
	make distclean
	make clean
	./configure --prefix=$PREFIXDIR/${ARCH}
	make -silent
	make install
	echo "================================================================="
	echo "Done"
	echo "================================================================="
}

makeOutput(){
	cp -Rf "$PREFIXDIR/arm64/" "$ROOT/output"
	find "$ROOT/output/lib/" -name '*.a' -delete
	rm "$ROOT/output/lib/libz.1.2.11.dylib"
	${DEVROOT}/usr/bin/lipo \
	-arch x86_64 ${PREFIXDIR}/x86_64/lib/libz.a \
	-arch arm64 ${PREFIXDIR}/arm64/lib/libz.a \
	-arch armv7 ${PREFIXDIR}/armv7/lib/libz.a \
	-output $ROOT/output/lib/libz.a -create

	${DEVROOT}/usr/bin/lipo \
	-arch x86_64 ${PREFIXDIR}/x86_64/lib/libz.1.2.11.dylib \
	-arch arm64 ${PREFIXDIR}/arm64/lib/libz.1.2.11.dylib \
	-arch armv7 ${PREFIXDIR}/armv7/lib/libz.1.2.11.dylib \
	-output $ROOT/output/lib/libz.1.2.11.dylib -create

	#rm -R ${PREFIXDIR}
}

build x86_64 i386-apple-darwin10 iPhoneSimulator
build armv7 arm-apple-darwin iPhoneOS
build arm64 arm-apple-darwin iPhoneOS
makeOutput


