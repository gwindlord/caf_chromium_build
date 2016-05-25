#!/bin/bash

LOCAL_REPO="$(dirname $(dirname $(readlink -f $0)))"
ROMName=$(basename $LOCAL_REPO)
export GYP_CHROMIUM_NO_ACTION=1

# errors on
set -e

# parameter "--system" allows not to start the build immdeiately
# parameter "--no-gn" allows not to run "gclient runhooks -v" - to check the pervious commits logs
isCustom="$1"

cd $LOCAL_REPO/src

# this is because they placed WebRefiner and WebDefender translation into zip archive >_<
pushd $LOCAL_REPO/src/components/web_refiner/java/
  cp -rf $LOCAL_REPO/build/webrefiner/values-ru .
  zip -0TX libswewebrefiner_java.zip values-ru/strings.xml
  rm -rf values-ru/
  git add -f $(git status -s | awk '{print $2}') && git commit -m "Adding WebRefiner and WebDefender translation"
popd

# this commit is here because gclient changes some files and they need to be either reset or committed to make repo clean
git add -f $(git status -s | awk '{print $2}') && git commit -m "Dummy"

# reverting Google capabilities, hidden under ENABLE_SUPPRESSED_CHROMIUM_FEATURES flag
# some of them are part of other commits, so had to use patching
git apply $LOCAL_REPO/build/patches/signin.patch && git add -f $(git status -s | awk '{print $2}') && git commit -m "Getting sign-in back"

# I do not know other way to get it themed, sorry
#git apply $LOCAL_REPO/build/patches/themes.patch && git add -f $(git status -s | awk '{print $2}') && git commit -m "Masking to Chrome Beta for themes support :->"

# removing Google Translate tick as it does not work anyway
git apply $LOCAL_REPO/build/patches/remove_translate.patch && git add -f $(git status -s | awk '{print $2}') && git commit -m "Remove page translation tick"

cp -f $LOCAL_REPO/build/webrefiner/web_refiner_conf $LOCAL_REPO/src/chrome/android/java/res/raw/
git add -f $(git status -s | awk '{print $2}') && git commit -m "Shamelessly stealing WebRefiner config from JSwarts and extending it"

git apply $LOCAL_REPO/build/patches/inox/chromium-sandbox-pie.patch && git add -f $(git status -s | awk '{print $2}') && git commit -m "Hardening the sandbox with Position Independent Code(PIE) against ROP exploits"

#cp -f $LOCAL_REPO/build/patches/search_engines_preload $LOCAL_REPO/src/chrome/android/java/res_chromium/raw/search_engines_preload
mkdir -p $LOCAL_REPO/src/swe/channels/default/raw/ $LOCAL_REPO/src/swe/channels/system/raw/
cp -f $LOCAL_REPO/build/patches/swe_features/search_engines_preload $LOCAL_REPO/src/swe/channels/default/raw/
cp -f $LOCAL_REPO/build/patches/swe_features/search_engines_preload $LOCAL_REPO/src/swe/channels/system/raw/
git add -f $(git status -s | awk '{print $2}') && git commit -m "Adding DuckDuckGo and Bing search engines"

mkdir -p $LOCAL_REPO/src/swe/channels/default/values/ $LOCAL_REPO/src/swe/channels/system/values/
cp -f $LOCAL_REPO/build/patches/swe_features/overlay.xml $LOCAL_REPO/src/swe/channels/default/values/
cp -f $LOCAL_REPO/build/patches/swe_features/overlay.xml $LOCAL_REPO/src/swe/channels/system/values/
cp -f $LOCAL_REPO/build/patches/swe_features/strings.xml $LOCAL_REPO/src/swe/channels/default/values/
cp -f $LOCAL_REPO/build/patches/swe_features/strings.xml $LOCAL_REPO/src/swe/channels/system/values/
git add -f $(git status -s | awk '{print $2}') && git commit -m "Enabling Media Download for sure and disabling DRM upload restriction"

if [[ "$isCustom" != "--no-gn" ]];
then
  . build/android/envsetup.sh
  gn gen out/Default --args='target_os="android" enable_nacl=false is_debug=false is_component_build=false'
  # implementing custom translated lines build
  # now all translatons are stock - but keeping this as a nice w/a
  #patch -p0 < $LOCAL_REPO/build/patches/chrome_strings_grd_ninja.diff
else
  exit 0
fi

# for ROM build env - to allow it starting system package build itself
if [[ "$isCustom" != "--system" ]];
then
  $LOCAL_REPO/build/run.sh &
fi
