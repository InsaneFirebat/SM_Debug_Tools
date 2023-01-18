
lorom

table ../resources/normal.tbl

; ====================================================================================================================
; This section is where you'll configure freespace usage and toggle debug features

; The crash handler displays stack and register information upon a crash
!FEATURE_CRASH_HANDLER = 0
!CRASH_EXTRA_PAGES = 0 ; Set to 1 to add the memory viewer and extra page to the crash handler
!CRASHDUMP = $7FFD00 ; Change this to move all menu RAM at once, ~$A0 bytes
!FREESPACE_CRASH_HANDLER = $80E000 ; Must live in bank $80 by default, <$200 bytes without extra pages
!FREESPACE_CRASH_HANDLER_CODE = $80E200 ; <640h bytes if single page, <A00h bytes if extra pages enabled, banks $80-BF
!FREESPACE_CRASH_HANDLER_TEXT = $DEEE00 ; <100-200h bytes that can live anywhere in the ROM
!FREESPACE_CRASH_HANDLER_GFX = $DFF700 ; $900 bytes

; The debug menu adds many debugging tools accessible from a controller shortcut
!FEATURE_DEBUG_MENU = 1
!DEBUG_MENU_SHORTCUT = #$3000 ; Start + Select
!DEBUGMENU = $7EFD00 ; Change this to move all menu RAM at once, ~$70 bytes, initialized to zero
!FREESPACE_DEBUG_MENU_CODE = $89B000 ; <$1500 bytes
!FREESPACE_DEBUG_MENU_GFX = $B8F700 ; $900 bytes
!FREESPACE_DEBUG_MENU_BANK80 = $80F000 ; $14 bytes
!FREESPACE_DEBUG_MENU_BANK85 = $85FFC0 ; <$30 bytes
; The following MENU orgs are commented out in mainmenu.asm
; They will default to the end of FREESPACE_DEBUG_MENU_CODE
; Uncomment those orgs to move them anywhere in banks $80-$BF
!FREESPACE_DEBUG_MENU_EQUIPMENT = $AFF300 ; <$B00 bytes
!FREESPACE_DEBUG_MENU_TELEPORT = $ADF700 ; <$900 bytes
!FREESPACE_DEBUG_MENU_MISC = $AEFE00 ; <$200 bytes
!FREESPACE_DEBUG_MENU_EVENTS = $B4FC00 ; <$400 bytes
!FREESPACE_DEBUG_MENU_GAME = $B5FA00 ; <$600 bytes
!FREESPACE_DEBUG_MENU_SOUND = $B6FA00 ; <$600 bytes
!FREESPACE_DEBUG_MENU_EDITOR = $B7FE00 ; <$200 bytes
; Optional, uncomment in mainmenu.asm and misc.asm
!FREESPACE_DEBUG_MISC_BANK80 = $80FD00 ; <$20 bytes

; ====================================================================================================================

incsrc macros.asm
incsrc defines.asm

if !FEATURE_CRASH_HANDLER
incsrc crash.asm
endif

if !FEATURE_DEBUG_MENU
incsrc gamemode.asm
incsrc menu.asm
incsrc misc.asm
endif

cleartable ; set text assignment back to default (ASCII)
