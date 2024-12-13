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
	

	
	export CFLAGS="-arch ${ARCH} -pipe -fembed-bitcode -Wno-trigraphs -fpascal-strings -O2 -Wreturn-type -Wunused-variable -fmessage-length=0 -fvisibility=hidden -miphoneos-version-min=${MIN_IPHONE_SDKVERSION} -isysroot $XCODE_ROOT/Platforms/$PLATFORM.platform/Developer/SDKs/$PLATFORM${IPHONE_SDKVERSION}.sdk"
	export LDFLAGS="-arch ${ARCH} -isysroot $XCODE_ROOT/Platforms/$PLATFORM.platform/Developer/SDKs/$PLATFORM${IPHONE_SDKVERSION}.sdk -miphoneos-version-min=${MIN_IPHONE_SDKVERSION}"

	
	export CC="$XCODE_ROOT/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang"
	export AR="$XCODE_ROOT/Toolchains/XcodeDefault.xctoolchain/usr/bin/ar"
	


	
	./configure --disable-assembly --enable-static --without-zlib --without-bzip2 --disable-shared --host="${HOST}" --prefix=$PREFIXDIR/${ARCH}
	
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
	-arch x86_64 ${PREFIXDIR}/x86_64/lib/libfreetype.a \
	-arch arm64 ${PREFIXDIR}/arm64/lib/libfreetype.a \
	-arch armv7 ${PREFIXDIR}/armv7/lib/libfreetype.a \
	-output $ROOT/output/lib/libfreetype.a -create
	#rm -R ${PREFIXDIR}
	#rm "$ROOT/output/bin/curl-config"
}

build x86_64 none-apple-darwin10 iPhoneSimulator
build armv7 arm-apple-darwin iPhoneOS
build arm64 arm-apple-darwin iPhoneOS
makeOutput


