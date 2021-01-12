#!/usr/bin/env bash
set -e

_BUILD_DIR=xAuto
_BUILD_TYPE=Release
_CEF_VERSION=75.1.14+gc81164e+chromium-75.0.3770.100

git fetch --tags
readonly _GIT_TAG=$(git describe --abbrev=0 --always)
export GIT_TAG=${_GIT_TAG}
readonly _FILE_DATE=$(date +%Y-%m-%d.%H-%M-%S)
export FILE_DATE=${_FILE_DATE}
readonly _YYYYMMDD=$(date +%Y%m%d)
export YYYYMMDD=${_YYYYMMDD}

readonly _SIDEKICK_ROOT="$(pwd)"
export SIDEKICK_ROOT=${_SIDEKICK_ROOT}
cd ../../.. || exit
readonly _OBS_ROOT="$(pwd)"
export OBS_ROOT=${_OBS_ROOT}
cd .. || exit
readonly _DEV_DIR="$(pwd)"
export DEV_DIR="${DEV_DIR:-${_DEV_DIR}}"

export DYLIBBUNDLER="${SIDEKICK_ROOT}/scripts/macdylibbundler/build/dylibbundler"
export BUILD_DIR="${BUILD_DIR:-${_BUILD_DIR}}"
export BUILD_ROOT="${OBS_ROOT}/${BUILD_DIR}"

if [ -f "${BUILD_ROOT}/CMakeCache.txt" ]; then
  PREV_BUILD_TYPE=$(grep -E 'CMAKE_BUILD_TYPE:[^=]+=' "${BUILD_ROOT}/CMakeCache.txt" | sed -E 's/CMAKE_BUILD_TYPE:[^=]+=//')
fi
readonly __BUILD_TYPE=${PREV_BUILD_TYPE:-${_BUILD_TYPE}}
readonly _BUILD_TYPE_=${1:-${__BUILD_TYPE}}
export CMAKE_BUILD_TYPE=${BUILD_TYPE:-${_BUILD_TYPE_}}
export BUILD_TYPE=${CMAKE_BUILD_TYPE}
_CEF_BUILD_TYPE=Release
if [ "${BUILD_TYPE}" = "Debug" ]; then _CEF_BUILD_TYPE=Debug; fi
export CEF_BUILD_TYPE=${CEF_BUILD_TYPE:-${_CEF_BUILD_TYPE}}

export CEF_VERSION=${CEF_VERSION:-${_CEF_VERSION}}
export CEF_BUILD_VERSION=${CEF_BUILD_VERSION:-${CEF_VERSION}}

readonly _CEF_DIR="${CEF:-${DEV_DIR}/cef_binary_${CEF_BUILD_VERSION}_macosx64}"
export CEF_ROOT_DIR="${CEF_ROOT_DIR:-${_CEF_DIR}}"
export CEF_ROOT="${CEF_ROOT:-${CEF_ROOT_DIR}}"

export BOOST_ROOT="${BOOST_ROOT:-/usr/local/opt/boost}"
readonly _OPENSSL_DIR="${OPENSSL:-/usr/local/opt/openssl@1.1}"
export OPENSSL_ROOT_DIR="${OPENSSL_ROOT_DIR:-${_OPENSSL_DIR}}"

# Store current xcode path
XCODE_SELECT="$(xcode-select -p)"

red=$'\e[1;31m'
# grn=$'\e[1;32m'
# blu=$'\e[1;34m'
# mag=$'\e[1;35m'
cyn=$'\e[1;36m'
# bold=$'\e[1m'
reset=$'\e[0m'

hr() {
  echo "───────────────────────────────────────────────────"
  echo "$1"
  [ -n "$2" ] && echo "$2"
  [ -n "$3" ] && echo "$3"
  [ -n "$4" ] && echo "$4"
  [ -n "$5" ] && echo "$5"
  echo "───────────────────────────────────────────────────"
}

main() {
  start_ts=$(date +%s)
  start="$(date '+%Y-%m-%d %H:%M:%S')"
  echo
  echo "${cyn}Packaging              Sidekick v1${reset}"
  echo "${red}BUILD_TYPE:            ${BUILD_TYPE}${reset}"
  if [ -f "${BUILD_ROOT}/CMakeCache.txt" ]; then
    echo "${red}PREVIOUS BUILD_TYPE:   ${PREV_BUILD_TYPE}${reset}"
  fi
  echo "BUILD_ROOT:            ${BUILD_ROOT}"
  echo "OBS_ROOT:              ${OBS_ROOT}"
  echo "DEV_DIR:               ${DEV_DIR}"

  # Switch to current Xcode for dylibbundler compilation
  sudo xcode-select --reset

  # Build dylibbundler
  hr "Compiling macdylibbundler"
  (cd "${SIDEKICK_ROOT}/scripts/macdylibbundler" && mkdir -p build && cd build && cmake .. && make)

  # Copy obslua
  if [ -f "${BUILD_ROOT}/rundir/${BUILD_TYPE}/data/obs-scripting/obslua.so" ]; then
    cp -pfR "${BUILD_ROOT}/rundir/${BUILD_TYPE}/data/obs-scripting/obslua.so" \
      "${BUILD_ROOT}/rundir/${BUILD_TYPE}/bin/"
  fi

  # Copy obspython
  if [ -f "${BUILD_ROOT}/rundir/${BUILD_TYPE}/data/obs-scripting/_obspython.so" ]; then
    cp -pfR "${BUILD_ROOT}/rundir/${BUILD_TYPE}/data/obs-scripting/_obspython.so" \
      "${BUILD_ROOT}/rundir/${BUILD_TYPE}/bin/"
    cp -pfR "${BUILD_ROOT}/rundir/${BUILD_TYPE}/data/obs-scripting/obspython.py" \
      "${BUILD_ROOT}/rundir/${BUILD_TYPE}/bin/"
  fi

  hr "Building Sidekick Login app bundle"
  (${DYLIBBUNDLER} -f -cd -of -q -a "${BUILD_ROOT}/plugins/MyFreeCams/Sidekick/MFCCefLogin/MFCCefLogin.app")

  hr "Building OBS-v1 app bundle"
  (cd "${BUILD_ROOT}" && "${SIDEKICK_ROOT}/scripts/install/osx/packageApp-v1.sh")

  cd "${BUILD_ROOT}"

  # Copy Chromium embedded framework to app Frameworks directory (for obs-browser)
  if [ -f "${BUILD_ROOT}/rundir/${BUILD_TYPE}/obs-plugins/obs-browser.so" ]; then
    hr "Copying Chromium Embedded Framework.framework"
    mkdir -p "${BUILD_ROOT}/OBS-v1.app/Contents/Frameworks"
    cp -pfR "${CEF_ROOT}/${CEF_BUILD_TYPE}/Chromium Embedded Framework.framework" \
      "${BUILD_ROOT}/OBS-v1.app/Contents/Frameworks/"
    install_name_tool -change \
      @rpath/Frameworks/Chromium\ Embedded\ Framework.framework/Chromium\ Embedded\ Framework \
      @executable_path/../../Frameworks/Chromium\ Embedded\ Framework.framework/Chromium\ Embedded\ Framework \
      "${BUILD_ROOT}/OBS-v1.app/Contents/Resources/obs-plugins/obs-browser.so"
    install_name_tool -change \
      @executable_path/../Frameworks/Chromium\ Embedded\ Framework.framework/Chromium\ Embedded\ Framework \
      @executable_path/../../Frameworks/Chromium\ Embedded\ Framework.framework/Chromium\ Embedded\ Framework \
      "${BUILD_ROOT}/OBS-v1.app/Contents/Resources/obs-plugins/obs-browser.so"
    install_name_tool -change \
      @rpath/Frameworks/Chromium\ Embedded\ Framework.framework/Chromium\ Embedded\ Framework \
      @executable_path/../../Frameworks/Chromium\ Embedded\ Framework.framework/Chromium\ Embedded\ Framework \
      "${BUILD_ROOT}/OBS-v1.app/Contents/Resources/obs-plugins/obs-browser-page"
    install_name_tool -change \
      @executable_path/../Frameworks/Chromium\ Embedded\ Framework.framework/Chromium\ Embedded\ Framework \
      @executable_path/../../Frameworks/Chromium\ Embedded\ Framework.framework/Chromium\ Embedded\ Framework \
      "${BUILD_ROOT}/OBS-v1.app/Contents/Resources/obs-plugins/obs-browser-page"
  fi

  cp "${SIDEKICK_ROOT}/scripts/install/osx/OBSPublicDSAKey.pem" "${BUILD_ROOT}/OBS-v1.app/Contents/Resources/"

  # Edit plist
  plutil -insert CFBundleVersion -string $GIT_TAG "${BUILD_ROOT}/OBS-v1.app/Contents/Info.plist"
  plutil -insert CFBundleShortVersionString -string $GIT_TAG "${BUILD_ROOT}/OBS-v1.app/Contents/Info.plist"
  plutil -insert SUPublicDSAKeyFile -string OBSPublicDSAKey.pem "${BUILD_ROOT}/OBS-v1.app/Contents/Info.plist"

  rm -rf "${BUILD_ROOT}/OBS-Sidekick-v1.app"

  # Create copy to use for Sidekick v1 Installer packaging
  cp -pfR "${BUILD_ROOT}/OBS-v1.app" "${BUILD_ROOT}/OBS-Sidekick-v1.app"

  if [ -f "${BUILD_ROOT}/OBS-Sidekick-v1.app/Contents/Plugins/MFCBroadcast.so" ]; then
    hr "MFCBroadcast.so: fixing dependencies"
    install_name_tool -change \
      @executable_path/../bin/websocketclient.dylib \
      @loader_path/websocketclient.dylib \
      "${BUILD_ROOT}/OBS-Sidekick-v1.app/Contents/Plugins/MFCBroadcast.so"
    install_name_tool -change \
      @executable_path/../bin//libcrypto.1.1.dylib \
      @loader_path/libcrypto.1.1.dylib \
      "${BUILD_ROOT}/OBS-Sidekick-v1.app/Contents/Plugins/MFCBroadcast.so"
    install_name_tool -change \
      @executable_path/../bin//libssl.1.1.dylib \
      @loader_path/libssl.1.1.dylib \
      "${BUILD_ROOT}/OBS-Sidekick-v1.app/Contents/Plugins/MFCBroadcast.so"
    install_name_tool -change \
      @executable_path/../bin//libboost_program_options-mt.dylib \
      @loader_path/libboost_program_options-mt.dylib \
      "${BUILD_ROOT}/OBS-Sidekick-v1.app/Contents/Plugins/MFCBroadcast.so"
    install_name_tool -change \
      @executable_path/../bin//libboost_date_time-mt.dylib \
      @loader_path/libboost_date_time-mt.dylib \
      "${BUILD_ROOT}/OBS-Sidekick-v1.app/Contents/Plugins/MFCBroadcast.so"
    install_name_tool -change \
      @executable_path/../bin//libboost_thread-mt.dylib \
      @loader_path/libboost_thread-mt.dylib \
      "${BUILD_ROOT}/OBS-Sidekick-v1.app/Contents/Plugins/MFCBroadcast.so"
    install_name_tool -change \
      @executable_path/../bin//libboost_system-mt.dylib \
      @loader_path/libboost_system-mt.dylib \
      "${BUILD_ROOT}/OBS-Sidekick-v1.app/Contents/Plugins/MFCBroadcast.so"
  fi

  if [ -f "${BUILD_ROOT}/OBS-Sidekick-v1.app/Contents/Plugins/websocketclient.dylib" ]; then
    install_name_tool -id \
      @rpath/websocketclient.dylib \
      "${BUILD_ROOT}/OBS-Sidekick-v1.app/Contents/Plugins/websocketclient.dylib"
    install_name_tool -change \
      @executable_path/../bin//libcrypto.1.1.dylib \
      @loader_path/libcrypto.1.1.dylib \
      "${BUILD_ROOT}/OBS-Sidekick-v1.app/Contents/Plugins/websocketclient.dylib"
    install_name_tool -change \
      @executable_path/../bin//libssl.1.1.dylib \
      @loader_path/libssl.1.1.dylib \
      "${BUILD_ROOT}/OBS-Sidekick-v1.app/Contents/Plugins/websocketclient.dylib"
  fi

  if [ -f "${BUILD_ROOT}/OBS-Sidekick-v1.app/Contents/Frameworks/libcrypto.1.1.dylib" ]; then
    install_name_tool -id \
      @rpath/libcrypto.1.1.dylib \
      "${BUILD_ROOT}/OBS-Sidekick-v1.app/Contents/Frameworks/libcrypto.1.1.dylib"
  fi
  if [ -f "${BUILD_ROOT}/OBS-Sidekick-v1.app/Contents/Frameworks/libssl.1.1.dylib" ]; then
    install_name_tool -id \
      @rpath/libssl.1.1.dylib \
      "${BUILD_ROOT}/OBS-Sidekick-v1.app/Contents/Frameworks/libssl.1.1.dylib"
    install_name_tool -change \
      @executable_path/../bin//libcrypto.1.1.dylib \
      @loader_path/libcrypto.1.1.dylib \
      "${BUILD_ROOT}/OBS-Sidekick-v1.app/Contents/Frameworks/libssl.1.1.dylib"
  fi

  if [ -f "${BUILD_ROOT}/OBS-Sidekick-v1.app/Contents/Resources/obs-plugins/MFCBroadcast.so" ]; then
    hr "MFCBroadcast.so: Fixing dependencies"
    # Copy missing boost dylib into app bundle
    cp "${BOOST_ROOT}/lib/libboost_system-mt.dylib" "${BUILD_ROOT}/OBS-Sidekick-v1.app/Contents/Resources/bin/"
    install_name_tool -id \
      @rpath/libboost_system-mt.dylib \
      "${BUILD_ROOT}/OBS-Sidekick-v1.app/Contents/Resources/bin/libboost_system-mt.dylib"
    install_name_tool -change \
      @rpath/libobs.0.dylib \
      @executable_path/libobs.0.dylib \
      "${BUILD_ROOT}/OBS-Sidekick-v1.app/Contents/Resources/obs-plugins/MFCBroadcast.so"
    install_name_tool -change \
      @rpath/libobs-frontend-api.dylib \
      @executable_path/libobs-frontend-api.dylib \
      "${BUILD_ROOT}/OBS-Sidekick-v1.app/Contents/Resources/obs-plugins/MFCBroadcast.so"
    install_name_tool -change \
      @rpath/QtCore \
      @executable_path/QtCore \
      "${BUILD_ROOT}/OBS-Sidekick-v1.app/Contents/Resources/obs-plugins/MFCBroadcast.so"
    install_name_tool -change \
      @rpath/QtGui \
      @executable_path/QtGui \
      "${BUILD_ROOT}/OBS-Sidekick-v1.app/Contents/Resources/obs-plugins/MFCBroadcast.so"
    install_name_tool -change \
      @rpath/QtSvg \
      @executable_path/QtSvg \
      "${BUILD_ROOT}/OBS-Sidekick-v1.app/Contents/Resources/obs-plugins/MFCBroadcast.so"
    install_name_tool -change \
      @rpath/QtWidgets \
      @executable_path/QtWidgets \
      "${BUILD_ROOT}/OBS-Sidekick-v1.app/Contents/Resources/obs-plugins/MFCBroadcast.so"
    install_name_tool -change \
      @rpath/websocketclient.dylib \
      @loader_path/websocketclient.dylib \
      "${BUILD_ROOT}/OBS-Sidekick-v1.app/Contents/Resources/obs-plugins/MFCBroadcast.so"
    install_name_tool -change \
      @rpath/libcrypto.1.1.dylib \
      @loader_path/libcrypto.1.1.dylib \
      "${BUILD_ROOT}/OBS-Sidekick-v1.app/Contents/Resources/obs-plugins/MFCBroadcast.so"
    install_name_tool -change \
      @rpath/libssl.1.1.dylib \
      @loader_path/libssl.1.1.dylib \
      "${BUILD_ROOT}/OBS-Sidekick-v1.app/Contents/Resources/obs-plugins/MFCBroadcast.so"
    install_name_tool -change \
      @rpath/libboost_program_options-mt.dylib \
      @loader_path/libboost_program_options-mt.dylib \
      "${BUILD_ROOT}/OBS-Sidekick-v1.app/Contents/Resources/obs-plugins/MFCBroadcast.so"
    install_name_tool -change \
      @rpath/libboost_date_time-mt.dylib \
      @loader_path/libboost_date_time-mt.dylib \
      "${BUILD_ROOT}/OBS-Sidekick-v1.app/Contents/Resources/obs-plugins/MFCBroadcast.so"
    install_name_tool -change \
      @rpath/libboost_thread-mt.dylib \
      @loader_path/libboost_thread-mt.dylib \
      "${BUILD_ROOT}/OBS-Sidekick-v1.app/Contents/Resources/obs-plugins/MFCBroadcast.so"
  fi

  install_name_tool -id \
    @rpath/websocketclient.dylib \
    "${BUILD_ROOT}/OBS-Sidekick-v1.app/Contents/Resources/obs-plugins/websocketclient.dylib"
  install_name_tool -change \
    @rpath/libobs.0.dylib \
    @executable_path/libobs.0.dylib \
    "${BUILD_ROOT}/OBS-Sidekick-v1.app/Contents/Resources/obs-plugins/websocketclient.dylib"
  install_name_tool -change \
    @rpath/libssl.1.1.dylib \
    @loader_path/libssl.1.1.dylib \
    "${BUILD_ROOT}/OBS-Sidekick-v1.app/Contents/Resources/obs-plugins/websocketclient.dylib"
  install_name_tool -change \
    @rpath/libcrypto.1.1.dylib \
    @loader_path/libcrypto.1.1.dylib \
    "${BUILD_ROOT}/OBS-Sidekick-v1.app/Contents/Resources/obs-plugins/websocketclient.dylib"

  install_name_tool -change \
    @rpath/libcrypto.1.1.dylib \
    @loader_path/libcrypto.1.1.dylib \
    "${BUILD_ROOT}/OBS-Sidekick-v1.app/Contents/Resources/bin/libssl.1.1.dylib"

  if [ -f "${BUILD_ROOT}/OBS-Sidekick-v1.app/Contents/Frameworks/libcrypto.1.1.dylib" ]; then
    install_name_tool -id \
      @rpath/libcrypto.1.1.dylib \
      "${BUILD_ROOT}/OBS-Sidekick-v1.app/Contents/Frameworks/libcrypto.1.1.dylib"
  fi
  if [ -f "${BUILD_ROOT}/OBS-Sidekick-v1.app/Contents/Frameworks/libssl.1.1.dylib" ]; then
    install_name_tool -id \
      @rpath/libssl.1.1.dylib \
      "${BUILD_ROOT}/OBS-Sidekick-v1.app/Contents/Frameworks/libssl.1.1.dylib"
    install_name_tool -change \
      @executable_path/../bin//libcrypto.1.1.dylib \
      @loader_path/libcrypto.1.1.dylib \
      "${BUILD_ROOT}/OBS-Sidekick-v1.app/Contents/Frameworks/libssl.1.1.dylib"
  fi

  if [ -f "${BUILD_ROOT}/OBS-Sidekick-v1.app/Contents/Frameworks/libboost_date_time-mt.dylib" ]; then
    install_name_tool -id \
      @rpath/libboost_date_time-mt.dylib \
      "${BUILD_ROOT}/OBS-Sidekick-v1.app/Contents/Frameworks/libboost_date_time-mt.dylib"
  fi
  if [ -f "${BUILD_ROOT}/OBS-Sidekick-v1.app/Contents/Frameworks/libboost_program_options-mt.dylib" ]; then
    install_name_tool -id \
      @rpath/libboost_program_options-mt.dylib \
      "${BUILD_ROOT}/OBS-Sidekick-v1.app/Contents/Frameworks/libboost_program_options-mt.dylib"
  fi
  if [ -f "${BUILD_ROOT}/OBS-Sidekick-v1.app/Contents/Frameworks/libboost_system-mt.dylib" ]; then
    install_name_tool -id \
      @rpath/libboost_system-mt.dylib \
      "${BUILD_ROOT}/OBS-Sidekick-v1.app/Contents/Frameworks/libboost_system-mt.dylib"
  fi
  if [ -f "${BUILD_ROOT}/OBS-Sidekick-v1.app/Contents/Frameworks/libboost_thread-mt.dylib" ]; then
    install_name_tool -id \
      @rpath/libboost_thread-mt.dylib \
      "${BUILD_ROOT}/OBS-Sidekick-v1.app/Contents/Frameworks/libboost_thread-mt.dylib"
    install_name_tool -change \
      @executable_path/../bin//libboost_system-mt.dylib \
      @loader_path/libboost_system-mt.dylib \
      "${BUILD_ROOT}/OBS-Sidekick-v1.app/Contents/Frameworks/libboost_thread-mt.dylib"
  fi

  # Package app
  hr "Generating package"
  packagesbuild "${SIDEKICK_ROOT}/scripts/install/osx/sidekick-v1.pkgproj"

  set +e
  rm -rf "${BUILD_ROOT}/OBS-Sidekick-v1.app"
  rm -f "${BUILD_ROOT}/OBS-v1.app/Contents/Resources/obs-plugins/MFCBroadcast.so" 2> /dev/null
  rm -f "${BUILD_ROOT}/OBS-v1.app/Contents/Resources/obs-plugins/MFCUpdater.so" 2> /dev/null
  rm -f "${BUILD_ROOT}/OBS-v1.app/Contents/Resources/obs-plugins/websocketclient.dylib" 2> /dev/null
  rm -f "${BUILD_ROOT}/OBS-v1.app/Contents/Resources/bin/websocketclient.dylib" 2> /dev/null
  rm -f "${BUILD_ROOT}"/OBS-v1.app/Contents/Resources/bin/libboost* 2> /dev/null

  hr "Finished building Sidekick for OBS 23-24.0.2"
  if [ "${BUILD_TYPE}" = "Release" ]; then
    mv "${BUILD_ROOT}/Sidekick.pkg" "${BUILD_ROOT}/Sidekick-v1-${YYYYMMDD}.pkg"
    cp -a "${BUILD_ROOT}/Sidekick-v1-${YYYYMMDD}.pkg" "${BUILD_ROOT}/Sidekick-v1.pkg"
    hr "BUILD_TYPE:            ${BUILD_TYPE}" " " "Package location:" " " "${BUILD_ROOT}/Sidekick-v1.pkg"
  else
    mv "${BUILD_ROOT}/Sidekick.pkg" "${BUILD_ROOT}/Sidekick-v1-${BUILD_TYPE}-${YYYYMMDD}.pkg"
    cp -a "${BUILD_ROOT}/Sidekick-v1-${BUILD_TYPE}-${YYYYMMDD}.pkg" "${BUILD_ROOT}/Sidekick-v1-${BUILD_TYPE}.pkg"
    hr "BUILD_TYPE:            ${BUILD_TYPE}" " " "Package location:" " " "${BUILD_ROOT}/Sidekick-v1-${BUILD_TYPE}.pkg"
  fi

  end=$(date '+%Y-%m-%d %H:%M:%S')
  end_ts=$(date +%s)
  runtime=$((end_ts-start_ts))
  hours=$((runtime / 3600))
  minutes=$(( (runtime % 3600) / 60 ))
  seconds=$(( (runtime % 3600) % 60 ))

  echo
  echo   "Start:           ${start}"
  echo   "End:             ${end}"
  printf "Elapsed:         (hh:mm:ss) %02d:%02d:%02d\n" ${hours} ${minutes} ${seconds}

  # Restore previously selected Xcode
  sudo xcode-select --switch "${XCODE_SELECT}"
}

main "$@"
