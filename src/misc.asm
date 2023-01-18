
; Patch out copy protection
org $008000
    db $FF


; Set SRAM size
; Enables SRAM from $700000-$707FFF and $710000-717FFF
; Vanilla uses 700000-$701FFF
;org $00FFD8
;    db $05 ; 64kb


; Skips the waiting time after teleporting
;org $90E877
;    LDA !MUSIC_TRACK
;    JSL $808FC1 ; queue room music track
;    BRA $18


; Toggle on in menu and transition through a door to
; fix graphics corruption from misaligned doors
;org $80AE29
;    JSR ih_fix_scroll_offsets
;
;org !FREESPACE_DEBUG_MISC_BANK80
;print pc, " misc bank80 start"
;ih_fix_scroll_offsets:
;{
;    LDA !ram_fix_scroll_offsets : BEQ .done
;    %a8()
;    LDA !LAYER1_X : STA $B1 : STA $B5
;    LDA !LAYER1_Y : STA $B3 : STA $B7
;    %a16()
;
;  .done
;    ; overwritten code
;    LDA $B1 : SEC
;    RTS
;}
;print pc, " misc bank80 end"
