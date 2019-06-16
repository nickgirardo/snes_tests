.include "include/Header.inc"
.include "include/Snes_Init.asm"
.include "include/Util.asm"

.define palette $40
.define palette_rom palette+$8000
.define palette_size $40

.org palette
.dw $0000, $6000, $7FFF, $0018
.dw $97A7, $B7C7, $D7E7, $F707
.dw $0000, $ff7f, $7e23, $b711
.dw $9e36, $a514, $ff01, $7810
.dw $0000, $ff7f, $1f5a, $aa55
.dw $b276, $a514, $df2a, $187a

.define sprite_fairy $1000
.define sprite_fairy_rom sprite_fairy+$8000
.define sprite_fairy_size  $0800

.include "include/Sprites/Fairy.inc"

; Not doing anything in vblank
VBlank:
    stz $2102
    stz $2103

    lda $2138
    ldy $2138
    inc a
    iny

    stz $2102
    stz $2103

    sta $2104
    sty $2104


    RTI

Start:
    ; Initialize the SNES.
    Snes_Init

    ; Set the A register to 8-bit
    sep #$20

    ; Start FBlank by turning off the screen
    lda #%10000000
    sta $2100

    SetupVramDMA 0 sprite_fairy_rom 0 $4000 sprite_fairy_size
    SetupPaletteDMA 1 palette_rom 0 $80 palette_size

    ; Start the transfers
    ; Enabling the first two bits corresponds to the first two channels
    ; In this case, channel 0 is for palettes and 1 is for vram
    lda	#%00000011
    sta	$420b

    SetupPaletteDMA 1 palette_rom 0 $a0 palette_size

    ; Start the transfer, bit one for channel 0
    lda	#$01
    sta	$420b

    stz $2102
    stz $2103

    lda #$30
    sta $2104
    lda #$57
    sta $2104
    lda #$00
    sta $2104
    lda #%01110010
    sta $2104

    lda #00
    sta $2102
    lda #01
    sta $2103

    lda #$02
    sta $2104

    ; End FBlank, set brightness to 15 (100%)
    lda #%00001111
    sta $2100

    lda #$80
    sta $4200       ; Enable NMI


    ; Loop forever.
Forever:
    jmp Forever

