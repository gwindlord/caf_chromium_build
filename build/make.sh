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

mkdir -p $LOCAL_REPO/src/swe/channels/default/res/raw/ $LOCAL_REPO/src/swe/channels/system/res/raw/
cp -f $LOCAL_REPO/build/patches/swe_features/search_engines_preload $LOCAL_REPO/src/swe/channels/default/res/raw/
cp -f $LOCAL_REPO/build/patches/swe_features/search_engines_preload $LOCAL_REPO/src/swe/channels/system/res/raw/
git add -f $(git status -s | awk '{print $2}') && git commit -m "Adding DuckDuckGo and Bing search engines preload"

mkdir -p $LOCAL_REPO/src/swe/channels/default/values/ $LOCAL_REPO/src/swe/channels/system/values/
cp -f $LOCAL_REPO/build/patches/swe_features/overlay.xml $LOCAL_REPO/src/swe/channels/default/values/
cp -f $LOCAL_REPO/build/patches/swe_features/overlay.xml $LOCAL_REPO/src/swe/channels/system/values/
cp -f $LOCAL_REPO/build/patches/swe_features/strings.xml $LOCAL_REPO/src/swe/channels/default/values/
cp -f $LOCAL_REPO/build/patches/swe_features/strings.xml $LOCAL_REPO/src/swe/channels/system/values/
git add -f $(git status -s | awk '{print $2}') && git commit -m "Enabling Media Download for sure and disabling DRM upload restriction"

# Inox patches
git apply $LOCAL_REPO/build/patches/inox/chromium-sandbox-pie.patch && git add -f $(git status -s | awk '{print $2}') && git commit -m "Hardening the sandbox with Position Independent Code(PIE) against ROP exploits"
git apply $LOCAL_REPO/build/patches/inox/add-duckduckgo-search-engine.patch && git add -f $(git status -s | awk '{print $2}') && git commit -m "Adding DuckDuckGo search engine"

# ungoogled patches
git apply $LOCAL_REPO/build/patches/ungoogled/add-nosearch-search-engine.patch && git add -f $(git status -s | awk '{print $2}') && git commit -m "Adding search engine to disable searching in the omnibox"
git apply $LOCAL_REPO/build/patches/ungoogled/remove-get-help-button.patch && git add -f $(git status -s | awk '{print $2}') && git commit -m "Removes the 'Get help with using Chromium' button"

# get back sign-in and sync, hidden under ENABLE_SUPPRESSED_CHROMIUM_FEATURES flag
# M54
#git revert --no-edit 9e0363e4c8fc8efdaedc92a56410ffa3a425990f || git add $(git status -s | awk '{print $2}') && git revert --continue # Disable unsupported sign-in and sync
git apply $LOCAL_REPO/build/patches/signin.patch && git add -f $(git status -s | awk '{print $2}') && git commit -m "Revert 'Disable unsupported sign-in and sync' and 'Remove snippets UI from NTP'"
#git revert --no-edit c414136443d28864ee55f90e09cfc18d7037af4c # Remove snippets UI from NTP

cp -f $LOCAL_REPO/build/webrefiner/web_refiner_conf $LOCAL_REPO/src/chrome/android/java/res/raw/
git add -f $(git status -s | awk '{print $2}') && git commit -m "Shamelessly stealing WebRefiner config from JSwarts and extending it"

pushd $LOCAL_REPO/src/components/web_refiner/java/
  cp -rf $LOCAL_REPO/build/webrefiner/raw .
  zip -0TX libswewebrefiner_java.zip raw/web_defender_configuration.txt
  rm -rf raw/
  git add -f $(git status -s | awk '{print $2}') && git commit -m "Adding WebDefender custom configuration"
popd

cp -f $LOCAL_REPO/build/patches/swe_overlay.xml $LOCAL_REPO/src/chrome/android/java/res_swe/values-ru/
git add -f $(git status -s | awk '{print $2}') && git commit -m "Adding file with missed Russian translations"

# I do not know other way to get it themed, sorry
#git apply $LOCAL_REPO/build/patches/themes.patch && git add -f $(git status -s | awk '{print $2}') && git commit -m "Masking to Chrome Beta for themes support :->"

# better broken night mode than none
git revert --no-edit 9c20e31570e0c3baf04d178161401896b2228d0c

:<<comment

  # this is because they placed WebRefiner and WebDefender translation into zip archive >_<
  pushd $LOCAL_REPO/src/components/web_refiner/java/
    cp -rf $LOCAL_REPO/build/webrefiner/values-ru .
    zip -0TX libswewebrefiner_java.zip values-ru/strings.xml
    rm -rf values-ru/
    git add -f $(git status -s | awk '{print $2}') && git commit -m "Adding WebRefiner and WebDefender translation"
  popd

  # removing Google Translate tick as it does not work anyway
  git apply $LOCAL_REPO/build/patches/remove_translate.patch && git add -f $(git status -s | awk '{print $2}') && git commit -m "Remove page translation tick"

  #cp -f $LOCAL_REPO/build/patches/search_engines_preload $LOCAL_REPO/src/chrome/android/java/res_chromium/raw/search_engines_preload

comment

if [[ "$isCustom" != "--no-gn" ]];
then
  . build/android/envsetup.sh
  gclient runhooks -v
  gn gen out/Default --args='target_os="android" is_debug=false symbol_level=1'
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
