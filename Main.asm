.include "include/Header.inc"
.include "include/Snes_Init.asm"
.include "include/Util.asm"

.define palette $40
.define palette_rom palette+$8000
.define palette_size $60

.org palette
.db $1F, $2F, $3F, $4F
.db $5F, $6F, $7F, $8F
.db $97, $A7, $B7, $C7
.db $D7, $E7, $F7, $07
.db $13, $23, $33, $43
.db $53, $63, $73, $83
.db $90, $A0, $B0, $C0
.db $D0, $E0, $F0, $00
.db $1F, $2F, $3F, $4F
.db $5F, $6F, $7F, $8F
.db $9F, $AF, $BF, $CF
.db $DF, $EF, $FF, $0F
.db $1F, $2F, $3F, $4F
.db $5F, $6F, $7F, $8F
.db $9F, $AF, $BF, $CF
.db $DF, $EF, $FF, $0F
.db $1F, $2F, $3F, $4F
.db $5F, $6F, $7F, $8F
.db $9F, $AF, $BF, $CF
.db $DF, $EF, $FF, $0F
.db $1F, $2F, $3F, $4F
.db $5F, $6F, $7F, $8F
.db $9F, $AF, $BF, $CF
.db $DF, $EF, $FF, $0F

.define tilemap $A0
.define tilemap_rom tilemap+$8000
.define tilemap_size $20

.org tilemap
.db $00, $00
.db $01, $00
.db $02, $00
.db $03, $00
.db $00, $04
.db $01, $04
.db $02, $04
.db $03, $04
.db $00, $08
.db $01, $08
.db $02, $08
.db $03, $08
.db $00, $0c
.db $01, $0c
.db $02, $0c
.db $03, $0c

.define char $C0
.define char_rom char+$8000
.define char_size $40

.org char
.db $00, $00, $00, $00, $00, $00, $00, $00
.db $00, $00, $00, $00, $00, $00, $00, $00
.db $ab, $ab, $ab, $ab, $ab, $ab, $ab, $ab
.db $ab, $ab, $ab, $ab, $ab, $ab, $ab, $ab
.db $75, $75, $75, $75, $ab, $ab, $ab, $ab
.db $ab, $ab, $ab, $ab, $75, $75, $75, $75
.db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
.db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff

VBlank:

    ; Cycle through all colors for background
    ; Test to make sure this is VBlank and we can access VRAM here
    rep #$20
    lda $020000
    inc a
    sta $020000
    sep #$20

    SetupPaletteDMA 0 0 2 0 2
    lda	#$01
    sta	$420b

    RTI

Start:
    ; Initialize the SNES.
    Snes_Init

    ; Set the A register to 8-bit
    sep #$20

    ; Start FBlank by turning off the screen
    lda #%10000000
    sta $2100

    lda #$01
    sta $210b

    SetupPaletteDMA 0 palette_rom 0 0 palette_size
    SetupVramDMA 1 tilemap_rom 0 0 tilemap_size

    ; Start the transfers
    ; Enabling the first two bits corresponds to the first two channels
    ; In this case, channel 0 is for palettes and 1 is for vram
    lda	#%00000011
    sta	$420b

    SetupVramDMA 0 char_rom 0 $1000 char_size

    ; Start the transfer, bit one for channel 0
    lda	#$01
    sta	$420b

    ; End FBlank, set brightness to 15 (100%)
    lda #%00001111
    sta $2100

    lda #$80
    sta $4200       ; Enable NMI

    ; Loop forever.
Forever:
    jmp Forever

