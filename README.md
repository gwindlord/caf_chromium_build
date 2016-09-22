# Chromium CAF Snapdragon M53 Build Scripts

1. Setup build environment as it is described [here](https://www.codeaurora.org/xwiki/bin/Chromium+for+Snapdragon/Setup)
  (though I use OpenJDK instead or Oracle one and everything works)
2. Clone this repo to dir where to build
3. Follow items 2-4 of this guide http://forum.xda-developers.com/general/general/guide-building-chromium-snapdragon-t3255475
  (item 1 is recommended, but I use Debian 8 and it works; hint: use *--unsupported* parameter for forcible install)
  In case of non-Ubuntu please check with [official packages manual](https://chromium.googlesource.com/chromium/src/+/master/docs/linux_build_instructions_prerequisites.md)
4. Change *LogsDir* in **./build/run.sh** if necessary
5. Make sure that you're in the dir where to build
6. To update run **./build/update.sh**
7. To build run **./build/make.sh**
8. Result is in **src/out/Default/apks**

Credits go to:
- [Chromium.org](https://www.chromium.org/);
- *CodeAurora* for their [code](https://codeaurora.org/cgit/quic/chrome4sdp/chromium/src?h=m53);
- *BachMinuetInG* for his guide;
