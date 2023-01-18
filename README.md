# Super Metroid Debugging Tools

The main function of this repo is the debugging menu which can be opened at nearly anytime with a controller shortcut (default Start+Select). From there, menus can be accessed to do things like edit Samus' equipment, toggle event flags, warp to load stations, or view/edit memory. 

A Crash Handler is also provided, which displays a crash screen with information about the CPU state and stack when the crash was detected. Other tools may be added in the future, as they are developed.

New users should first look at `src/main.asm` to configure options and freespace usage. `src/mainmenu.asm` provides some documentation on adding/editing menu options. Feel free to open an issue on GitHub or contact me on Discord for assistance.


## Building IPS Patches:

1. Download and install Python 3+ from https://python.org. Windows users will need to set the PATH environmental variable to point to their Python installation folder.
2. Run build_patches.bat to create IPS patch files.
3. Locate the patch files in the /build/ folder.

## Auto-Patching Your ROM:

1. Rename your unheadered SM rom to `HACK.sfc` and place it in the /build/ folder.
2. Run build_fast.bat to generate a patched practice rom in /build/ named `Debug_HACK.sfc`.

## Thanks!

The debugging menu originates from the speedrun practice hack found at https://github.com/tewtal/sm_practice_hack

Thanks to the Metroid Construction Discord at https://discord.gg/xDwaaqa

