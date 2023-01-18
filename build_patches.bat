@echo off

rem Requires Python 3+

echo Building SM Hack Debugging Patch
cd tools
python create_dummies.py 00.sfc ff.sfc

echo Building IPS patches for full version
copy *.sfc ..\build
asar\asar --no-title-check -DFEATURE_DEBUG_MENU=1 -DFEATURE_CRASH_HANDLER=1 -DCRASH_EXTRA_PAGES=1 ..\src\main.asm ..\build\00.sfc
asar\asar --no-title-check ..\src\main.asm ..\build\ff.sfc
python create_ips.py ..\build\00.sfc ..\build\ff.sfc ..\build\Debug_Full.ips

echo Building IPS patches for menu version
copy *.sfc ..\build
asar\asar --no-title-check -DFEATURE_DEBUG_MENU=1 -DFEATURE_CRASH_HANDLER=0 -DCRASH_EXTRA_PAGES=0 ..\src\main.asm ..\build\00.sfc
asar\asar --no-title-check ..\src\main.asm ..\build\ff.sfc
python create_ips.py ..\build\00.sfc ..\build\ff.sfc ..\build\Debug_Menu.ips

echo Building IPS patches for crash-lite version
copy *.sfc ..\build
asar\asar --no-title-check -DFEATURE_DEBUG_MENU=0 -DFEATURE_CRASH_HANDLER=1 -DCRASH_EXTRA_PAGES=0 ..\src\main.asm ..\build\00.sfc
asar\asar --no-title-check ..\src\main.asm ..\build\ff.sfc
python create_ips.py ..\build\00.sfc ..\build\ff.sfc ..\build\Debug_Crash.ips

del 00.sfc ff.sfc ..\build\00.sfc ..\build\ff.sfc
cd ..

PAUSE
