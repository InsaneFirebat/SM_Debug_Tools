
; The menu makes heavy use of direct page (DP) indirect addressing.
; The value stored in the DP address is treated as a pointer,
; and the value at that pointer address is loaded instead.
; [Square brackets] indicate long addressing, and a third byte
; of DP is used as the bank byte for 24bit addressing.


org !FREESPACE_DEBUG_MENU_BANK85
print pc, " menu bank85 start"

wait_for_lag_frame_long:
    JSR $8136
    RTL

initialize_ppu_long:
    PHP : %a16()
    LDA $7E33EA : STA !ram_cgram_cache+$1E
    PLP
    JSR $8143
    RTL

restore_ppu_long:
    JSR $861A
    PHP : %a16()
    LDA !ram_cgram_cache+$1E : STA $7E33EA
    PLP
    RTL

play_music_long:
    JSR $8574
    RTL

maybe_trigger_pause_long:
    JSR $80FA
    RTL

print pc, " menu bank85 end"


org !FREESPACE_DEBUG_MENU_CODE
print pc, " menu start"

cm_start:
{
    PHP
    PHB : PHK : PLB

    ; Ensure sound is enabled when menu is open
    LDA !DISABLE_SOUNDS : PHA
    STZ !DISABLE_SOUNDS
    LDA !PB_EXPLOSION_STATUS : PHA
    STZ !PB_EXPLOSION_STATUS
    JSL $82BE17 ; Cancel sound effects

    JSR cm_init
    JSL cm_draw
    JSL play_music_long ; Play 2 lag frames of music and sound effects

    JSR cm_loop

    ; Restore sounds variables
    PLA : STA !PB_EXPLOSION_STATUS
    PLA : STA !DISABLE_SOUNDS
    ; Makes the game checks Samus' health again, to see if we need annoying sound
    STZ !SAMUS_HEALTH_WARNING

    JSR cm_exit

    PLB : PLP
    RTL
}

cm_init:
{
    ; Setup registers
    %a8()
    STZ $420C
    LDA #$80 : STA $802100 ; enable forced blanking
    LDA #$A1 : STA $4200 ; enable NMI, v-IRQ, and auto-joy read
    LDA #$09 : STA $2105 ; BG Mode 1, enable BG3 priority
    LDA #$0F : STA $0F2100 ; disable forced blanking
    %a16()

    JSL initialize_ppu_long
    JSL cm_transfer_custom_tileset
    JSL cm_transfer_custom_cgram
    JSL cm_clear_tilemap

    ; Set up menu state
    LDA #$0000 : STA !ram_cm_leave
    STA !ram_cm_stack_index : STA !ram_cm_cursor_stack
    STA !CONTROLLER_PRI_NEW : STA !CONTROLLER_PRI

    LDA !FRAME_COUNTER : STA !ram_cm_input_counter
    LDA.w #MainMenu : STA !ram_cm_menu_stack
    LDA.w #MainMenu>>16 : STA !ram_cm_menu_bank

    LDA !ram_cm_init : BNE +
    JSR cm_first_menu_open

+   JSL SetupEquipmentMenus

    JSL cm_calculate_max

    RTS
}

cm_first_menu_open:
{
; Init non-zero values that can be retained after menu is closed
    LDA #$0001
    STA !ram_soundtest_lib1 : STA !ram_soundtest_lib2
    STA !ram_soundtest_lib3 : STA !ram_music_toggle
    STA !ram_cm_init

    LDA #$007E : STA !ram_mem_address_bank
    LDA #!SAMUS_HP : STA !ram_mem_address

    RTS
}

cm_exit:
{
    JSL wait_for_lag_frame_long
    JSL cm_transfer_original_tileset
    JSR cm_transfer_original_cgram

    ; Update HUD (in case we added missiles etc.)
    JSL $809A79 ; Initialise HUD
    JSL $809B44 ; Handle HUD tilemap

    JSL restore_ppu_long ; Restore PPU

    ; skip sound effects if not gameplay ($7-13 allowed)
    %ai16()
    LDA !GAMEMODE : CMP #$0006 : BMI .skipSFX
    CMP #$0014 : BPL .skipSFX
    JSL $82BE2F ; Queue Samus movement sound effects

  .skipSFX
    JSL play_music_long ; Play 2 lag frames of music and sound effects
    JSL maybe_trigger_pause_long ; Maybe trigger pause screen or return save confirmation selection
    RTS
}


; ----------
; Drawing
; ----------

cm_transfer_custom_tileset:
{
    PHP : %i16() : %a8()
    LDX !ROOM_ID : CPX #$A59F : BEQ .kraid_vram

    ; Load custom vram to normal location
    LDA #$80 : STA $802100 ; enable forced blanking
    LDA #$04 : STA $210C ; BG3 starts at $4000 (8000 in vram)
    LDA #$80 : STA $2115 ; word-access, incr by 1
    LDX #$4000 : STX $2116 ; VRAM address (8000 in vram)
    LDX #cm_hud_table : STX $4302 ; Source offset
    LDA.b #cm_hud_table>>16 : STA $4304 ; Source bank
    LDX #$0900 : STX $4305 ; Size (0x10 = 1 tile)
    LDA #$01 : STA $4300 ; word, normal increment (DMA MODE)
    LDA #$18 : STA $4301 ; destination (VRAM write)
    LDA #$01 : STA $420B ; initiate DMA (channel 1)
    LDA #$0F : STA $0F2100 ; enable forced blanking
    PLP
    RTL

  .kraid_vram
    ; Load custom vram to kraid location
    LDA #$80 : STA $802100 ; enable forced blanking
    LDA #$02 : STA $210C ; BG3 starts at $2000 (4000 in vram)
    LDA #$80 : STA $2115 ; word-access, incr by 1
    LDX #$2000 : STX $2116 ; VRAM address (4000 in vram)
    LDX #cm_hud_table : STX $4302 ; Source offset
    LDA.b #cm_hud_table>>16 : STA $4304 ; Source bank
    LDX #$0900 : STX $4305 ; Size (0x10 = 1 tile)
    LDA #$01 : STA $4300 ; word, normal increment (DMA MODE)
    LDA #$18 : STA $4301 ; destination (VRAM write)
    LDA #$01 : STA $420B ; initiate DMA (channel 1)
    LDA #$0F : STA $0F2100 ; disable forced blanking
    PLP
    RTL
}

cm_transfer_original_tileset:
{
    PHP : %i16() : %a8()
    LDX !ROOM_ID : CPX #$A59F : BEQ .kraid_vram

    ; Load in normal vram to normal location
    LDA #$80 : STA $802100 ; enable forced blanking
    LDA #$04 : STA $210C ; BG3 starts at $4000 (8000 in vram)
    LDA #$80 : STA $2115 ; word-access, incr by 1
    LDX #$4000 : STX $2116 ; VRAM address (8000 in vram)
    LDX #$B200 : STX $4302 ; Source offset
    LDA #$9A : STA $4304 ; Source bank
    LDX #$1000 : STX $4305 ; Size (0x10 = 1 tile)
    LDA #$01 : STA $4300 ; word, normal increment (DMA MODE)
    LDA #$18 : STA $4301 ; destination (VRAM write)
    LDA #$01 : STA $420B ; initiate DMA (channel 1)
    LDA #$0F : STA $0F2100 ; disable forced blanking
    PLP
    RTL

  .kraid_vram
    ; Load in normal vram to kraid location
    LDA #$80 : STA $802100 ; enable forced blanking
    LDA #$02 : STA $210C ; BG3 starts at $2000 (4000 in vram)
    LDA #$80 : STA $2115 ; word-access, incr by 1
    LDX #$2000 : STX $2116 ; VRAM address (4000 in vram)
    LDX #$B200 : STX $4302 ; Source offset
    LDA #$9A : STA $4304 ; Source bank
    LDX #$1000 : STX $4305 ; Size (0x10 = 1 tile)
    LDA #$01 : STA $4300 ; word, normal increment (DMA MODE)
    LDA #$18 : STA $4301 ; destination (VRAM write)
    LDA #$01 : STA $420B ; initiate DMA (channel 1)
    LDA #$0F : STA $0F2100 ; disable forced blanking
    PLP
    RTL
}

cm_transfer_custom_cgram:
{
; $0A = Border & OFF   $7277
; $12 = Header         $48F3
; $1A = Num            $0000, $7FFF
; $32 = ON / Sel Num   $4376
; $34 = Selected item  $761F
; $3A = Sel Num        $0000, $761F
    %a16()
    ; backup gameplay palettes
    LDA $7EC00A : STA !ram_cgram_cache
    LDA $7EC00E : STA !ram_cgram_cache+$02
    LDA $7EC012 : STA !ram_cgram_cache+$04
    LDA $7EC014 : STA !ram_cgram_cache+$06
    LDA $7EC016 : STA !ram_cgram_cache+$08
    LDA $7EC01A : STA !ram_cgram_cache+$0A
    LDA $7EC01C : STA !ram_cgram_cache+$0C
    LDA $7EC032 : STA !ram_cgram_cache+$0E
    LDA $7EC034 : STA !ram_cgram_cache+$10
    LDA $7EC036 : STA !ram_cgram_cache+$12
    LDA $7EC03A : STA !ram_cgram_cache+$14
    LDA $7EC03C : STA !ram_cgram_cache+$16

    ; apply menu palettes
    LDA #$0000 : STA $7EC000
    STA $7EC016 : STA $7EC00E ; background
    LDA #$7277 : STA $7EC00A ; border
    LDA #$48F3 : STA $7EC012 ; header outline
    LDA #$7FFF : STA $7EC014 ; text
    LDA #$0000 : STA $7EC01A ; number outline
    LDA #$7FFF : STA $7EC01C ; number fill
    LDA #$4376 : STA $7EC032 ; toggle on
    LDA #$761F : STA $7EC034 ; selected text
    LDA #$0000 : STA $7EC036 ; selected text background
    LDA #$0000 : STA $7EC03A ; selected number outline
    LDA #$761F : STA $7EC03C ; selected number fill

    JSL transfer_cgram_long
    %ai16()
    RTL
}

cm_transfer_original_cgram:
{
    PHP : %a16()
    ; restore gameplay palettes
    LDA !ram_cgram_cache : STA $7EC00A
    LDA !ram_cgram_cache+$02 : STA $7EC00E
    LDA !ram_cgram_cache+$04 : STA $7EC012
    LDA !ram_cgram_cache+$06 : STA $7EC014
    LDA !ram_cgram_cache+$08 : STA $7EC016
    LDA !ram_cgram_cache+$0A : STA $7EC01A
    LDA !ram_cgram_cache+$0C : STA $7EC01C
    LDA !ram_cgram_cache+$0E : STA $7EC032
    LDA !ram_cgram_cache+$10 : STA $7EC034
    LDA !ram_cgram_cache+$12 : STA $7EC036
    LDA !ram_cgram_cache+$14 : STA $7EC03A
    LDA !ram_cgram_cache+$16 : STA $7EC03C

    JSL transfer_cgram_long
    PLP
    RTS
}

cm_draw:
{
    PHP
    %ai16()
    JSL cm_tilemap_bg
    JSR cm_tilemap_menu
    JSR cm_memory_editor
    JSR cm_tilemap_transfer
    PLP
    RTL
}

cm_clear_tilemap:
{
    RTL
}

cm_tilemap_bg:
{
    ; top left corner  = $042
    ; top right corner = $07C
    ; bot left corner  = $682
    ; bot right corner = $6BC
	; Empty out !ram_tilemap_buffer
    LDX #$07FE
    LDA !MENU_BLANK ; change to !MENU_CLEAR for transparent backgrounds
  .clearBG3
    STA !ram_tilemap_buffer,X
    DEX #2 : BPL .clearBG3

    ; Vertical edges
    LDX #$0000
    LDY #$0019 ; 25 rows
  .loopVertical
    LDA #$647A : STA !ram_tilemap_buffer+$082,X
    LDA #$247A : STA !ram_tilemap_buffer+$0BC,X
    TXA : CLC : ADC #$0040 : TAX
    DEY : BPL .loopVertical

    ; Horizontal edges
    LDX #$0000
    LDY #$001B ; 28 columns
  .loopHorizontal
    LDA #$A47B : STA !ram_tilemap_buffer+$044,X
    LDA #$247B : STA !ram_tilemap_buffer+$704,X
    INX #2
    DEY : BPL .loopHorizontal

    ; Interior
    LDX #$0000
    LDY #$001B
    LDA !MENU_BLANK

  .interior_loop
;    STA !ram_tilemap_buffer+$004,X
    STA !ram_tilemap_buffer+$084,X
    STA !ram_tilemap_buffer+$0C4,X
    STA !ram_tilemap_buffer+$104,X
    STA !ram_tilemap_buffer+$144,X
    STA !ram_tilemap_buffer+$184,X
    STA !ram_tilemap_buffer+$1C4,X
    STA !ram_tilemap_buffer+$204,X
    STA !ram_tilemap_buffer+$244,X
    STA !ram_tilemap_buffer+$284,X
    STA !ram_tilemap_buffer+$2C4,X
    STA !ram_tilemap_buffer+$304,X
    STA !ram_tilemap_buffer+$344,X
    STA !ram_tilemap_buffer+$384,X
    STA !ram_tilemap_buffer+$3C4,X
    STA !ram_tilemap_buffer+$404,X
    STA !ram_tilemap_buffer+$444,X
    STA !ram_tilemap_buffer+$484,X
    STA !ram_tilemap_buffer+$4C4,X
    STA !ram_tilemap_buffer+$504,X
    STA !ram_tilemap_buffer+$544,X
    STA !ram_tilemap_buffer+$584,X
    STA !ram_tilemap_buffer+$5C4,X
    STA !ram_tilemap_buffer+$604,X
    STA !ram_tilemap_buffer+$644,X
    STA !ram_tilemap_buffer+$684,X
    STA !ram_tilemap_buffer+$6C4,X

    INX #2
    DEY : BPL .interior_loop

  .done
    RTL
}

cm_tilemap_menu:
{
    LDA !ram_cm_stack_index : TAX
    LDA !ram_cm_menu_stack,X : STA !DP_MenuIndices
    LDA !ram_cm_menu_bank : STA !DP_MenuIndices+2 : STA !DP_CurrentMenu+2

    LDY #$0000 ; Y = menu item index
  .loop
    ; highlight if selected row
    TYA : CMP !ram_cm_cursor_stack,X : BEQ .selected
    LDA #$0000
    BRA .continue

  .selected
    LDA #$0010

  .continue
    ; later ORA'd with tile attributes
    STA !DP_Palette

    ; check for special entries (header/blank lines)
    LDA [!DP_MenuIndices],Y : BEQ .header
    CMP #$FFFF : BEQ .blank
    STA !DP_CurrentMenu

    PHY : PHX

    ; X = action index (action type)
    LDA [!DP_CurrentMenu] : TAX

    ; !DP_CurrentMenu points to data after the action type index
    INC !DP_CurrentMenu : INC !DP_CurrentMenu

    ; draw menu item
    JSR (cm_draw_action_table,X)

    PLX : PLY

  .blank
    ; skip drawing blank lines
    INY #2
    BRA .loop

  .header
    STZ !DP_Palette
    ; menu pointer + index + 2 = header
    TYA : CLC : ADC !DP_MenuIndices : INC #2 : STA !DP_CurrentMenu
    ; draw menu header
    LDX #$00C6
    JSR cm_draw_text

    ; menu pointer + header pointer + 1 = footer
    TYA : CLC : ADC !DP_CurrentMenu : INC : STA !DP_CurrentMenu
    LDA [!DP_CurrentMenu] : CMP #$F007 : BNE .done

    ; INC past #$F007
    INC !DP_CurrentMenu : INC !DP_CurrentMenu : STZ !DP_Palette
    ; Optional footer
    LDX #$0686
    JMP cm_draw_text

  .done
    ; no footer, back up two bytes
    DEC !DP_CurrentMenu : DEC !DP_CurrentMenu
    RTS
}

cm_memory_editor:
; Draws the memory values identified by the last digit of the 24-bit address
{
    LDA !ram_mem_editor_active : BNE +
    RTS

    ; assemble address word
+   %a8()
    LDA !ram_mem_address_hi : XBA : LDA !ram_mem_address_lo
    %a16()
    STA !ram_mem_address

    ; draw the address bank
    LDA !ram_mem_address_bank : STA !DP_DrawValue
    LDX #$044E : JSL cm_draw2_hex

    ; draw the address word
    %a16()
    LDA !ram_mem_address : STA !DP_DrawValue
    LDX #$0452 : JSL cm_draw4_hex

    ; assemble indirect address
    LDA !ram_mem_address_bank : STA !DP_Address+2
    LDA !ram_mem_address : STA !DP_Address
    LDA [!DP_Address] : STA !DP_DrawValue

    ; 16-bit or 8-bit
    LDA !ram_mem_memory_size : BNE .eight_bit

    ; draw the 16-bit hex value at address
    LDX #$042A : JSL cm_draw4_hex
    LDX #$0468 : JSL cm_draw5
    BRA .labels

  .eight_bit
    ; draw the 8-bit hex value at address
    %a8()
    LDX #$042A : JSL cm_draw2_hex
    LDX #$0468 : JSL cm_draw3

  .labels
    ; bunch of $ symbols
    LDA #$284E
    STA !ram_tilemap_buffer+$174 ; $Bank
    STA !ram_tilemap_buffer+$1B4 ; $High
    STA !ram_tilemap_buffer+$1F4 ; $Low
    STA !ram_tilemap_buffer+$2F4 ; $High
    STA !ram_tilemap_buffer+$334 ; $Low
    STA !ram_tilemap_buffer+$428 ; $Value
    STA !ram_tilemap_buffer+$44C ; $Address

    ; labeling for newbies
    LDA #$2C01
    STA !ram_tilemap_buffer+$40E ; B
    STA !ram_tilemap_buffer+$410 ; B
    LDA #$2C08 : STA !ram_tilemap_buffer+$414 ; I
    LDA #$2C0B : STA !ram_tilemap_buffer+$416 ; L
    LDA #$2C7D : STA !ram_tilemap_buffer+$418 ; O
    LDA #$2C07 : STA !ram_tilemap_buffer+$412 ; H

    ; HEX and DEC labels
    STA !ram_tilemap_buffer+$420 ; H
    LDA #$2C04
    STA !ram_tilemap_buffer+$422 ; E
    STA !ram_tilemap_buffer+$462 ; E
    LDA #$2C17 : STA !ram_tilemap_buffer+$424 ; X
    LDA #$2C03 : STA !ram_tilemap_buffer+$460 ; D
    LDA #$2C02 : STA !ram_tilemap_buffer+$464 ; C

    ; setup to draw $10 bytes of nearby RAM
    LDX #$0508
    %a8()
    LDA #$00 : STA !ram_mem_line_position : STA !ram_mem_loop_counter
    LDA !DP_Address : AND #$F0 : STA !DP_Address

  .drawNearbyMem
    ; draw a byte
    LDA [!DP_Address] : STA !DP_DrawValue
    JSL cm_draw2_hex
    INC !DP_Address

    ; inc tilemap position
    INX #6
    LDA !ram_mem_line_position : INC
    STA !ram_mem_line_position : AND #$08 : BEQ +

    ; start a new line
    LDA #$00 : STA !ram_mem_line_position
    %a16()
    ; skip a row and wrap to the beginning
    TXA : CLC : ADC #$0050 : TAX
    CPX #$05BA : BPL .doneNearbyMem
    %a8()

    ; inc bytes drawn
+   LDA !ram_mem_loop_counter : INC : STA !ram_mem_loop_counter
    CMP #$10 : BNE .drawNearbyMem
    %a16()

  .doneNearbyMem
    RTS
}

cm_tilemap_transfer:
{
    JSL wait_for_lag_frame_long ; Wait for lag frame

    %a16()
    LDA #$5800 : STA $2116 ; VRAM addr
    LDA #$1801 : STA $4310 ; VRAM write
    LDA.w #!ram_tilemap_buffer : STA $4312 ; src addr
    LDA.w #!ram_tilemap_buffer>>16 : STA $4314 ; src bank
    LDA #$0800 : STA $4315 ; size
    STZ $4317 : STZ $4319 ; clear HDMA registers
    %a8()
    LDA #$80 : STA $2115 ; INC mode
    LDA #$02 : STA $420B ; enable DMA, channel 1
    JSL $808F0C ; handle music queue
    JSL $8289EF ; handle sfx
    %a16()
    RTS
}

cm_tilemap_transfer_long:
{
    JSR cm_tilemap_transfer
    RTL
}

cm_draw_action_table:
{
    dw draw_toggle
    dw draw_toggle_bit
    dw draw_toggle_inverted
    dw draw_toggle_bit_inverted
    dw draw_numfield
    dw draw_numfield_hex
    dw draw_numfield_word
    dw draw_choice
    dw draw_controller_input
    dw draw_jsl
    dw draw_submenu
    dw draw_numfield_sound

draw_toggle:
{
    ; grab the memory address (long)
    LDA [!DP_CurrentMenu] : INC !DP_CurrentMenu : INC !DP_CurrentMenu : STA !DP_Address
    LDA [!DP_CurrentMenu] : INC !DP_CurrentMenu : STA !DP_Address+2

    ; grab the toggle value
    LDA [!DP_CurrentMenu] : AND #$00FF : INC !DP_CurrentMenu : STA !DP_ToggleValue

    ; increment past JSL
    INC !DP_CurrentMenu : INC !DP_CurrentMenu

    ; Draw the text
    %item_index_to_vram_index()
    PHX : JSR cm_draw_text : PLX

    ; Set position for ON/OFF
    TXA : CLC : ADC #$002E : TAX

    ; grab the value at that memory address
    LDA [!DP_Address] : CMP !DP_ToggleValue : BEQ .checked

    ; Off
    LDA #$244B : STA !ram_tilemap_buffer+0,X
    LDA #$244D : STA !ram_tilemap_buffer+2,X
    LDA #$244D : STA !ram_tilemap_buffer+4,X
    RTS

  .checked
    ; On
    LDA #$384B : STA !ram_tilemap_buffer+2,X
    LDA #$384C : STA !ram_tilemap_buffer+4,X
    RTS
}

draw_toggle_bit:
{
    ; grab the memory address (long)
    LDA [!DP_CurrentMenu] : INC !DP_CurrentMenu : INC !DP_CurrentMenu : STA !DP_Address
    LDA [!DP_CurrentMenu] : INC !DP_CurrentMenu : STA !DP_Address+2

    ; grab bitmask
    LDA [!DP_CurrentMenu] : INC !DP_CurrentMenu : INC !DP_CurrentMenu : STA !DP_ToggleValue

    ; increment past JSL
    INC !DP_CurrentMenu : INC !DP_CurrentMenu

    ; Draw the text
    %item_index_to_vram_index()
    PHX : JSR cm_draw_text : PLX

    ; Set position for ON/OFF
    TXA : CLC : ADC #$002E : TAX

    ; grab the value at that memory address
    LDA [!DP_Address] : AND !DP_ToggleValue : BNE .checked

    ; Off
    LDA #$244B : STA !ram_tilemap_buffer+0,X
    LDA #$244D : STA !ram_tilemap_buffer+2,X
    LDA #$244D : STA !ram_tilemap_buffer+4,X
    RTS

  .checked
    ; On
    LDA #$384B : STA !ram_tilemap_buffer+2,X
    LDA #$384C : STA !ram_tilemap_buffer+4,X
    RTS
}

draw_toggle_inverted:
{
    ; grab the memory address (long)
    LDA [!DP_CurrentMenu] : INC !DP_CurrentMenu : INC !DP_CurrentMenu : STA !DP_Address
    LDA [!DP_CurrentMenu] : INC !DP_CurrentMenu : STA !DP_Address+2

    ; grab the toggle value
    LDA [!DP_CurrentMenu] : AND #$00FF : INC !DP_CurrentMenu : STA !DP_ToggleValue

    ; increment past JSL
    INC !DP_CurrentMenu : INC !DP_CurrentMenu

    ; Draw the text
    %item_index_to_vram_index()
    PHX : JSR cm_draw_text : PLX

    ; Set position for ON/OFF
    TXA : CLC : ADC #$002E : TAX

    ; grab the value at that memory address
    LDA [!DP_Address] : CMP !DP_ToggleValue : BNE .checked

    ; Off
    LDA #$244B : STA !ram_tilemap_buffer+0,X
    LDA #$244D : STA !ram_tilemap_buffer+2,X
    LDA #$244D : STA !ram_tilemap_buffer+4,X
    RTS

  .checked
    ; On
    LDA #$384B : STA !ram_tilemap_buffer+2,X
    LDA #$384C : STA !ram_tilemap_buffer+4,X
    RTS
}

draw_toggle_bit_inverted:
{
    ; grab the memory address (long)
    LDA [!DP_CurrentMenu] : INC !DP_CurrentMenu : INC !DP_CurrentMenu : STA !DP_Address
    LDA [!DP_CurrentMenu] : INC !DP_CurrentMenu : STA !DP_Address+2

    ; grab bitmask
    LDA [!DP_CurrentMenu] : INC !DP_CurrentMenu : INC !DP_CurrentMenu : STA !DP_ToggleValue

    ; increment past JSL
    INC !DP_CurrentMenu : INC !DP_CurrentMenu

    ; Draw the text
    %item_index_to_vram_index()
    PHX : JSR cm_draw_text : PLX

    ; Set position for ON/OFF
    TXA : CLC : ADC #$002C : TAX

    ; grab the value at that memory address
    LDA [!DP_Address] : AND !DP_ToggleValue : BEQ .checked

    ; Off
    LDA #$244B : STA !ram_tilemap_buffer+2,X
    LDA #$244D : STA !ram_tilemap_buffer+4,X
    LDA #$244D : STA !ram_tilemap_buffer+6,X
    RTS

  .checked
    ; On
    LDA #$384B : STA !ram_tilemap_buffer+4,X
    LDA #$384C : STA !ram_tilemap_buffer+6,X
    RTS
}

draw_numfield:
{
    ; grab the memory address (long)
    LDA [!DP_CurrentMenu] : INC !DP_CurrentMenu : INC !DP_CurrentMenu : STA !DP_Address
    LDA [!DP_CurrentMenu] : INC !DP_CurrentMenu : STA !DP_Address+2

    ; skip bounds and increment values
    INC !DP_CurrentMenu : INC !DP_CurrentMenu : INC !DP_CurrentMenu; : INC !DP_CurrentMenu

    ; increment past JSL
    INC !DP_CurrentMenu : INC !DP_CurrentMenu

    ; Draw the text
    %item_index_to_vram_index()
    PHX : JSR cm_draw_text : PLX

    ; set position for the number
    TXA : CLC : ADC #$002E : TAX

    ; convert value to decimal
    LDA [!DP_Address] : AND #$00FF : JSR cm_hex2dec

    ; Clear out the area
    LDA !MENU_BLANK : STA !ram_tilemap_buffer+0,X
                      STA !ram_tilemap_buffer+2,X
                      STA !ram_tilemap_buffer+4,X

    ; Set palette
    %a8()
    LDA #$24 : ORA !DP_Palette : STA !DP_Palette+1
    LDA #$70 : STA !DP_Palette ; number tiles are 70-79

    ; Draw numbers
    %a16()
    ; ones
    LDA !DP_ThirdDigit : CLC : ADC !DP_Palette : STA !ram_tilemap_buffer+4,X
    ; tens
    LDA !DP_SecondDigit : ORA !DP_FirstDigit : BEQ .done
    LDA !DP_SecondDigit : CLC : ADC !DP_Palette : STA !ram_tilemap_buffer+2,X
    ; hundreds
    LDA !DP_FirstDigit : BEQ .done
    CLC : ADC !DP_Palette : STA !ram_tilemap_buffer,X

  .done
    RTS
}

draw_numfield_sound:
draw_numfield_hex:
{
    ; grab the memory address (long)
    LDA [!DP_CurrentMenu] : INC !DP_CurrentMenu : INC !DP_CurrentMenu : STA !DP_Address
    LDA [!DP_CurrentMenu] : INC !DP_CurrentMenu : STA !DP_Address+2

    ; skip bounds and increment values
    INC !DP_CurrentMenu : INC !DP_CurrentMenu : INC !DP_CurrentMenu; : INC !DP_CurrentMenu

    ; increment past JSL
    INC !DP_CurrentMenu : INC !DP_CurrentMenu

    ; Draw the text
    %item_index_to_vram_index()
    PHX : JSR cm_draw_text : PLX

    ; set position for the number
    TXA : CLC : ADC #$0030 : TAX

    ; load the value
    LDA [!DP_Address] : AND #$00FF : STA !DP_DrawValue

    ; Clear out the area
    LDA !MENU_BLANK : STA !ram_tilemap_buffer+0,X
                      STA !ram_tilemap_buffer+2,X

    ; Draw numbers
    ; (00X0)
    LDA !DP_DrawValue : AND #$00F0 : LSR #3 : TAY
    LDA.w HexMenuGFXTable,Y : STA !ram_tilemap_buffer,X
    ; (000X)
    LDA !DP_DrawValue : AND #$000F : ASL : TAY
    LDA.w HexMenuGFXTable,Y : STA !ram_tilemap_buffer+2,X

    ; overwrite palette bytes
    %a8()
    LDA #$24 : ORA !DP_Palette
    STA !ram_tilemap_buffer+1,X : STA !ram_tilemap_buffer+3,X
    %a16()

    RTS
}

draw_numfield_word:
{
    ; grab the memory address (long)
    LDA [!DP_CurrentMenu] : INC !DP_CurrentMenu : INC !DP_CurrentMenu : STA !DP_Address
    LDA [!DP_CurrentMenu] : INC !DP_CurrentMenu : STA !DP_Address+2

    ; skip bounds and increment values
    INC !DP_CurrentMenu : INC !DP_CurrentMenu : INC !DP_CurrentMenu; : INC !DP_CurrentMenu
    INC !DP_CurrentMenu : INC !DP_CurrentMenu : INC !DP_CurrentMenu; : INC !DP_CurrentMenu

    ; increment past JSL
    INC !DP_CurrentMenu : INC !DP_CurrentMenu

    ; Draw the text
    %item_index_to_vram_index()
    PHX : JSR cm_draw_text : PLX

    ; set position for the number
    TXA : CLC : ADC #$002C : TAX

    ; convert value to decimal
    LDA [!DP_Address] : JSR cm_hex2dec

    ; Clear out the area (black tile)
    LDA !MENU_BLANK : STA !ram_tilemap_buffer+0,X
                      STA !ram_tilemap_buffer+2,X
                      STA !ram_tilemap_buffer+4,X
                      STA !ram_tilemap_buffer+6,X

    ; Set palette
    %a8()
    LDA #$24 : ORA !DP_Palette : STA !DP_Palette+1
    LDA #$70 : STA !DP_Palette ; number tiles are 70-79

    ; Draw numbers
    %a16()
    ; ones
    LDA !DP_ThirdDigit : CLC : ADC !DP_Palette : STA !ram_tilemap_buffer+6,X
    ; tens
    LDA !DP_SecondDigit : ORA !DP_FirstDigit
    ORA !DP_Temp : BEQ .done
    LDA !DP_SecondDigit : CLC : ADC !DP_Palette : STA !ram_tilemap_buffer+4,X
    ; hundreds
    LDA !DP_FirstDigit : ORA !DP_Temp : BEQ .done
    LDA !DP_FirstDigit : CLC : ADC !DP_Palette : STA !ram_tilemap_buffer+2,X
    ; thousands
    LDA !DP_Temp : BEQ .done
    CLC : ADC !DP_Palette : STA !ram_tilemap_buffer,X

  .done
    RTS
}

draw_choice:
{
    ; grab the memory address (long)
    LDA [!DP_CurrentMenu] : INC !DP_CurrentMenu : INC !DP_CurrentMenu : STA !DP_Address
    LDA [!DP_CurrentMenu] : INC !DP_CurrentMenu : STA !DP_Address+2

    ; skip the JSL target
    INC !DP_CurrentMenu : INC !DP_CurrentMenu

    ; Draw the text first
    %item_index_to_vram_index()
    PHX : JSR cm_draw_text : PLX

    ; set position for choice
    TXA : CLC : ADC #$001E : TAX

    ; grab the value at that memory address
    LDA [!DP_Address] : TAY

    ; find the correct text that should be drawn (the selected choice)
    ; skipping the first text that we already drew
    INY #2 ; uh, ..

  .loop_choices
    DEY : BEQ .found

  .loop_text
    LDA [!DP_CurrentMenu] : %a16() : INC !DP_CurrentMenu : %a8()
    CMP #$FF : BEQ .loop_choices
    BRA .loop_text

  .found
    %a16()
    JSR cm_draw_text
    RTS
}

draw_controller_input:
{
    ; grab the memory address (long)
    LDA [!DP_CurrentMenu] : INC !DP_CurrentMenu : INC !DP_CurrentMenu : STA !DP_Address
    STA !ram_cm_ctrl_assign
    LDA [!DP_CurrentMenu] : INC !DP_CurrentMenu : STA !DP_Address+2

    ; skip JSL target + argument
    INC !DP_CurrentMenu : INC !DP_CurrentMenu : INC !DP_CurrentMenu : INC !DP_CurrentMenu

    ; Draw the text
    %item_index_to_vram_index()
    PHX : JSR cm_draw_text : PLX

    ; set position for the input
    TXA : CLC : ADC #$0020 : TAX

    ; check if anything to draw
    LDA (!DP_Address) : AND #$E0F0 : BEQ .unbound

    ; determine which input to draw, using Y to refresh A
    TAY : AND !CTRL_A : BEQ + : LDY #$0000 : BRA .draw
+   TYA : AND !CTRL_B : BEQ + : LDY #$0002 : BRA .draw
+   TYA : AND !CTRL_X : BEQ + : LDY #$0004 : BRA .draw
+   TYA : AND !CTRL_Y : BEQ + : LDY #$0006 : BRA .draw
+   TYA : AND !CTRL_L : BEQ + : LDY #$0008 : BRA .draw
+   TYA : AND !CTRL_R : BEQ + : LDY #$000A : BRA .draw
+   TYA : AND !CTRL_SELECT : BEQ .unbound : LDY #$000C

  .draw
    LDA.w CtrlMenuGFXTable,Y : STA !ram_tilemap_buffer,X
    RTS

  .unbound
    LDA !MENU_BLANK : STA !ram_tilemap_buffer,X
    RTS

CtrlMenuGFXTable:
    ;    A      B      X      Y      L      R    Select
    ;  $0080  $8000  $0040  $4000  $0020  $0010  $2000
    dw $288F, $2887, $288E, $2886, $288D, $288C, $2885
}

draw_jsl:
draw_submenu:
{
    ; skip JSL address
    INC !DP_CurrentMenu : INC !DP_CurrentMenu

    ; skip argument
    INC !DP_CurrentMenu : INC !DP_CurrentMenu

    ; draw text normally
    %item_index_to_vram_index()
    JSR cm_draw_text
    RTS
}

cm_draw_text:
; X = pointer to tilemap area (STA !ram_tilemap_buffer,X)
    %a8()
    LDY #$0000
    ; terminator
    LDA [!DP_CurrentMenu],Y : INY : CMP #$FF : BEQ .end
    ; ORA with palette info
    ORA !DP_Palette : STA !DP_Palette

  .loop
    LDA [!DP_CurrentMenu],Y : CMP #$FF : BEQ .end       ; terminator
    STA !ram_tilemap_buffer,X : INX                     ; tile
    LDA !DP_Palette : STA !ram_tilemap_buffer,X : INX   ; palette
    INY : BRA .loop

  .end
    %a16()
    RTS


; ---------
; Logic
; ---------

cm_loop:
{
    %ai16()
    JSL wait_for_lag_frame_long  ; Wait for lag frame
    JSL $808F0C ; Music queue
    JSL $8289EF ; Sound fx queue

    LDA !ram_cm_leave : BEQ .checkInputs
    LDA #$0000 : STA !ram_mem_editor_active
    RTS ; Exit menu loop

  .checkInputs
    JSR cm_get_inputs : STA !ram_cm_controller : BEQ cm_loop

;    BIT #$0040 : BNE .pressedX
    BIT !CTRL_A : BEQ + : JMP .pressedA ; more wiggle room with branch limits...
+   BIT !CTRL_B : BEQ + : JMP .pressedB
+   BIT !CTRL_Y : BNE .pressedY
    BIT !CTRL_SELECT : BNE .pressedSelect
    BIT !IH_INPUT_START : BNE .pressedStart
    BIT !IH_INPUT_UP : BNE .pressedUp
    BIT !IH_INPUT_DOWN : BNE .pressedDown
    BIT !IH_INPUT_RIGHT : BNE .pressedRight
    BIT !IH_INPUT_LEFT : BNE .pressedLeft
    BIT !CTRL_L : BNE .pressedL
    BIT !CTRL_R : BNE .pressedR
    JMP cm_loop

  .pressedB
    JSL cm_previous_menu
    BRA .redraw

  .pressedDown
    LDA #$0002
    JSR cm_move
    BRA .redraw

  .pressedUp
    LDA #$FFFE
    JSR cm_move
    BRA .redraw

  .pressedL
    ; jump to top menu item
    LDA !ram_cm_stack_index : TAX
    LDA #$0000 : STA !ram_cm_cursor_stack,X
    %sfxmove()
    BRA .redraw

  .pressedR
    ; jump to bottom menu item
    LDA !ram_cm_stack_index : TAX
    LDA !ram_cm_cursor_max : DEC #2 : STA !ram_cm_cursor_stack,X
    %sfxmove()
    BRA .redraw

  .pressedA
;  .pressedX
  .pressedY
  .pressedLeft
  .pressedRight
    JSR cm_execute
    BRA .redraw

  .pressedStart
  .pressedSelect
    LDA #$0001 : STA !ram_cm_leave
    JMP cm_loop

  .redraw
    JSL cm_draw
    JMP cm_loop
}

cm_previous_menu:
{
    JSL cm_go_back
    JSL cm_calculate_max
    RTL
}

cm_go_back:
{
    ; disable memory editor
    LDA #$0000 : STA !ram_mem_editor_active

    ; make sure next time we go to a submenu, we start on the first line.
    LDA !ram_cm_stack_index : TAX
    LDA #$0000 : STA !ram_cm_cursor_stack,X

    ; make sure we dont set a negative number
    LDA !ram_cm_stack_index : DEC #2 : BPL .done

    ; leave menu
    LDA #$0001 : STA !ram_cm_leave

    LDA #$0000
  .done
    STA !ram_cm_stack_index
    LDA !ram_cm_stack_index : BNE .end
    ; Reset submenu bank when back at main menu
    LDA.w #MainMenu>>16 : STA !ram_cm_menu_bank

  .end
    %sfxgoback()
    RTL
}

cm_calculate_max:
{
    LDA !ram_cm_stack_index : TAX
    LDA !ram_cm_menu_stack,X : STA !DP_MenuIndices
    LDA !ram_cm_menu_bank : STA !DP_MenuIndices+2

    LDX #$0000
  .loop
    LDA [!DP_MenuIndices] : BEQ .done
    INC !DP_MenuIndices : INC !DP_MenuIndices
    INX #2 ; count menu items in X
    BRA .loop

  .done
    ; store total menu items +2
    TXA : STA !ram_cm_cursor_max
    RTL
}

cm_get_inputs:
{
    ; Make sure we don't read joysticks twice in the same frame
    LDA !FRAME_COUNTER : CMP !ram_cm_input_counter : PHP : STA !ram_cm_input_counter : PLP : BNE +

    JSL $809459 ; Read controller input

+   LDA !CONTROLLER_PRI_NEW : BEQ .check_holding

    ; Initial delay of $0E frames
    LDA #$000E : STA !ram_cm_input_timer

    ; Return the new input
    LDA !CONTROLLER_PRI_NEW
    RTS

  .check_holding
    ; Check if we're holding the dpad
    LDA !CONTROLLER_PRI : AND #$0F00 : BEQ .noinput

    ; Decrement delay timer and check if it's zero
    LDA !ram_cm_input_timer : DEC : STA !ram_cm_input_timer : BNE .noinput

    ; Set new delay to two frames and return the input we're holding
    LDA #$0002 : STA !ram_cm_input_timer
    LDA !CONTROLLER_PRI : AND #$4F00 : ORA !IH_INPUT_HELD
    RTS

  .noinput
    LDA #$0000
    RTS
}

cm_move:
{
    STA !DP_Temp
    LDA !ram_cm_stack_index : TAX
    LDA !DP_Temp : CLC : ADC !ram_cm_cursor_stack,X : BPL .positive
    LDA !ram_cm_cursor_max : DEC #2 : BRA .inBounds

  .positive
    CMP !ram_cm_cursor_max : BNE .inBounds
    LDA #$0000

  .inBounds
    STA !ram_cm_cursor_stack,X : TAY

    ; check for blank menu line ($FFFF)
    LDA [!DP_MenuIndices],Y : CMP #$FFFF : BNE .end

    ; repeat move to skip blank line
    LDA !DP_Temp : BRA cm_move

  .end
    %sfxmove()
    RTS
}

action_mainmenu:
{
    ; Set bank of new menu
    LDA !ram_cm_cursor_stack : TAX
    LDA.l MainMenuBanks,X : STA !ram_cm_menu_bank
    STA !DP_MenuIndices+2 : STA !DP_CurrentMenu+2

    ; fallthrough to action_submenu
}

action_submenu:
{
    ; Increment stack pointer by 2, then store current menu from Y
    LDA !ram_cm_stack_index : INC #2 : STA !ram_cm_stack_index : TAX
    TYA : STA !ram_cm_menu_stack,X

    LDA #$0000 : STA !ram_cm_cursor_stack,X

    %sfxmove()
    JSL cm_calculate_max
    JML cm_draw
}

stop_all_sounds:
{
; If sounds are not enabled, the game won't clear the sounds
    LDA !DISABLE_SOUNDS : PHA
    STZ !DISABLE_SOUNDS
    JSL $82BE17  ; Cancel sound effects
    PLA : STA !DISABLE_SOUNDS

    ; Makes the game check Samus' health again, to see if we need annoying sound
    STZ !SAMUS_HEALTH_WARNING
    RTL
}


; --------
; Execute
; --------

cm_execute:
{
    LDA !ram_cm_stack_index : TAX
    LDA !ram_cm_menu_stack,X : STA !DP_CurrentMenu
    LDA !ram_cm_menu_bank : STA !DP_CurrentMenu+2
    LDA !ram_cm_cursor_stack,X : TAY
    LDA [!DP_CurrentMenu],Y : STA !DP_CurrentMenu

    ; Increment past the action index
    LDA [!DP_CurrentMenu] : INC !DP_CurrentMenu : INC !DP_CurrentMenu : TAX

    ; Safety net incase blank line selected
    CPX #$FFFF : BEQ +

    ; Execute action
    JSR (cm_execute_action_table,X)
+   RTS
}

cm_execute_action_table:
    dw execute_toggle
    dw execute_toggle_bit
    dw execute_toggle ; inverted
    dw execute_toggle_bit ; inverted
    dw execute_numfield
    dw execute_numfield_hex
    dw execute_numfield_word
    dw execute_choice
    dw execute_controller_input
    dw execute_jsl
    dw execute_submenu
    dw execute_numfield_sound

execute_toggle:
{
    ; Grab address (long)
    LDA [!DP_CurrentMenu] : INC !DP_CurrentMenu : INC !DP_CurrentMenu : STA !DP_Address
    LDA [!DP_CurrentMenu] : INC !DP_CurrentMenu : STA !DP_Address+2

    ; Grab toggle value
    LDA [!DP_CurrentMenu] : INC !DP_CurrentMenu : AND #$00FF : STA !DP_ToggleValue

    ; Grab JSL target
    LDA [!DP_CurrentMenu] : INC !DP_CurrentMenu : INC !DP_CurrentMenu : STA !DP_JSLTarget

    %a8()
    LDA [!DP_Address] : CMP !DP_ToggleValue : BEQ .toggleOff
    ; toggle on
    LDA !DP_ToggleValue : STA [!DP_Address]
    BRA .jsl

  .toggleOff
    LDA #$00 : STA [!DP_Address]

  .jsl
    %a16()
    ; skip if JSL target is zero
    LDA !DP_JSLTarget : BEQ .end

    ; Set return address for indirect JSL
    LDA !ram_cm_menu_bank : STA !DP_JSLTarget+2
    PHK : PEA .end-1

    ; addr in A
    LDA [!DP_Address] : LDX #$0000
    JML.w [!DP_JSLTarget]

  .end
    %ai16()
    %sfxtoggle()
    RTS
}

execute_toggle_bit:
{
    ; Load the address
    LDA [!DP_CurrentMenu] : INC !DP_CurrentMenu : INC !DP_CurrentMenu : STA !DP_Address
    LDA [!DP_CurrentMenu] : INC !DP_CurrentMenu : STA !DP_Address+2

    ; Load which bit(s) to toggle
    LDA [!DP_CurrentMenu] : INC !DP_CurrentMenu : INC !DP_CurrentMenu : STA !DP_ToggleValue

    ; Load JSL target
    LDA [!DP_CurrentMenu] : INC !DP_CurrentMenu : INC !DP_CurrentMenu : STA !DP_JSLTarget

    ; Toggle the bit
    LDA [!DP_Address] : EOR !DP_ToggleValue : STA [!DP_Address]

    ; skip if JSL target is zero
    LDA !DP_JSLTarget : BEQ .end

    ; Set return address for indirect JSL
    LDA !ram_cm_menu_bank : STA !DP_JSLTarget+2
    PHK : PEA .end-1

    ; addr in A
    LDA [!DP_Address] : LDX #$0000
    JML.w [!DP_JSLTarget]

 .end
    %ai16()
    %sfxtoggle()
    RTS
}

execute_numfield:
execute_numfield_hex:
{
    ; grab the memory address (long)
    LDA [!DP_CurrentMenu] : INC !DP_CurrentMenu : INC !DP_CurrentMenu : STA !DP_Address
    LDA [!DP_CurrentMenu] : INC !DP_CurrentMenu : STA !DP_Address+2

    ; grab minimum (!DP_Minimum) and maximum (!DP_Maximum) values
    LDA [!DP_CurrentMenu] : INC !DP_CurrentMenu : AND #$00FF : STA !DP_Minimum
    LDA [!DP_CurrentMenu] : INC !DP_CurrentMenu : AND #$00FF : INC : STA !DP_Maximum ; INC for convenience

    ; grab normal increment
    LDA [!DP_CurrentMenu] : INC !DP_CurrentMenu : AND #$00FF : STA !DP_Increment

    ; check if fast scroll button (Y) is held
    LDA !CONTROLLER_PRI : AND !CTRL_Y : BEQ .load_jsl_target
    ; 4x scroll speed if held
    LDA !DP_Increment : ASL #2 : STA !DP_Increment

; "hold dpad to fast-scroll" is disabled here
;    ; check for held inputs
;    LDA !ram_cm_controller : BIT !IH_INPUT_HELD : BNE .input_held
;    ; grab normal increment and skip past both
;    LDA [!DP_CurrentMenu] : INC !DP_CurrentMenu : INC !DP_CurrentMenu; : AND #$00FF : STA !DP_Increment
;    BRA .load_jsl_target

;  .input_held
;    ; grab faster increment and skip past both
;    INC !DP_CurrentMenu : LDA [!DP_CurrentMenu] : INC !DP_CurrentMenu : AND #$00FF : STA !DP_Increment

  .load_jsl_target
    LDA [!DP_CurrentMenu] : INC !DP_CurrentMenu : INC !DP_CurrentMenu : STA !DP_JSLTarget

    ; determine dpad direction
    LDA !ram_cm_controller : BIT #$0200 : BNE .pressed_left
    ; pressed right, inc
    LDA [!DP_Address] : CLC : ADC !DP_Increment
    CMP !DP_Maximum : BCS .set_to_min
    %a8() : STA [!DP_Address] : BRA .jsl

  .pressed_left ; dec
    LDA [!DP_Address] : SEC : SBC !DP_Increment : BMI .set_to_max
    CMP !DP_Maximum : BCS .set_to_max
    %a8() : STA [!DP_Address] : BRA .jsl

  .set_to_min
    LDA !DP_Minimum : %a8() : STA [!DP_Address] : BRA .jsl

  .set_to_max
    LDA !DP_Maximum : DEC : %a8() : STA [!DP_Address]

  .jsl
    %a16()
    ; skip if JSL target is zero
    LDA !DP_JSLTarget : BEQ .end

    ; Set return address for indirect JSL
    LDA !ram_cm_menu_bank : STA !DP_JSLTarget+2
    PHK : PEA .end-1

    ; addr in A
    LDA [!DP_Address] : LDX #$0000
    JML.w [!DP_JSLTarget]

  .end
    %ai16()
    %sfxnumber()
    RTS
}

execute_numfield_word:
{
    ; grab the memory address (long)
    LDA [!DP_CurrentMenu] : INC !DP_CurrentMenu : INC !DP_CurrentMenu : STA !DP_Address
    LDA [!DP_CurrentMenu] : INC !DP_CurrentMenu : STA !DP_Address+2

    ; grab minimum (!DP_Minimum) and maximum (!DP_Maximum) values
    LDA [!DP_CurrentMenu] : INC !DP_CurrentMenu : INC !DP_CurrentMenu : STA !DP_Minimum
    LDA [!DP_CurrentMenu] : INC !DP_CurrentMenu : INC !DP_CurrentMenu : INC : STA !DP_Maximum ; INC for convenience

    ; grab normal increment
    LDA [!DP_CurrentMenu] : INC !DP_CurrentMenu : INC !DP_CurrentMenu : STA !DP_Increment

    ; check if fast scroll button (Y) is held
    LDA !CONTROLLER_PRI : AND !CTRL_Y : BEQ +
    ; 4x scroll speed if held
    LDA !DP_Increment : ASL #2 : STA !DP_Increment

; "hold dpad to fast-scroll" is disabled here
;    ; check for held inputs
;    LDA !ram_cm_controller : BIT !IH_INPUT_HELD : BNE .input_held
;    ; grab normal increment and skip past both
;    LDA [!DP_CurrentMenu] : INC !DP_CurrentMenu : INC !DP_CurrentMenu; : AND #$00FF : STA !DP_Increment
;    BRA .load_jsl_target

;  .input_held
;    ; grab faster increment and skip past both
;    INC !DP_CurrentMenu : LDA [!DP_CurrentMenu] : INC !DP_CurrentMenu : AND #$00FF : STA !DP_Increment

  .load_jsl_target
+   LDA [!DP_CurrentMenu] : INC !DP_CurrentMenu : INC !DP_CurrentMenu : STA !DP_JSLTarget

    ; determine dpad direction
    LDA !ram_cm_controller : BIT #$0200 : BNE .pressed_left
    ; pressed right, inc
    LDA [!DP_Address] : CLC : ADC !DP_Increment
    CMP !DP_Maximum : BCS .set_to_min
    STA [!DP_Address] : BRA .jsl

  .pressed_left ; dec
    LDA [!DP_Address] : SEC : SBC !DP_Increment
    CMP !DP_Minimum : BMI .set_to_max
    CMP !DP_Maximum : BCS .set_to_max
    STA [!DP_Address] : BRA .jsl

  .set_to_min
    LDA !DP_Minimum : STA [!DP_Address] : CLC : BRA .jsl

  .set_to_max
    LDA !DP_Maximum : DEC : STA [!DP_Address]

  .jsl
    ; skip if JSL target is zero
    LDA !DP_JSLTarget : BEQ .end

    ; Set return address for indirect JSL
    LDA !ram_cm_menu_bank : STA !DP_JSLTarget+2
    PHK : PEA .end-1

    ; addr in A
    LDA [!DP_Address] : LDX #$0000
    JML.w [!DP_JSLTarget]

  .end
    %ai16()
    %sfxnumber()
    RTS
}

execute_choice:
{
    ; grab the memory address (long)
    LDA [!DP_CurrentMenu] : INC !DP_CurrentMenu : INC !DP_CurrentMenu : STA !DP_Address
    LDA [!DP_CurrentMenu] : INC !DP_CurrentMenu : STA !DP_Address+2

    LDA [!DP_CurrentMenu] : INC !DP_CurrentMenu : INC !DP_CurrentMenu : STA !DP_JSLTarget

    ; we either increment or decrement
    LDA !ram_cm_controller : BIT #$0200 : BNE .pressed_left
    ; pressed right
    LDA [!DP_Address] : INC : BRA .bounds_check

  .pressed_left
    LDA [!DP_Address] : DEC

  .bounds_check
    TAX         ; X = new value
    LDY #$0000  ; Y will be set to max
    %a8()

  .loop_choices
    LDA [!DP_CurrentMenu] : %a16() : INC !DP_CurrentMenu : %a8() : CMP #$FF : BEQ .loop_done

  .loop_text
    LDA [!DP_CurrentMenu] : %a16() : INC !DP_CurrentMenu : %a8()
    CMP #$FF : BNE .loop_text
    INY : BRA .loop_choices

  .loop_done
    ; Y = maximum + 2
    ; for convenience so we can use BCS. We do one more DEC in `.set_to_max`
    ; below, so we get the actual max.
    DEY

    %a16()
    ; X = new value (might be out of bounds)
    TXA : BMI .set_to_max
    TYA : STA !DP_Maximum
    TXA : CMP !DP_Maximum : BCS .set_to_zero

    BRA .store

  .set_to_zero
    LDA #$0000 : BRA .store

  .set_to_max
    TYA : DEC

  .store
    STA [!DP_Address]

    ; skip if JSL target is zero
    LDA !DP_JSLTarget : BEQ .end

    ; Set return address for indirect JSL
    LDA !ram_cm_menu_bank : STA !DP_JSLTarget+2
    PHK : PEA .end-1

    ; addr in A
    LDA [!DP_Address] : LDX #$0000
    JML.w [!DP_JSLTarget]

  .end
    %ai16()
    %sfxtoggle()
    RTS
}

execute_controller_input:
{
    ; <, > and X should do nothing here
    ; also ignore input held flag
    LDA !ram_cm_controller : BIT #$0341 : BNE .end

    ; store long address as short address for now
    LDA [!DP_CurrentMenu] : INC !DP_CurrentMenu : INC !DP_CurrentMenu : INC !DP_CurrentMenu
    STA !ram_cm_ctrl_assign

    ; !DP_JSLTarget = JSL target
    LDA [!DP_CurrentMenu] : INC !DP_CurrentMenu : INC !DP_CurrentMenu : STA !DP_JSLTarget

    ; Use bank of action_submenu
    ; instead of new menu's bank
    LDA.l #action_submenu>>16 : STA !DP_JSLTarget+2

    ; Set return address for indirect JSL
    PHK : PEA .end-1

    ; Y = Argument
    LDA [!DP_CurrentMenu] : TAY

    LDX #$0000
    JML.w [!DP_JSLTarget]

  .end
    %ai16()
    RTS
}

execute_jsl:
{
    ; <, > and X should do nothing here
    ; also ignore input held flag
    LDA !ram_cm_controller : BIT #$0341 : BNE .end

    ; !DP_JSLTarget = JSL target
    LDA [!DP_CurrentMenu] : INC !DP_CurrentMenu : INC !DP_CurrentMenu : STA !DP_JSLTarget

    ; Set return address for indirect JSL
    LDA !ram_cm_menu_bank : STA !DP_JSLTarget+2
    PHK : PEA .end-1

    ; Y = Argument
    LDA [!DP_CurrentMenu] : TAY

    LDX #$0000
    JML.w [!DP_JSLTarget]

  .end
    %ai16()
    RTS
}

execute_submenu:
{
    ; <, > and X should do nothing here
    ; also ignore input held flag
    LDA !ram_cm_controller : BIT #$0341 : BNE .end

    ; !DP_JSLTarget = JSL target
    LDA [!DP_CurrentMenu] : INC !DP_CurrentMenu : INC !DP_CurrentMenu : STA !DP_JSLTarget

    ; Set bank of action_submenu
    ; instead of the new menu's bank
    LDA.w #action_submenu>>16 : STA !DP_JSLTarget+2

    ; Set return address for indirect JSL
    PHK : PEA .end-1

    ; Y = Argument
    LDA [!DP_CurrentMenu] : TAY

    LDX #$0000
    JML.w [!DP_JSLTarget]

  .end
    %ai16()
    RTS
}

execute_numfield_sound:
{
    ; grab the memory address (long)
    LDA [!DP_CurrentMenu] : INC !DP_CurrentMenu : INC !DP_CurrentMenu : STA !DP_Address
    LDA [!DP_CurrentMenu] : INC !DP_CurrentMenu : STA !DP_Address+2

    ; grab minimum (!DP_Minimum) and maximum (!DP_Maximum) values
    LDA [!DP_CurrentMenu] : INC !DP_CurrentMenu : AND #$00FF : STA !DP_Minimum
    LDA [!DP_CurrentMenu] : INC !DP_CurrentMenu : AND #$00FF : INC : STA !DP_Maximum ; INC for convenience

    ; grab normal increment
    LDA [!DP_CurrentMenu] : INC !DP_CurrentMenu : AND #$00FF : STA !DP_Increment

    ; check if fast scroll button is held
    LDA !CONTROLLER_PRI : AND !CTRL_Y : BEQ .load_jsl_target
    ; 4x scroll speed if held
    LDA !DP_Increment : ASL #2 : STA !DP_Increment

  .load_jsl_target
    LDA [!DP_CurrentMenu] : INC !DP_CurrentMenu : INC !DP_CurrentMenu : STA !DP_JSLTarget

    ; check for Y pressed
    LDA !ram_cm_controller : BIT #$4000 : BNE .jsl

    ; determine dpad direction
    LDA !ram_cm_controller : BIT #$0200 : BNE .pressed_left
    ; pressed right, inc
    LDA [!DP_Address] : CLC : ADC !DP_Increment
    CMP !DP_Maximum : BCS .set_to_min
    %a8() : STA [!DP_Address] : BRA .jsl

  .pressed_left ; dec
    LDA [!DP_Address] : SEC : SBC !DP_Increment
    CMP !DP_Minimum : BMI .set_to_max
    CMP !DP_Maximum : BCS .set_to_max
    %a8() : STA [!DP_Address] : BRA .jsl

  .set_to_min
    LDA !DP_Minimum : STA [!DP_Address] : BRA .end

  .set_to_max
    LDA !DP_Maximum : DEC : STA [!DP_Address] : BRA .end

  .jsl
    %ai16()
    ; skip if JSL target is zero
    LDA !DP_JSLTarget : BEQ .end

    ; Set return address for indirect JSL
    LDA !ram_cm_menu_bank : STA !DP_JSLTarget+2
    PHK : PEA .end-1

    ; addr in A
    LDA [!DP_Address] : LDX #$0000
    JML.w [!DP_JSLTarget]

  .end
    %ai16()
    RTS
}


; -------
; Numbers
; -------

cm_hex2dec:
{
    ; store 16-bit dividend
    STA $4204

    %a8()
    ; divide by 100
    LDA #$64 : STA $4206

    %a16()
    PEA $0000 : PLA ; wait for math

    ; store result and use remainder as new dividend
    LDA $4214 : STA !DP_Temp
    LDA $4216 : STA $4204

    %a8()
    ; divide by 10
    LDA #$0A : STA $4206

    %a16()
    PEA $0000 : PLA ; wait for math

    ; store result and remainder, divide the rest
    LDA $4214 : STA !DP_SecondDigit
    LDA $4216 : STA !DP_ThirdDigit
    LDA !DP_Temp : STA $4204

    %a8()
    ; divide by 10
    LDA #$0A : STA $4206

    %a16()
    PEA $0000 : PLA ; wait for math

    ; store result and remainder
    LDA $4214 : STA !DP_Temp
    LDA $4216 : STA !DP_FirstDigit

    RTS
}

cm_draw2_hex:
{
    PHP : %a16()
    PHB : PHK : PLB
    ; (00X0)
    LDA !DP_DrawValue : AND #$00F0 : LSR #3 : TAY
    LDA.w HexMenuGFXTable,Y : STA !ram_tilemap_buffer,X
    ; (000X)
    LDA !DP_DrawValue : AND #$000F : ASL : TAY
    LDA.w HexMenuGFXTable,Y : STA !ram_tilemap_buffer+2,X
    PLB : PLP
    RTL
}

cm_draw3:
; Converts a hex number into a three digit decimal number
; expects value to be drawn in !DP_DrawValue
; expects tilemap pointer in X
{
    PHB
    LDA !DP_DrawValue : STA $4204
    %a8()
    LDA #$0A : STA $4206 ; divide by 10
    PEA $0000 : PLA : PLA ; wait for CPU math
    %a16()
    LDA $4214 : STA !DP_SecondDigit

    ; Ones digit
    LDA $4216 : ASL : TAY
    LDA.w DecMenuGFXTable,Y : STA !ram_tilemap_buffer+4,X

    LDA !DP_SecondDigit : BEQ .blanktens
    STA $4204
    %a8()
    LDA #$0A : STA $4206 ; divide by 10
    %a16()
    PEA $0000 : PLA
    LDA $4214 : STA !DP_ThirdDigit

    ; Tens digit
    LDA $4216 : ASL : TAY
    LDA.w DecMenuGFXTable,Y : STA !ram_tilemap_buffer+2,X

    ; Hundreds digit
    LDA !DP_ThirdDigit : BEQ .blankhundreds : ASL : TAY
    LDA.w DecMenuGFXTable,Y : STA !ram_tilemap_buffer,X

  .done
    PLB
    INX #6
    RTL

  .blanktens
    LDA !MENU_BLANK
    STA !ram_tilemap_buffer,X : STA !ram_tilemap_buffer+2,X
    BRA .done

  .blankhundreds
    LDA !MENU_BLANK : STA !ram_tilemap_buffer,X
    BRA .done
}

cm_draw4_hex:
{
    PHP : %a16()
    PHB : PHK : PLB
    ; (X000)
    LDA !DP_DrawValue : AND #$F000 : XBA : LSR #3 : TAY
    LDA.w HexMenuGFXTable,Y : STA !ram_tilemap_buffer,X
    ; (0X00)
    LDA !DP_DrawValue : AND #$0F00 : XBA : ASL : TAY
    LDA.w HexMenuGFXTable,Y : STA !ram_tilemap_buffer+2,X
    ; (00X0)
    LDA !DP_DrawValue : AND #$00F0 : LSR #3 : TAY
    LDA.w HexMenuGFXTable,Y : STA !ram_tilemap_buffer+4,X
    ; (000X)
    LDA !DP_DrawValue : AND #$000F : ASL : TAY
    LDA.w HexMenuGFXTable,Y : STA !ram_tilemap_buffer+6,X
    PLB : PLP
    RTL
}

cm_draw5:
; Converts a hex number into a five digit decimal number
; expects value to be drawn in !DP_DrawValue
; expects tilemap pointer in X
{
    PHB
    LDA !DP_DrawValue : STA $4204
    %a8()
    LDA #$0A : STA $4206 ; divide by 10
    PEA $0000 : PLA : PLA ; wait for CPU math
    %a16()
    LDA $4214 : STA !DP_SecondDigit

    ; Ones digit
    LDA $4216 : ASL : TAY
    LDA.w DecMenuGFXTable,Y : STA !ram_tilemap_buffer+8,X

    LDA !DP_SecondDigit : BNE +
    BRL .blanktens
+   STA $4204
    %a8()
    LDA #$0A : STA $4206 ; divide by 10
    %a16()
    PEA $0000 : PLA
    LDA $4214 : STA !DP_ThirdDigit

    ; Tens digit
    LDA $4216 : ASL : TAY
    LDA.w DecMenuGFXTable,Y : STA !ram_tilemap_buffer+6,X

    LDA !DP_ThirdDigit : BNE +
    BRL .blankhundreds
+   STA $4204
    %a8()
    LDA #$0A : STA $4206 ; divide by 10
    %a16()
    PEA $0000 : PLA
    LDA $4214 : STA !DP_DrawValue

    ; Hundreds digit
    LDA $4216 : ASL : TAY
    LDA.w DecMenuGFXTable,Y : STA !ram_tilemap_buffer+4,X

    LDA !DP_DrawValue : BEQ .blankthousands
    STA $4204
    %a8()
    LDA #$0A : STA $4206 ; divide by 10
    %a16()
    PEA $0000 : PLA
    LDA $4214 : STA !DP_Temp

    ; Thousands digit
    LDA $4216 : ASL : TAY
    LDA.w DecMenuGFXTable,Y : STA !ram_tilemap_buffer+2,X

    ; Ten thousands digit
    LDA !DP_Temp : BEQ .blanktenthousands
    ASL : TAY
    LDA.w DecMenuGFXTable,Y : STA !ram_tilemap_buffer,X

  .done
    PLB
    INX #10
    RTL

  .blanktens
    LDA !MENU_BLANK
    STA !ram_tilemap_buffer,X : STA !ram_tilemap_buffer+2,X
    STA !ram_tilemap_buffer+4,X : STA !ram_tilemap_buffer+6,X
    BRA .done

  .blankhundreds
    LDA !MENU_BLANK
    STA !ram_tilemap_buffer,X : STA !ram_tilemap_buffer+2,X : STA !ram_tilemap_buffer+4,X
    BRA .done

  .blankthousands
    LDA !MENU_BLANK
    STA !ram_tilemap_buffer,X : STA !ram_tilemap_buffer+2,X
    BRA .done

  .blanktenthousands
    LDA !MENU_BLANK : STA !ram_tilemap_buffer,X
    BRA .done
}

SetupEquipmentMenus:
; Setup initial values for dummy equipment addresses
{
    LDA !SAMUS_ITEMS_COLLECTED : BIT #$0001 : BEQ .noVaria
    LDA !SAMUS_ITEMS_EQUIPPED : BIT #$0001 : BNE .equipVaria
    ; unequip Varia
    LDA #$0002 : STA !ram_cm_varia : BRA +
  .equipVaria
    LDA #$0001 : STA !ram_cm_varia : BRA +
  .noVaria
    LDA #$0000 : STA !ram_cm_varia

+   LDA !SAMUS_ITEMS_COLLECTED : BIT #$0020 : BEQ .noGravity
    LDA !SAMUS_ITEMS_EQUIPPED : BIT #$0020 : BNE .equipGravity
    ; unequip Gravity
    LDA #$0002 : STA !ram_cm_gravity : BRA +
  .equipGravity
    LDA #$0001 : STA !ram_cm_gravity : BRA +
  .noGravity
    LDA #$0000 : STA !ram_cm_gravity

+   LDA !SAMUS_ITEMS_COLLECTED : BIT #$0004 : BEQ .noMorph
    LDA !SAMUS_ITEMS_EQUIPPED : BIT #$0004 : BNE .equipMorph
    ; unequip Morph
    LDA #$0002 : STA !ram_cm_morph : BRA +
  .equipMorph
    LDA #$0001 : STA !ram_cm_morph : BRA +
  .noMorph
    LDA #$0000 : STA !ram_cm_morph

+   LDA !SAMUS_ITEMS_COLLECTED : BIT #$1000 : BEQ .noBombs
    LDA !SAMUS_ITEMS_EQUIPPED : BIT #$1000 : BNE .equipBombs
    ; unequip Bombs
    LDA #$0002 : STA !ram_cm_bombs : BRA +
  .equipBombs
    LDA #$0001 : STA !ram_cm_bombs : BRA +
  .noBombs
    LDA #$0000 : STA !ram_cm_bombs

+   LDA !SAMUS_ITEMS_COLLECTED : BIT #$0002 : BEQ .noSpring
    LDA !SAMUS_ITEMS_EQUIPPED : BIT #$0002 : BNE .equipSpring
    ; unequip Spring
    LDA #$0002 : STA !ram_cm_spring : BRA +
  .equipSpring
    LDA #$0001 : STA !ram_cm_spring : BRA +
  .noSpring
    LDA #$0000 : STA !ram_cm_spring

+   LDA !SAMUS_ITEMS_COLLECTED : BIT #$0008 : BEQ .noScrew
    LDA !SAMUS_ITEMS_EQUIPPED : BIT #$0008 : BNE .equipScrew
    ; unequip Screw
    LDA #$0002 : STA !ram_cm_screw : BRA +
  .equipScrew
    LDA #$0001 : STA !ram_cm_screw : BRA +
  .noScrew
    LDA #$0000 : STA !ram_cm_screw

+   LDA !SAMUS_ITEMS_COLLECTED : BIT #$0100 : BEQ .noHiJump
    LDA !SAMUS_ITEMS_EQUIPPED : BIT #$0100 : BNE .equipHiJump
    ; unequip HiJump
    LDA #$0002 : STA !ram_cm_hijump : BRA +
  .equipHiJump
    LDA #$0001 : STA !ram_cm_hijump : BRA +
  .noHiJump
    LDA #$0000 : STA !ram_cm_hijump

+   LDA !SAMUS_ITEMS_COLLECTED : BIT #$0200 : BEQ .noSpace
    LDA !SAMUS_ITEMS_EQUIPPED : BIT #$0200 : BNE .equipSpace
    ; unequip Space
    LDA #$0002 : STA !ram_cm_space : BRA +
  .equipSpace
    LDA #$0001 : STA !ram_cm_space : BRA +
  .noSpace
    LDA #$0000 : STA !ram_cm_space

+   LDA !SAMUS_ITEMS_COLLECTED : BIT #$2000 : BEQ .noSpeed
    LDA !SAMUS_ITEMS_EQUIPPED : BIT #$2000 : BNE .equipSpeed
    ; unequip Speed
    LDA #$0002 : STA !ram_cm_speed : BRA +
  .equipSpeed
    LDA #$0001 : STA !ram_cm_speed : BRA +
  .noSpeed
    LDA #$0000 : STA !ram_cm_speed

+   LDA !SAMUS_BEAMS_COLLECTED : BIT #$1000 : BEQ .noCharge
    LDA !SAMUS_BEAMS_EQUIPPED : BIT #$1000 : BNE .equipCharge
    ; unequip Charge
    LDA #$0002 : STA !ram_cm_charge : BRA +
  .equipCharge
    LDA #$0001 : STA !ram_cm_charge : BRA +
  .noCharge
    LDA #$0000 : STA !ram_cm_charge

+   LDA !SAMUS_BEAMS_COLLECTED : BIT #$0002 : BEQ .noIce
    LDA !SAMUS_BEAMS_EQUIPPED : BIT #$0002 : BNE .equipIce
    ; unequip Ice
    LDA #$0002 : STA !ram_cm_ice : BRA +
  .equipIce
    LDA #$0001 : STA !ram_cm_ice : BRA +
  .noIce
    LDA #$0000 : STA !ram_cm_ice

+   LDA !SAMUS_BEAMS_COLLECTED : BIT #$0001 : BEQ .noWave
    LDA !SAMUS_BEAMS_EQUIPPED : BIT #$0001 : BNE .equipWave
    ; unequip Wave
    LDA #$0002 : STA !ram_cm_wave : BRA +
  .equipWave
    LDA #$0001 : STA !ram_cm_wave : BRA +
  .noWave
    LDA #$0000 : STA !ram_cm_wave

+   LDA !SAMUS_BEAMS_COLLECTED : BIT #$0004 : BEQ .noSpazer
    LDA !SAMUS_BEAMS_EQUIPPED : BIT #$0004 : BNE .equipSpazer
    ; unequip Spazer
    LDA #$0002 : STA !ram_cm_spazer : BRA +
  .equipSpazer
    LDA #$0001 : STA !ram_cm_spazer : BRA +
  .noSpazer
    LDA #$0000 : STA !ram_cm_spazer

+   LDA !SAMUS_BEAMS_COLLECTED : BIT #$0008 : BEQ .noPlasma
    LDA !SAMUS_BEAMS_EQUIPPED : BIT #$0008 : BNE .equipPlasma
    ; unequip Plasma
    LDA #$0002 : STA !ram_cm_plasma : BRA +
  .equipPlasma
    LDA #$0001 : STA !ram_cm_plasma : BRA +
  .noPlasma
    LDA #$0000 : STA !ram_cm_plasma

+   RTL
}

pushpc
org !FREESPACE_DEBUG_MENU_BANK80
print pc, " transfer_cgram_long start"
transfer_cgram_long:
{
    PHP
    %a16() : %i8()
    LDX #$80 : STX $2100
    JSR $933A
    LDX #$0F : STX $2100
    PLP
    RTL
}
print pc, " transfer_cgram_long start"
pullpc


; ---------
; Menu Data
; ---------

print pc, " mainmenu start"
incsrc mainmenu.asm
print pc, " mainmenu end"
pullpc


; ---------
; Resources
; ---------

HexMenuGFXTable:
    dw $2C70, $2C71, $2C72, $2C73, $2C74, $2C75, $2C76, $2C77, $2C78, $2C79, $2C50, $2C51, $2C52, $2C53, $2C54, $2C55

DecMenuGFXTable:
    dw $2C20, $2C21, $2C22, $2C23, $2C24, $2C25, $2C26, $2C27, $2C28, $2C29
print pc, " menu end"

org !FREESPACE_DEBUG_MENU_GFX
print pc, " menu graphics start"
cm_hud_table:
    ; 900h bytes
    incbin ../resources/cm_gfx.bin
print pc, " menu graphics end"
