.include "include/Header.inc"
.include "include/Snes_Init.asm"
.include "include/Util.asm"

.define palette $40
.define palette_rom palette+$8000
.define palette_size $60

.org palette
.dw $0000, $6000, $7FFF, $0018
.dw $97A7, $B7C7, $D7E7, $F707
.dw $1323, $3343, $5363, $7383
.dw $90A0, $B0C0, $D0E0, $F000
.dw $1F2F, $3F4F, $5F6F, $7F8F
.dw $9FAF, $BFCF, $DFEF, $FF0F
.dw $1F2F, $3F4F, $5F6F, $7F8F
.dw $9FAF, $BFCF, $DFEF, $FF0F
.dw $1F2F, $3F4F, $5F6F, $7F8F
.dw $9FAF, $BFCF, $DFEF, $FF0F
.dw $1F2F, $3F4F, $5F6F, $7F8F
.dw $9FAF, $BFCF, $DFEF, $FF0F

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

.define typeface $1000
.define typeface_rom typeface+$8000
.define typeface_size  $0800

.include "include/Typeface.inc"

.define text $1800
.define text_rom text+$8000
.define text_size  $0e00

.org text
.include "text/Test.inc"

.enum $020000
ts_space_char dw
ts_cpu_offset dw
ts_vram_offset dw
ts_frames_since_move db
ts_scanlines_moved db ; Scanlines traversed
ts_next_line db
ts_textlines_moved db ; Count lines of text which have been sent to vram
.ende

.define ts_total_lines $38

VBlank:

    .define text_speed $04
    .define line_width $40

    lda ts_scanlines_moved
    tay
    lda ts_frames_since_move
    inc a
    cmp #text_speed
    bne somewhere
    lda #$00
    iny

somewhere:
    sta ts_frames_since_move
    sty $2112

    tya
    sta ts_scanlines_moved

    cmp ts_next_line
    bne end

    ; Count the total lines of text we've transferred
    lda ts_textlines_moved
    rep #$01
    inc a
    sta ts_textlines_moved

    cmp #ts_total_lines
    beq end

    rep #$01
    lda ts_next_line
    adc #$08
    sta ts_next_line

    SetupVramDMA 0 text_rom 0 $0400 line_width ts_cpu_offset ts_vram_offset

    ; Start the transfer, bit one for channel 0
    lda	#$01
    sta	$420b

    ; 16 bit acc
    rep #$20
    lda ts_cpu_offset

    ; Clear carry
    rep #$01
    adc #line_width
    sta ts_cpu_offset

    ; VRAM offset is half of the cpu offset
    lsr
    and #$fbf0
    sta ts_vram_offset
    sep #$20


end:
    RTI

Start:
    ; Initialize the SNES.
    Snes_Init

    ; Set the A register to 8-bit
    sep #$20

    ; Start FBlank by turning off the screen
    lda #%10000000
    sta $2100

    SetupPaletteDMA 0 palette_rom 0 0 palette_size
    SetupVramDMA 1 tilemap_rom 0 0 tilemap_size

    ; Start the transfers
    ; Enabling the first two bits corresponds to the first two channels
    ; In this case, channel 0 is for palettes and 1 is for vram
    lda	#%00000011
    sta	$420b

    SetupVramDMA 0 typeface_rom 0 $2000 typeface_size

    ; Start the transfer, bit one for channel 0
    lda	#$01
    sta	$420b

    ; lines done count
    lda #$00
    sta ts_frames_since_move
    sta ts_scanlines_moved
    sta ts_textlines_moved

    ; Next dma line
    lda #$08
    sta ts_next_line

    rep #$20
    lda #$0000
    ; cpu offset
    sta ts_cpu_offset
    ; vram offset
    sta ts_vram_offset

    lda #$0080
    sta ts_space_char

    sep #$20

    ; TODO hardcoded for now, fix later
    msetVramDMA 0 $0000 2 $0400 text_size

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

