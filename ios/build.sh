#!/bin/bash

XCODE_ROOT=`xcode-select -print-path`
export DEVROOT=${XCODE_ROOT}/Toolchains/XcodeDefault.xctoolchain
CUR_DIR=`pwd`
DIST_DIR=`pwd`/output
LIB=`pwd`/libs
cd php

function build() {
    make clean
    make distclean
    PLATFORM=$3
    HOST=$2
    ARCH=$1
	XCODE_ROOT=`xcode-select -print-path`
	PLATFORM_PATH=$XCODE_ROOT/Platforms/$PLATFORM.platform/Developer
	SDK_PATH=$PLATFORM_PATH/SDKs/$PLATFORM.sdk
	
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
	
	
	FLAGS="-isysroot $SDK_PATH -arch $ARCH -miphoneos-version-min=9.0 -I${LIB}/ssh2/prefix/$ARCH/include"
    PLATFORM_BIN_PATH=$XCODE_ROOT/Toolchains/XcodeDefault.xctoolchain/usr/bin
    CFLAGS="$FLAGS -std=gnu99 -fembed-bitcode -DSQLITE_ENABLE_LOCKING_STYLE=0 -Wno-error=unused-command-line-argument"
    CXXFLAGS="$FLAGS -std=gnu++11 -stdlib=libc++"
    LDFLAGS="$FLAGS"
	export OPENSSL_CFLAGS="-I${LIB}/ssl/prefix/$ARCH/include"
	export OPENSSL_LIBS="-L${LIB}/ssl/prefix/$ARCH/lib -lssl -lcrypto"
	export ICU_CFLAGS="-I${LIB}/icu/prefix/$ARCH/include -fembed-bitcode"
	export ICU_LIBS="-L${LIB}/icu/prefix/$ARCH/lib -licui18n -liculx -licule -licuio -licuuc -licudata"
	export ONIG_CFLAGS="-I${LIB}/onig/prefix/$ARCH/include"
	export ONIG_LIBS="-L${LIB}/onig/prefix/$ARCH/lib -lonig"
	export JPEG_CFLAGS="-I${LIB}/jpeg/prefix/$ARCH/include"
	export JPEG_LIBS="-L${LIB}/jpeg/prefix/$ARCH/lib"
	export PNG_CFLAGS="-I${LIB}/png/prefix/$ARCH/include"
	export PNG_LIBS="-L${LIB}/png/prefix/$ARCH/lib"
	export FREETYPE2_CFLAGS="-I${LIB}/freetype/prefix/$ARCH/include/freetype2"
	export FREETYPE2_LIBS="-L${LIB}/freetype/prefix/$ARCH/lib -lfreetype"
	export LIBXML_CFLAGS="-I${LIB}/xml/prefix/$ARCH/include"
	export LIBXML_LIBS="-L${LIB}/xml/prefix/$ARCH/lib -lxml2"
	export LIBZIP_CFLAGS="-I${LIB}/libzip/prefix/$ARCH/include"
	export LIBZIP_LIBS="-L${LIB}/libzip/prefix/$ARCH/lib -lzip"
	export CURL_CFLAGS="-I${LIB}/curl/prefix/$ARCH/include -DCURL_STATICLIB"
	export CURL_LIBS="-L${LIB}/curl/prefix/$ARCH/lib -L${LIB}/ssh2/prefix/$ARCH/lib -L${LIB}/zlib/prefix/$ARCH/lib -lssh2 -lcurl -lz"
	export XSL_CFLAGS="-I${LIB}/xslt/prefix/$ARCH/include"
	export XSL_LIBS="-L${LIB}/xslt/prefix/$ARCH/lib"
	export SQLITE_CFLAGS="-I${LIB}/sqlite3/prefix/$ARCH/include"
	export SQLITE_LIBS="-L${LIB}/sqlite3/prefix/$ARCH/lib"

	export ZLIB_CFLAGS="-I${LIB}/zlib/prefix/$ARCH/include"
	export ZLIB_LIBS="-L${LIB}/zlib/prefix/$ARCH/lib"
	
	export PCRE2_CFLAGS="-I${LIB}/pcre/prefix/$ARCH/include -DPCRE2_STATIC"
	export PCRE2_LIBS="-L${LIB}/pcre/prefix/$ARCH/lib"
	
    export CFLAGS CXXFLAGS LDFLAGS EXTRA_LDFLAGS INCLUDES
	CONFIGURE_FLAGS="
			--host=$HOST
			--with-iconv=${LIB}/iconv/prefix/$ARCH
			--with-mcrypt=${LIB}/mcrypt/prefix/$ARCH
			--with-gmp=${LIB}/gmp/prefix/$ARCH
			--with-ssh2=${LIB}/ssh2/prefix/$ARCH
			--with-external-pcre=${LIB}/pcre/prefix/$ARCH
			--enable-tideways-xhprof
			--with-xsl
			--with-curl
			--with-openssl
			--with-zlib
			--with-libxml
			--enable-mysqlnd
			--with-pdo-mysql
			--enable-exif
			--enable-sockets
			--enable-soap
			--enable-mbstring
			--enable-calendar
			--enable-intl
			--enable-fpm
			--enable-bcmath
			--with-zip
			--enable-gd
			--enable-ftp
			--with-jpeg
			--with-freetype
			--enable-gd-jis-conv
			--enable-embed=static
			--without-pear
			--disable-opcache
			--without-pcre-jit
			--disable-opcache-jit
			--disable-shared
			--disable-cli
			--with-mysqli"
	./configure $CONFIGURE_FLAGS EXTRA_LIBS="-lresolv -lpng -ljpeg -lsqlite3 -lxslt -lpcre2-8"
    sed 's/\-L\/Applications\/Xcode.app\/Contents\/Developer\/Platforms\/MacOSX.platform\/Developer\/SDKs\/MacOSX.sdk\/usr\/lib / /' "${CUR_DIR}/php/makefile" > "${CUR_DIR}/php/makefile_.tmp"
	mv "${CUR_DIR}/php/makefile_.tmp" "${CUR_DIR}/php/makefile"
	sed 's/\-I\/Applications\/Xcode.app\/Contents\/Developer\/Platforms\/MacOSX.platform\/Developer\/SDKs\/MacOSX.sdk\/usr\/include / /' "${CUR_DIR}/php/makefile" > "${CUR_DIR}/php/makefile_.tmp"
	mv "${CUR_DIR}/php/makefile_.tmp" "${CUR_DIR}/php/makefile"
	sed 's/\-I\/Applications\/Xcode.app\/Contents\/Developer\/Platforms\/MacOSX.platform\/Developer\/SDKs\/MacOSX.sdk\/usr\/include\/libxml2 / /' "${CUR_DIR}/php/makefile" > "${CUR_DIR}/php/makefile_.tmp"
	mv "${CUR_DIR}/php/makefile_.tmp" "${CUR_DIR}/php/makefile"
	sed 's/CXXFLAGS_CLEAN = /CXXFLAGS_CLEAN = -fembed-bitcode /' "${CUR_DIR}/php/makefile" > "${CUR_DIR}/php/makefile_.tmp"
	mv "${CUR_DIR}/php/makefile_.tmp" "${CUR_DIR}/php/makefile"
	sed 's/CXXFLAGS = /CXXFLAGS = -fembed-bitcode /' "${CUR_DIR}/php/makefile" > "${CUR_DIR}/php/makefile_.tmp"
	mv "${CUR_DIR}/php/makefile_.tmp" "${CUR_DIR}/php/makefile"
    make --silent
    rm -rf ${DIST_DIR}/$1
    mkdir -p ${DIST_DIR}/$1
    cp -r `pwd`/.libs/libphp.a ${DIST_DIR}/$1/php8.a
}
function makeFat(){
${DEVROOT}/usr/bin/lipo \
-arch x86_64 ${DIST_DIR}/x86_64/php8.a \
-arch arm64 ${DIST_DIR}/arm64/php8.a \
-arch armv7 ${DIST_DIR}/armv7/php8.a \
-output $DIST_DIR/php8.a -create

}

# steps
# 1- build
# 2- goto makefile and remove all MacOS from EXTRA_LDFLAGS, EXTRA_LDFLAGS_PROGRAM & INCLUDES
#	 also add -fembed-bitcode in CFLAGS, CXXFLAGS and CXXFLAGS_CLEAN
# 3- goto php and make -silent
# 4- copy lib
# 5- do the same thing for the 3 archs
# 6- make fat file (lipo)

build x86_64 i386-apple-darwin iPhoneSimulator
build arm64 arm-apple-darwin iPhoneOS
build armv7 arm-apple-darwin iPhoneOS
makeFat
