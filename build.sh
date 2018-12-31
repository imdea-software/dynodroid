#!/usr/bin/env bash

if [ $# -eq 0 ] || [ $# -gt 3 ]; then
  echo "Usage: ${0} <ANDROID_HOME> <SHOWEMU> [TOOLDIRNAME]"
  exit 1
fi

ANDROID_HOME=$1
if [[ ! -e ${ANDROID_HOME} ]]; then
    echo "This ANDROID_HOME: ${ANDROID_HOME} - Doesn't exist."
    echo "Run again with a correct folder."
    exit 1
fi

SHOWEMU=$2

TOOLDIRNAME=${3:-deploy}

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


TOOLDIR=${DIR}/${TOOLDIRNAME}/
setupRelPath="/dynodroidsetup"
# setupRelPath same as dynodroid/dynodroidsetup.py
sdcardimg_setup_filepath="${DIR}${setupRelPath}/freshavd/emu.avd/sdcard.img"
sdcardimg_backup_filepath="${DIR}/freshavd/emu.avd/sdcard.img"

echo "-- PREPARING ${TOOL}"
if [[ -f "${sdcardimg_backup_filepath}" ]]; then
  echo -n "    * Coping sdcard.img backup: "
  sdcardimg_filename="sdcard.img"
  sdcardimg_filepath="${DIR}/${sdcardimg_filename}"
  CMD="cp ${DIR}/freshavd/emu.avd/sdcard.img ${sdcardimg_filepath}"
  echo -n "${CMD}: "
  [[ $? -ne 0 ]] && echo "ERROR" && exit 1 || echo "OK"
else
  echo "    * Downloading sdcard.img"
  # Thanks to https://stackoverflow.com/a/38937732/8091456
  ggID='1mf4kKCNgz059C5hzRKOT5Wk_e9WccmFk'
  ggURL='https://drive.google.com/uc?export=download'
  sdcardimg_filename="$(curl -sc /tmp/gcokie "${ggURL}&id=${ggID}" | grep -o '="uc-name.*</span>' | sed 's/.*">//;s/<.a> .*//')"
  sdcardimg_filepath="${DIR}/${sdcardimg_filename}"
  getcode="$(awk '/_warning_/ {print $NF}' /tmp/gcokie)"
  URL="${ggURL}&confirm=${getcode}&id=${ggID}"
  curl -Lb /tmp/gcokie ${URL} -o ${sdcardimg_filepath}
  echo -n "    * Downloading sdcard.img: "
  [[ $? -ne 0 ]] && echo "ERROR" && exit 1 || echo "OK"
fi

echo -n "    * "
CMD="mv ${sdcardimg_filepath} ${sdcardimg_setup_filepath}"
echo -n "${CMD}: "
eval ${CMD}
[[ $? -ne 0 ]] && echo "ERROR" && exit 1 || echo "OK"


echo "-- BUILDING ${TOOL}"
echo -n "    * "
CMD="export SDK_INSTALL=${ANDROID_HOME}"
echo -n "${CMD}: "
eval ${CMD}
[[ $? -ne 0 ]] && echo "ERROR" && exit 1 || echo "OK"

cd ${DIR}
echo -n "    * cleaning ${TOOLDIR}"
rm -rf ${TOOLDIR}
mkdir -p ${TOOLDIR}

echo -n "    * building... "
CMD="python dynodroidsetup.py ${DIR} ${TOOLDIR} ${SHOWEMU}"
echo -n "${CMD}: "
eval ${CMD}
[[ $? -ne 0 ]] && echo "ERROR" && exit 1 || echo "OK"

cd ${TOOLDIR}

echo -n "    * "
CMD="ant -diagnostics"
echo -n "${CMD}: "
eval ${CMD}
[[ $? -ne 0 ]] && echo "ERROR" && exit 1 || echo "OK"

echo -n "    * "
CMD="ant -verbose -debug clean"
echo -n "${CMD}: "
eval ${CMD}
[[ $? -ne 0 ]] && echo "ERROR" && exit 1 || echo "OK"


echo -n "    * "
CMD="ant -verbose -debug compile"
echo -n "${CMD}: "
eval ${CMD}
[[ $? -ne 0 ]] && echo "ERROR" && exit 1 || echo "OK"
