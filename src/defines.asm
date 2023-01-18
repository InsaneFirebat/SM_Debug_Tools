
; --------
; Menu RAM
; --------

!ram_tilemap_buffer = $7E5800

!DP_MenuIndices = $00 ; 0x4
!DP_CurrentMenu = $04 ; 0x4
!DP_Address = $08 ; 0x4
!DP_JSLTarget = $0C ; 0x4
!DP_CtrlInput = $10 ; 0x4
!DP_Palette = $14
!DP_Temp = $16
; v these repeat v
!DP_ToggleValue = $18
!DP_Increment = $1A
!DP_Minimum = $1C
!DP_Maximum = $1E
!DP_DrawValue = $18
!DP_FirstDigit = $1A
!DP_SecondDigit = $1C
!DP_ThirdDigit = $1E

; !DEBUGMENU is defined in main.asm
!ram_cm_menu_stack = !DEBUGMENU+$00 ; $10 bytes
!ram_cm_cursor_stack = !DEBUGMENU+$10 ; $10 bytes

!ram_cm_stack_index = !DEBUGMENU+$20
!ram_cm_cursor_max = !DEBUGMENU+$22
!ram_cm_menu_bank = !DEBUGMENU+$24
!ram_cm_leave = !DEBUGMENU+$26
!ram_cm_controller = !DEBUGMENU+$28
!ram_cm_input_counter = !DEBUGMENU+$2A
!ram_cm_input_timer = !DEBUGMENU+$2C
!ram_cm_init = !DEBUGMENU+$2E

!ram_cm_ctrl_assign = !DEBUGMENU+$30
!ram_cm_ctrl_swap = !DEBUGMENU+$32

!ram_mem_editor_active = !DEBUGMENU+$34
!ram_mem_editor_hi = !DEBUGMENU+$36
!ram_mem_editor_lo = !DEBUGMENU+$38
!ram_mem_address_bank = !DEBUGMENU+$3A
!ram_mem_address = !DEBUGMENU+$3C
!ram_mem_address_hi = !DEBUGMENU+$3E
!ram_mem_address_lo = !DEBUGMENU+$40
!ram_mem_memory_size = !DEBUGMENU+$42
!ram_mem_line_position = !DEBUGMENU+$44
!ram_mem_loop_counter = !DEBUGMENU+$46

!ram_cm_etanks = !DEBUGMENU+$48
!ram_cm_reserve = !DEBUGMENU+$4A
!ram_cm_varia = !DEBUGMENU+$4C
!ram_cm_gravity = !DEBUGMENU+$4E
!ram_cm_morph = !DEBUGMENU+$50
!ram_cm_bombs = !DEBUGMENU+$52
!ram_cm_spring = !DEBUGMENU+$54
!ram_cm_screw = !DEBUGMENU+$56
!ram_cm_hijump = !DEBUGMENU+$58
!ram_cm_space = !DEBUGMENU+$5A
!ram_cm_speed = !DEBUGMENU+$5C
!ram_cm_charge = !DEBUGMENU+$5E
!ram_cm_ice = !DEBUGMENU+$60
!ram_cm_wave = !DEBUGMENU+$62
!ram_cm_spazer = !DEBUGMENU+$64
!ram_cm_plasma = !DEBUGMENU+$66

!ram_soundtest_lib1 = !DEBUGMENU+$68
!ram_soundtest_lib2 = !DEBUGMENU+$6A
!ram_soundtest_lib3 = !DEBUGMENU+$6C
!ram_soundtest_music = !DEBUGMENU+$6E
!ram_music_toggle = !DEBUGMENU+$70

!ram_fix_scroll_offsets = !DEBUGMENU+$72

!ram_cgram_cache = !DEBUGMENU+$80 ; $20 bytes


; -----------------
; Crash Handler RAM
; -----------------

; !CRASHDUMP is defined in main.asm
!ram_crash_a = !CRASHDUMP
!ram_crash_x = !CRASHDUMP+$02
!ram_crash_y = !CRASHDUMP+$04
!ram_crash_dbp = !CRASHDUMP+$06
!ram_crash_sp = !CRASHDUMP+$08
!ram_crash_type = !CRASHDUMP+$0A
!ram_crash_draw_value = !CRASHDUMP+$0C
!ram_crash_stack_size = !CRASHDUMP+$0E

; Reserve 48 bytes for stack
!ram_crash_stack = !CRASHDUMP+$10

!ram_crash_page = !CRASHDUMP+$40
!ram_crash_palette = !CRASHDUMP+$42
!ram_crash_cursor = !CRASHDUMP+$44
!ram_crash_loop_counter = !CRASHDUMP+$46
!ram_crash_bytes_to_write = !CRASHDUMP+$48
!ram_crash_stack_line_position = !CRASHDUMP+$4A
!ram_crash_text = !CRASHDUMP+$4C
!ram_crash_text_bank = !CRASHDUMP+$4E
!ram_crash_text_palette = !CRASHDUMP+$50
!ram_crash_mem_viewer = !CRASHDUMP+$52
!ram_crash_mem_viewer_bank = !CRASHDUMP+$54
!ram_crash_temp = !CRASHDUMP+$56

!ram_crash_input = !CRASHDUMP+$60
!ram_crash_input_new = !CRASHDUMP+$62
!ram_crash_input_prev = !CRASHDUMP+$64
!ram_crash_input_timer = !CRASHDUMP+$66


; -------
; Symbols
; -------

!CONTROLLER_PRI = $8B
!CONTROLLER_PRI_NEW = $8F

!IH_INPUT_SHOT = $7E09B2
!IH_INPUT_JUMP = $7E09B4
!IH_INPUT_RUN = $7E09B6
!IH_INPUT_ITEM_CANCEL = $7E09B8
!IH_INPUT_ITEM_SELECT = $7E09BA
!IH_INPUT_ANGLE_UP = $7E09BE
!IH_INPUT_ANGLE_DOWN = $7E09BC

!MENU_CLEAR = #$000E
!MENU_BLANK = #$281F

!IH_INPUT_HELD = #$0001
!IH_INPUT_START = #$1000
!IH_INPUT_UP = #$0800
!IH_INPUT_DOWN = #$0400
!IH_INPUT_LEFTRIGHT = #$0300
!IH_INPUT_LEFT = #$0200
!IH_INPUT_RIGHT = #$0100

!CTRL_B = #$8000
!CTRL_Y = #$4000
!CTRL_SELECT = #$2000
!CTRL_A = #$0080
!CTRL_X = #$0040
!CTRL_L = #$0020
!CTRL_R = #$0010

!ACTION_TOGGLE              = #$0000
!ACTION_TOGGLE_BIT          = #$0002
!ACTION_TOGGLE_INVERTED     = #$0004
!ACTION_TOGGLE_BIT_INVERTED = #$0006
!ACTION_NUMFIELD            = #$0008
!ACTION_NUMFIELD_HEX        = #$000A
!ACTION_NUMFIELD_WORD       = #$000C
!ACTION_CHOICE              = #$000E
!ACTION_CTRL_INPUT          = #$0010
!ACTION_JSL                 = #$0012
!ACTION_JSL_SUBMENU         = #$0014
!ACTION_NUMFIELD_SOUND      = #$0016


; --------------
; Vanilla Labels
; --------------

!MUSIC_ROUTINE = $808FC1
!SFX_LIB1 = $80903F
!SFX_LIB2 = $8090C1
!SFX_LIB3 = $809143

!OAM_STACK_POINTER = $0590
!PB_EXPLOSION_STATUS = $0592
!NMI_REQUEST_FLAG = $05B4
!FRAME_COUNTER_8BIT = $05B5
!FRAME_COUNTER = $05B6
!DEBUG_MODE_FLAG = $05D1
!RANDOM_NUMBER = $05E5
!DISABLE_SOUNDS = $05F5
!SOUND_TIMER = $0686
!SCREEN_FADE_DELAY = $0723
!SCREEN_FADE_COUNTER = $0725
!LOAD_STATION_INDEX = $078B
!ROOM_ID = $079B
!AREA_ID = $079F
!ROOM_WIDTH_BLOCKS = $07A5
!ROOM_WIDTH_SCROLLS = $07A9
!MUSIC_DATA = $07F3
!MUSIC_TRACK = $07F5
!LAYER1_X = $0911
!LAYER1_Y = $0915
!CURRENT_SAVE_FILE = $0952
!GAMEMODE = $0998
!DOOR_FUNCTION_POINTER = $099C
!SAMUS_ITEMS_EQUIPPED = $09A2
!SAMUS_ITEMS_COLLECTED = $09A4
!SAMUS_BEAMS_EQUIPPED = $09A6
!SAMUS_BEAMS_COLLECTED = $09A8
!SAMUS_RESERVE_MODE = $09C0
!SAMUS_HP = $09C2
!SAMUS_HP_MAX = $09C4
!SAMUS_MISSILES = $09C6
!SAMUS_MISSILES_MAX = $09C8
!SAMUS_SUPERS = $09CA
!SAMUS_SUPERS_MAX = $09CC
!SAMUS_PBS = $09CE
!SAMUS_PBS_MAX = $09D0
!SAMUS_RESERVE_MAX = $09D4
!SAMUS_RESERVE_ENERGY = $09D6
!SAMUS_LAST_HP = $0A06
!SAMUS_POSE = $0A1C
!SAMUS_POSE_DIRECTION = $0A1E
!SAMUS_MOVEMENT_TYPE = $0A1F
!SAMUS_PREVIOUS_POSE = $0A20
!SAMUS_PREVIOUS_POSE_DIRECTION = $0A22
!SAMUS_PREVIOUS_MOVEMENT_TYPE = $0A23
!SAMUS_SHINE_TIMER = $0A68
!SAMUS_HEALTH_WARNING = $0A6A
!SAMUS_HYPER_BEAM = $0A76
!SAMUS_ANIMATION_TIMER = $0A94
!SAMUS_ANIMATION_FRAME = $0A96
!LIQUID_PHYSICS_TYPE = $0AD2
!SAMUS_X = $0AF6
!SAMUS_X_SUBPX = $0AF8
!SAMUS_Y = $0AFA
!SAMUS_Y_SUBPX = $0AFC
!SAMUS_X_RADIUS = $0AFE
!SAMUS_Y_RADIUS = $0B00
!SAMUS_SPRITEMAP_X = $0B04
!SAMUS_Y_SUBSPEED = $0B2C
!SAMUS_Y_SPEEDCOMBINED = $0B2D
!SAMUS_Y_SPEED = $0B2E
!SAMUS_Y_DIRECTION = $0B36
!SAMUS_DASH_COUNTER = $0B3F
!SAMUS_X_RUNSPEED = $0B42
!SAMUS_X_SUBRUNSPEED = $0B44
!SAMUS_X_MOMENTUM = $0B46
!SAMUS_X_SUBMOMENTUM = $0B48
!SAMUS_PROJ_X = $0B64
!SAMUS_PROJ_Y = $0B78
!SAMUS_PROJ_RADIUS_X = $0BB4
!SAMUS_PROJ_RADIUS_Y = $0BC8
!SAMUS_COOLDOWN = $0CCC
!SAMUS_CHARGE_TIMER = $0CD0
!SAMUS_BOMB_COUNTER = $0CD2
!SAMUS_HEALTH_DROP_FLAG = $0E1A
!ENEMY_X = $0F7A
!ENEMY_Y = $0F7E
!ENEMY_X_RADIUS = $0F82
!ENEMY_Y_RADIUS = $0F84
!ENEMY_PROPERTIES_2 = $0F88
!ENEMY_HP = $0F8C
!ENEMY_SPRITEMAP = $0F8E
!ENEMY_BANK = $0FA6
!SAMUS_IFRAME_TIMER = $18A8
!SAMUS_KNOCKBACK_TIMER = $18AA
!ENEMY_PROJ_ID = $1997
!ENEMY_PROJ_X = $1A4B
!ENEMY_PROJ_Y = $1A93
!ENEMY_PROJ_RADIUS = $1BB3

