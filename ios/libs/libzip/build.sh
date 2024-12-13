#!/bin/bash

#  Automatic build script for libzip
#  for iPhoneOS and iPhoneSimulator

###########################################################################
#  Change values here													  #
#                                                                         #
VERSION="1.7.3"												              #
MIN_IOS_VERSION="8.0"                                                     #
#																		  #
###########################################################################
#																		  #
# Don't change anything under this line!								  #
#																		  #
###########################################################################

#configure options
ZIP_CONFIGURE_OPTIONS="-DBUILD_SHARED_LIBS=OFF \
                        -DBUILD_TOOLS=OFF \
                        -DBUILD_DOC=OFF \
                        -DBUILD_REGRESS=OFF \
                        -DENABLE_BITCODE=ON \
                        -DENABLE_LZMA=OFF \
                        -DENABLE_ZSTD=OFF \
                        -DENABLE_BZIP2=OFF \
                        -DBUILD_EXAMPLES=OFF"


CURRENTPATH=`pwd`
ARCHS="x86_64 armv7 arm64"
DEVELOPER=`xcode-select -print-path`

if [ ! -d "$DEVELOPER" ]; then
    echo "xcode path is not set correctly $DEVELOPER does not exist (most likely because of xcode > 4.3)"
    echo "run"
    echo "sudo xcode-select -switch <xcode path>"
    echo "for default installation:"
    echo "sudo xcode-select -switch /Applications/Xcode.app/Contents/Developer"
    exit 1
fi

case $DEVELOPER in
    *\ * )
    echo "Your Xcode path contains whitespaces, which is not supported."
    exit 1
    ;;
esac

case $CURRENTPATH in
    *\ * )
    echo "Your path contains whitespaces, which is not supported by 'make install'."
    exit 1
    ;;
esac

set -e
if [ ! -e libzip-${VERSION}.tar.gz ]; then
    echo "Downloading libzip-${VERSION}.tar.gz"
    curl -O -L -s https://libzip.org/download/libzip-${VERSION}.tar.gz
else
    echo "Using libzip-${VERSION}.tar.gz"
fi

mkdir -p "${CURRENTPATH}/src"
mkdir -p "${CURRENTPATH}/prefix"
mkdir -p "${CURRENTPATH}/output/lib"

tar zxf libzip-${VERSION}.tar.gz -C "${CURRENTPATH}/src"
cd "${CURRENTPATH}/src/libzip-${VERSION}"


for ARCH in ${ARCHS}
do
    if [[ "${ARCH}" == "i386" || "${ARCH}" == "x86_64" ]];
    then
        PLATFORM="iPhoneSimulator"
    else
        PLATFORM="iPhoneOS"
    fi

    case "${ARCH}" in
    "i386")
        BUILD_PLATFORM="SIMULATOR"
        ;;
    "x86_64")
        BUILD_PLATFORM="SIMULATOR64"
        ;;
    "armv7")
        BUILD_PLATFORM="OS"
        ;;
    "armv7s")
        BUILD_PLATFORM="OS"
        ;;
    "arm64")
        BUILD_PLATFORM="OS64"
        ;;
    "arm64e")
        BUILD_PLATFORM="OS64"
        ;;
    esac

    echo "Building zip-${VERSION} for ${PLATFORM}  ${ARCH}"
    echo "Please stand by..."

    mkdir -p "${CURRENTPATH}/prefix/${ARCH}"
    LOG="${CURRENTPATH}/prefix/${ARCH}/libzip-${VERSION}.log"

    set +e
    INSTALL_DIR="${CURRENTPATH}/prefix/${ARCH}"
    mkdir "build-${ARCH}"
    cd "build-${ARCH}"
    cmake .. -DCMAKE_TOOLCHAIN_FILE=${CURRENTPATH}/toolchain/ios.toolchain.cmake -DCMAKE_INSTALL_PREFIX:PATH="${INSTALL_DIR}" -DPLATFORM=${BUILD_PLATFORM} -DARCHS=${ARCH} ${ZIP_CONFIGURE_OPTIONS} -DCMAKE_PREFIX_PATH="${CURRENTPATH}/../ssl/prefix/${ARCH}" > "${LOG}" 2>&1

    if [ $? != 0 ];
    then
        echo "Problem while configure - Please check ${LOG}"
        exit 1
    fi

    cmake --build . --config Release --target install  >> "${LOG}" 2>&1

    if [ $? != 0 ];
    then
        echo "Problem while building - Please check ${LOG}"
        exit 1
    fi

    cd ..
    set -e
done


echo "Build library..."
lipo -create ${CURRENTPATH}/prefix/x86_64/lib/libzip.a  ${CURRENTPATH}/prefix/armv7/lib/libzip.a ${CURRENTPATH}/prefix/arm64/lib/libzip.a -output ${CURRENTPATH}/output/lib/libzip.a

mkdir -p ${CURRENTPATH}/output/include
cp -R ${CURRENTPATH}/prefix/x86_64/include ${CURRENTPATH}/output/include/
echo "Building done."
echo "Cleaning up..."
rm -rf ${CURRENTPATH}/src/zip-${VERSION}
echo "Done."

lipo -info ${CURRENTPATH}/output/lib/libzip.a
