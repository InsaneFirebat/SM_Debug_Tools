; $82:8963 AD 98 09    LDA $0998  [$7E:0998]
; $82:8966 29 FF 00    AND #$00FF
org $828963
    ; gamemode_shortcuts will either CLC or SEC
    ; to control if normal gameplay will happen on this frame
    JSL gamemode_start : BRA $00


org $85F800
print pc, " gamemode start"

gamemode_start:
{
    PHB
    PHK : PLB
    JSR gamemode_shortcuts
    %ai16()
    ; overwritten code
    LDA !GAMEMODE : AND #$00FF
    PLB
    RTL
}

gamemode_shortcuts:
    LDA !CONTROLLER_PRI_NEW : BNE +
    ; No shortcuts configured, CLC so we won't skip normal gameplay
    CLC : RTS

+   LDA !CONTROLLER_PRI : AND !DEBUG_MENU_SHORTCUT : CMP !DEBUG_MENU_SHORTCUT : BNE +
    AND !CONTROLLER_PRI_NEW : BEQ +
    JMP .menu

    ; No shortcuts matched, CLC so we won't skip normal gameplay
+   CLC : RTS

  .menu
    ; Set IRQ vector
    LDA $AB : PHA
    LDA #$0004 : STA $AB

    ; skip accidental pause from default Start+Select shortcut
    LDA !GAMEMODE : CMP #$000C : BNE +
    LDA #$0008 : STA !GAMEMODE
    ; clear screen fade delay/counter
    STZ $0723 : STZ $0725
    ; Brightness = $F (max)
    LDA $51 : ORA #$000F : STA $51

    ; Enter MainMenu
+   JSL cm_start

    ; Restore IRQ vector
    PLA : STA $AB

    ; SEC to skip normal gameplay for one frame after handling the menu
    SEC : RTS
}

print pc, " gamemode end"
warnpc $85FD00
