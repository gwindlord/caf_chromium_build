#!/bin/bash

LOCAL_REPO="$(dirname $(dirname $(readlink -f $0)))"
ROMName=$(basename $LOCAL_REPO)
export GYP_CHROMIUM_NO_ACTION=1 # don't process gyp

# errors on
set -e

pushd $LOCAL_REPO/src
  git clean -f -d
  git reset --hard HEAD
  rm -rf out
popd

#gclient sync --with_branch_heads
gclient sync
