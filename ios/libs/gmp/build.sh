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
	#export CC=$XCODE_ROOT/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang
	#export CC_BASENAME=clang
	#export CXX=$XCODE_ROOT/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang++
	#export CXX_BASENAME=clang++
	
	
	
	export CPPFLAGS="-arch $ARCH -fembed-bitcode -isysroot $XCODE_ROOT/Platforms/$PLATFORM.platform/Developer/SDKs/$PLATFORM${IPHONE_SDKVERSION}.sdk -Wno-error -Wno-implicit-function-declaration -miphoneos-version-min=${MIN_IPHONE_SDKVERSION}"
	
	export CC="$XCODE_ROOT/usr/bin/gcc"
	export CXX="$XCODE_ROOT/usr/bin/g++"
	export CPP="$XCODE_ROOT/usr/bin/gcc -E"
	export AR="$XCODE_ROOT/Toolchains/XcodeDefault.xctoolchain/usr/bin/ar"
	export NM="$XCODE_ROOT/Toolchains/XcodeDefault.xctoolchain/usr/bin/nm"
	export NMEDIT="$XCODE_ROOT/Toolchains/XcodeDefault.xctoolchain/usr/bin/nmedit"
	export LIBTOOL="$XCODE_ROOT/Toolchains/XcodeDefault.xctoolchain/usr/bin/libtool"
	export LIPO="$XCODE_ROOT/Toolchains/XcodeDefault.xctoolchain/usr/bin/lipo"
	export OTOOL="$XCODE_ROOT/Toolchains/XcodeDefault.xctoolchain/usr/bin/otool"
	export RANLIB="$XCODE_ROOT/Toolchains/XcodeDefault.xctoolchain/usr/bin/ranlib"
	export STRIP="$XCODE_ROOT/Toolchains/XcodeDefault.xctoolchain/usr/bin/strip"
	export LD="$XCODE_ROOT/usr/bin/ld"

	
	./configure --disable-assembly --enable-static --disable-shared --host="${HOST}" --prefix=$PREFIXDIR/${ARCH}
	
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
	-arch x86_64 ${PREFIXDIR}/x86_64/lib/libgmp.a \
	-arch arm64 ${PREFIXDIR}/arm64/lib/libgmp.a \
	-arch armv7 ${PREFIXDIR}/armv7/lib/libgmp.a \
	-output $ROOT/output/lib/libgmp.a -create
	#rm -R ${PREFIXDIR}
	#rm "$ROOT/output/bin/curl-config"
}

build x86_64 none-apple-darwin10 iPhoneSimulator
build armv7 arm-apple-darwin iPhoneOS
build arm64 arm-apple-darwin iPhoneOS
makeOutput


