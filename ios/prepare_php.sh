#!/bin/bash


CUR_DIR=`pwd`
echo -e "\033[38;5;82mAdding Extensions\033[0m"
cp -r "${CUR_DIR}/raw/mcrypt" "${CUR_DIR}/php/ext/mcrypt"
cp -r "${CUR_DIR}/raw/ssh2" "${CUR_DIR}/php/ext/ssh2"
#cp -r "${CUR_DIR}/raw/tideways-xhprof" "${CUR_DIR}/php/ext/tideways-xhprof"

#======================================================
echo -e "\033[38;5;82mSetting Permission\033[0m"
chmod -R a+x "${CUR_DIR}/php/"

#======================================================

echo -e "\033[38;5;82mPhpize\033[0m"
#cd "${CUR_DIR}/php/ext/tideways-xhprof"
#phpize
cd "${CUR_DIR}/php/ext/mcrypt"
phpize 
cd "${CUR_DIR}"

#======================================================

echo -e "\033[38;5;82mRebuild conf\033[0m"
rm "${CUR_DIR}/php/configure"
cd "${CUR_DIR}/php"
./buildconf --force
sed 's/CONFIGURE_COMMAND="$CONFIGURE_COMMAND $CONFIGURE_OPTIONS"/CONFIGURE_COMMAND="'\''.\/configure'\''"/' "${CUR_DIR}/php/configure" > "${CUR_DIR}/php/configure.tmp"
mv "${CUR_DIR}/php/configure.tmp" "${CUR_DIR}/php/configure"

#======================================================
chmod -R a+x "${CUR_DIR}/php/"
#echo -e "\033[38;5;82mZIP patch\033[0m"
#grep '#include <unistd.h>//added by Firas ' "${CUR_DIR}/php/ext/zip/lib/mkstemp.c" || echo "#include <unistd.h>//added by Firas $(cat ${CUR_DIR}/php/ext/zip/lib/mkstemp.c)" > "${CUR_DIR}/php/ext/zip/lib/mkstemp.c"
echo -e "\033[38;5;82mDone, now edit configure to disable cross compiling\033[0m"
