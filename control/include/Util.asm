EmptyFn:
    rts

; The following 6 macros are shorthand to control reigster size
.macro A16
    rep #$20
.endm

.macro A8
    sep #$20
.endm

.macro XY16
    rep #$10
.endm

.macro XY8
    sep #$10
.endm

.macro AXY16
    rep #$30
.endm

.macro AXY8
    sep #$30
.endm

; macro for moving a block of data from cart to ram
; this is probably not the best way to do this but it's working for now
.macro CopyRomToRam args ROM_ADDR RAM_BANK RAM_ADDR SIZE
    .repeat SIZE index size
    lda $8000+ROM_ADDR+size
    sta RAM_BANK*$010000+RAM_ADDR+size
    .endr
.endm

; TODO is 256 byte cap real?
; macro for perparing a transfer of palette data into the PPU's CGRAM
; only use if SIZE is less than 256 bytes
.macro SetupPaletteDMA args DMA_CHANNEL CPU_ADDR CGRAM_ADDR SIZE
    pha
    phx
    php

    A8
    XY16

    ; Destination address (in CGRAM)
    lda	#CGRAM_ADDR
    sta	$2121

    ; DMA Settings
    stz	$4300+($10*DMA_CHANNEL)

    ; DMA Destination
    ; $22 is the lower byte of the CGRAM data register ($2122)
    lda	#$22
    sta	$4301+($10*DMA_CHANNEL)

    ; Source address and bank
    ldx #loword(CPU_ADDR)
    stx $4302+($10*DMA_CHANNEL)
    lda #bankbyte(CPU_ADDR)
    sta $4304+($10*DMA_CHANNEL)

    ; Number of bytes to transfer
    ldx	#SIZE
    stx	$4305+($10*DMA_CHANNEL)

    plp
    plx
    pla
.endm

.macro SetupOamDMA args DMA_CHANNEL CPU_ADDR OAM_ADDR SIZE
    pha
    phx
    php

    A8
    XY16

    ; Destination address (in OAM)
    ldx #OAM_ADDR
    stx $2102

    ; DMA Settings
    stz	$4300+($10*DMA_CHANNEL)

    ; DMA Destination
    ; $04 is the lower byte of the OAM data register ($2104)
    lda #$04
    sta $4301+($10*DMA_CHANNEL)

    ; Source address and bank
    ldx #loword(CPU_ADDR)
    stx $4302+($10*DMA_CHANNEL)
    lda #bankbyte(CPU_ADDR)
    sta $4304+($10*DMA_CHANNEL)

    ; Number of bytes to copy
    ldx #SIZE
    stx $4305+($10*DMA_CHANNEL)

    plp
    plx
    pla
.endm

; TODO fix this up a bit
; TODO CPU_BANK arg can be avoided as above
; macro for perparing a transfer of graphics data into the PPU's VRAM
; TODO is size *really* capped at 256 bytes? Why?
; only use if SIZE is less than 256 bytes
; OFFSET_ADDR is optional
.macro SetupVramDMA args DMA_CHANNEL CPU_ADDR VRAM_ADDR SIZE CPU_OFFSET_ADDR VRAM_OFFSET_ADDR

    ; save the current accumulator, Y index and status registers for the time the function is executed.
    pha
    phy
    php

    A16
    XY8

    ; Destination address with optional offset
    lda	#VRAM_ADDR
    .if NARGS == 6
        clc
        adc VRAM_OFFSET_ADDR
    .endif
    sta	$2116

    ; DMA Settings
    ; #01 means word increments
    ldy	#$01
    sty	$4300+($10*DMA_CHANNEL)

    ; DMA Destination
    ; $18 is the lower byte of the VRAM data register ($2118)
    ldy	#$18
    sty	$4301+($10*DMA_CHANNEL)

    ; Source address
    ; I can't remember why I went through all of the effort to allow
    ; offsets to be used
    lda	#loword(CPU_ADDR)
    .if NARGS == 6
        clc
        adc CPU_OFFSET_ADDR
    .endif
    sta	$4302+($10*DMA_CHANNEL)

    ldy	#bankbyte(CPU_ADDR)
    sty	$4304+($10*DMA_CHANNEL)

    ; Number of bytes to transfer
    lda	#SIZE
    sta	$4305+($10*DMA_CHANNEL)

    plp
    ply
    pla
.endm


; TODO check this out later, probably don't need CPU_BANK
; macro for perparing a transfer of graphics data into the PPU's VRAM
; only use if SIZE is less than 256 bytes
; OFFSET_ADDR is optional
.macro msetVramDMA args DMA_CHANNEL CPU_ADDR VRAM_ADDR SIZE

    ; save the current accumulator, Y index and status registers for the time the function is executed
    pha
    phx
    php

    A8
    XY16

    ; VRAM increment value
    ; write $80 bytes in one row
    ; not 100% sure what this value entails
    lda #$80
    sta $2115

    ; Destination address in VRAM
    ldx #VRAM_ADDR
    stx $2116

    ; DMA settings
    ; 43x0 format: ab0cdeee
    ; Setting cd = 11 means not incrementing the source address
    ; Setting eee = 001 means moving words at a time
    lda #%00001101
    sta $4300+($10*DMA_CHANNEL)

    ; DMA Destination
    ; $18 is the lower byte of the VRAM data register ($2118)
    lda #$18
    sta $4301+($10*DMA_CHANNEL)

    ; Source address and bank
    ldx #loword(CPU_ADDR)
    stx $4302+($10*DMA_CHANNEL)
    lda #bankbyte(CPU_ADDR)
    sta $4304+($10*DMA_CHANNEL)

    ; Number of bytes to transfer
    ldx #SIZE
    stx $4305+($10*DMA_CHANNEL)

    ; Restore registers
    plp
    plx
    pla
.endm
