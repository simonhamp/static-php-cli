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
	export CFLAGS="-arch $ARCH -fembed-bitcode -isysroot $XCODE_ROOT/Platforms/$PLATFORM.platform/Developer/SDKs/$PLATFORM${IPHONE_SDKVERSION}.sdk -miphoneos-version-min=${MIN_IPHONE_SDKVERSION} -Wno-error-implicit-function-declaration"
	cd $LIB_SRC
	make distclean
	make clean
	./configure --host=$HOST --prefix=$PREFIXDIR/${ARCH}
	make -silent
	make install
	echo "================================================================="
	echo "Done"
	echo "================================================================="
}

makeOutput(){
	cp -Rf "$PREFIXDIR/arm64/" "$ROOT/output"
	find "$ROOT/output/lib/" -name '*.a' -delete
	find "$ROOT/output/lib/" -name '*.dylib' -delete
	${DEVROOT}/usr/bin/lipo \
	-arch x86_64 ${PREFIXDIR}/x86_64/lib/libxml2.2.dylib \
	-arch arm64 ${PREFIXDIR}/arm64/lib/libxml2.2.dylib \
	-arch armv7 ${PREFIXDIR}/armv7/lib/libxml2.2.dylib \
	-output $ROOT/output/lib/libxml2.2.dylib -create
	#rm -R ${PREFIXDIR}
	#rm "$ROOT/output/bin/xml2-config"
}

build x86_64 i386-apple-darwin10 iPhoneSimulator
build armv7 arm-apple-darwin iPhoneOS
build arm64 arm-apple-darwin iPhoneOS
makeOutput

