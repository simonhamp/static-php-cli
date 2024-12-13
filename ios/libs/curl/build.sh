: ${IPHONE_SDKVERSION:=`xcodebuild -showsdks | grep iphoneos | egrep "[[:digit:]]+\.[[:digit:]]+" -o | tail -1`}
: ${MIN_IPHONE_SDKVERSION:=9.0}
: ${XCODE_ROOT:=`xcode-select -print-path`}
DEVROOT=${XCODE_ROOT}/Toolchains/XcodeDefault.xctoolchain
: ${PREFIXDIR:=`pwd`/prefix}
LIB_SRC=`pwd`/src
ROOT=`pwd`
build(){
make clean
	ARCH=$1
	HOST=$2
	PLATFORM=$3
	cd $LIB_SRC
	export PATH="${DEVROOT}/usr/bin/:${PATH}"
	export CFLAGS="-DCURL_BUILD_IOS -arch ${ARCH} -pipe -Os -gdwarf-2 -isysroot $XCODE_ROOT/Platforms/$PLATFORM.platform/Developer/SDKs/$PLATFORM${IPHONE_SDKVERSION}.sdk -miphoneos-version-min=${MIN_IPHONE_SDKVERSION} -fembed-bitcode"
	export LDFLAGS="-arch ${ARCH} -isysroot $XCODE_ROOT/Platforms/$PLATFORM.platform/Developer/SDKs/$PLATFORM${IPHONE_SDKVERSION}.sdk"

	./configure --disable-shared --with-ssl=$ROOT/../ssl/prefix/$ARCH --with-libssh2=$ROOT/../ssh2/prefix/$ARCH --with-zlib=$ROOT/../zlib/prefix/$ARCH --enable-static --enable-ipv6 --with-ssl=$ROOT/../ssl/prefix/$ARCH --host="${HOST}" --prefix=$PREFIXDIR/${ARCH}
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
	-arch x86_64 ${PREFIXDIR}/x86_64/lib/libcurl.a \
	-arch arm64 ${PREFIXDIR}/arm64/lib/libcurl.a \
	-arch armv7 ${PREFIXDIR}/armv7/lib/libcurl.a \
	-output $ROOT/output/lib/libcurl.a -create
	#rm -R ${PREFIXDIR}
	#rm "$ROOT/output/bin/curl-config"
}

build x86_64 i386-apple-darwin10 iPhoneSimulator
build armv7 arm-apple-darwin iPhoneOS
build arm64 arm-apple-darwin iPhoneOS
makeOutput


