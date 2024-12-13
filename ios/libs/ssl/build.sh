#!/bin/bash


# Setup paths to stuff we need
DEST_DIR=`pwd`/prefix
OUTPUT=`pwd`/output
cd src




DEVELOPER=$(xcode-select --print-path)

IPHONEOS_SDK_VERSION=$(xcrun --sdk iphoneos --show-sdk-version)
IPHONEOS_DEPLOYMENT_VERSION="9.0"
IPHONEOS_PLATFORM=$(xcrun --sdk iphoneos --show-sdk-platform-path)
IPHONEOS_SDK=$(xcrun --sdk iphoneos --show-sdk-path)

IPHONESIMULATOR_PLATFORM=$(xcrun --sdk iphonesimulator --show-sdk-platform-path)
IPHONESIMULATOR_SDK=$(xcrun --sdk iphonesimulator --show-sdk-path)



configure() {
    OS=$1
    ARCH=$2
    PLATFORM=$3
    SDK_VERSION=$4
    DEPLOYMENT_VERSION=$5
    export CROSS_TOP="${PLATFORM}/Developer"
    export CROSS_SDK="${OS}${SDK_VERSION}.sdk"
    if [ "$ARCH" == "x86_64" ]; then
       ./Configure darwin64-x86_64-cc --openssldir="${DEST_DIR}/${ARCH}"
       sed -ie "s!^CFLAG=!CFLAG=-isysroot ${CROSS_TOP}/SDKs/${CROSS_SDK} -arch $ARCH -mios-simulator-version-min=${DEPLOYMENT_VERSION} -miphoneos-version-min=${DEPLOYMENT_VERSION} !" "Makefile"
   else
       ./Configure iphoneos-cross -no-asm --openssldir="${DEST_DIR}/${ARCH}"
       sed -ie "s!^CFLAG=!CFLAG=-mios-simulator-version-min=${DEPLOYMENT_VERSION} -miphoneos-version-min=${DEPLOYMENT_VERSION} !" "Makefile"
       perl -i -pe 's|static volatile sig_atomic_t intr_signal|static volatile int intr_signal|' crypto/ui/ui_openssl.c
   fi
}

build(){
make distclean
make clean
   ARCH=$1
   export BUILD_TOOLS="${DEVELOPER}"
   export CC="${BUILD_TOOLS}/usr/bin/gcc -fembed-bitcode -arch ${ARCH}"

    if [ "$ARCH" == "x86_64" ] || [ "$ARCH" == "i386" ]; then
        configure "iPhoneSimulator" $ARCH ${IPHONESIMULATOR_PLATFORM} ${IPHONEOS_SDK_VERSION} ${IPHONEOS_DEPLOYMENT_VERSION}
    else
        configure "iPhoneOS" $ARCH ${IPHONEOS_PLATFORM} ${IPHONEOS_SDK_VERSION} ${IPHONEOS_DEPLOYMENT_VERSION}
        fi

   make && make install
}

makeOutput(){
cp -Rf "$DEST_DIR/arm64/" "$OUTPUT"
find "$OUTPUT/lib/" -name '*.a' -delete
xcrun lipo \
-arch x86_64 ${DEST_DIR}/x86_64/lib/libcrypto.a \
-arch arm64 ${DEST_DIR}/arm64/lib/libcrypto.a \
-arch armv7 ${DEST_DIR}/armv7/lib/libcrypto.a \
-output ${OUTPUT}/lib/libcrypto.a -create
xcrun lipo \
-arch x86_64 ${DEST_DIR}/x86_64/lib/libssl.a \
-arch arm64 ${DEST_DIR}/arm64/lib/libssl.a \
-arch armv7 ${DEST_DIR}/armv7/lib/libssl.a \
-output ${OUTPUT}/lib/libssl.a -create

#rm -R ${DEST_DIR}
}

build "x86_64"
build "armv7"
build "arm64"
makeOutput

