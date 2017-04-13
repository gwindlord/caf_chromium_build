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

pushd $LOCAL_REPO/src/v8
  git reset --hard HEAD
popd

#gclient sync --with_branch_heads
gclient sync -v -r refs/remotes/origin/m58

