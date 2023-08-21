@echo off

echo SM Hack Debugging Tools

cd build
echo Building and pre-patching as defined in main.asm
cp HACK.sfc Debug_HACK.sfc && cd ..\src && ..\tools\asar\asar --no-title-check --symbols=wla --symbols-path=..\build\Debug_Symbols.sym -DFEATURE_DEBUG_MENU=1 -DFEATURE_CRASH_HANDLER=1 -DCRASH_EXTRA_PAGES=1 main.asm ..\build\Debug_HACK.sfc && cd ..

rem Change 'HACK.sfc' above to match the file name of your rom in the build directory

PAUSE
