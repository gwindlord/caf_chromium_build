#!/bin/bash

LOCAL_REPO="$(dirname $(dirname $(readlink -f $0)))"
ROMName=$(basename $LOCAL_REPO)
LogsDir="$HOME/logs"
export GYP_CHROMIUM_NO_ACTION=1 # don't process gyp

# errors on
set -e

if [ ! -d "$LogsDir" ]; then
  echo -e "\n"$(date +%D\ %T) "Logs directory '$LogsDir' not found, creating it..."
  mkdir -p "$LogsDir"
fi

# these lines explained at https://serverfault.com/a/103569
exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>$LogsDir/bg_build_${ROMName}_$(date +%F_%H_%M_%S).log 2>&1
# Everything below will go to the log file

cd $LOCAL_REPO/src
time ninja -C out/Default swe_browser_apk
