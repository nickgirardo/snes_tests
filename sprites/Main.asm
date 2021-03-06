.include "include/Header.inc"
.include "include/Snes_Init.asm"
.include "include/Util.asm"

.define palette $40
.define palette_rom palette+$8000
.define palette_size $20

.org palette
.dw $0000, $ff7f, $7e23, $b711
.dw $9e36, $a514, $ff01, $7810

.define sprite_fairy $1000
.define sprite_fairy_rom sprite_fairy+$8000
.define sprite_fairy_size  $0800

.include "include/Sprites/Fairy.inc"

VBlank:
    ; Our fairy sprite is stored at the first spot in oam
    stz $2102
    stz $2103

    ; Reading twice gets x and y pos
    lda $2138
    ldy $2138

    ; Increment each
    inc a
    iny

    ; Reset our read/ write address to first spot
    stz $2102
    stz $2103

    ; Update x and y values
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
    SetupPaletteDMA 1 palette_rom 0 $90 palette_size

    ; Start the transfers
    ; Enabling the first two bits corresponds to the first two channels
    ; In this case, channel 0 is for palettes and 1 is for vram
    lda	#%00000011
    sta	$420b

    SetupPaletteDMA 1 palette_rom 0 $a0 palette_size

    ; Start the transfer, bit one for channel 0
    lda	#$01
    sta	$420b

    ; Setting up our sprite at first spot in oam
    stz $2102
    stz $2103

    ; Starting x = $30
    lda #$30
    sta $2104
    ; Starting y = $57
    lda #$57
    sta $2104
    ; Tile number = 0
    lda #$00
    sta $2104
    ; Object attributes
    ; vhoopppn
    ; v = vertical flip
    ; h = horizontal flip
    ; o = priority
    ; p = palette
    ; n = Name table (i.e. msb of tile)
    ; Here I am setting priority, horizontal flip, palette = 1
    lda #%01110010
    sta $2104

    lda #00
    sta $2102
    lda #01
    sta $2103

    ; Setting sprite size/ msb of x
    ; If sprite size = 0, sprite is 8x8
    ; If sprite size = 1, sprite is 16x16
    ; Here I set sprite size = 1, msb x = 0
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

