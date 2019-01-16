;macro for moving a block of data from cart to ram
;this is probably not the best way to do this but it's working for now
.macro CopyRomToRam args ROM_ADDR RAM_BANK RAM_ADDR SIZE
    .repeat SIZE index size
    lda $8000+ROM_ADDR+size
    sta RAM_BANK*$010000+RAM_ADDR+size
    .endr
.endm

;macro for perparing a transfer of palette data into the PPU's CGRAM
;only use if SIZE is less than 256 bytes
.macro SetupPaletteDMA args DMA_CHANNEL CPU_ADDR CPU_BANK CGRAM_ADDR SIZE
    pha
    php

    rep	#$20		; 16bit A
    lda	#SIZE
    sta	$4305+($10*DMA_CHANNEL); # of bytes to be copied
    lda	#CPU_ADDR 		; offset of data into 4302, 4303
    sta	$4302+($10*DMA_CHANNEL)
    sep	#$20		; 8bit A

    lda	#CPU_BANK		; bank address of data in memory(ROM)
    sta	$4304+($10*DMA_CHANNEL)
    lda	#CGRAM_ADDR
    sta	$2121		; address of CGRAM to start copying graphics to

    stz	$4300+($10*DMA_CHANNEL)		; 0= 1 byte increment (not a word!)
    lda	#$22
    sta	$4301+($10*DMA_CHANNEL)		; destination 21xx   this is 2122 (CGRAM Gate)

    plp
    pla
.endm


;macro for perparing a transfer of graphics data into the PPU's VRAM
;only use if SIZE is less than 256 bytes
.macro SetupVramDMA args DMA_CHANNEL CPU_ADDR CPU_BANK VRAM_ADDR SIZE

    pha			; save the current accumulator, Y index and status registers for the time the function is executed.
    phy
    php

    rep	#$20		; set the accumulator (A) register into 16 bit mode
    sep	#$10		; set the index (X and Y) register into 8 bit mode

    ldy	#$80		;  we will try to write 128 ($80) bytes in one row ...
    sty	$2115		; ... and we will let the PPU let this know.

    lda	#VRAM_ADDR		; the controller will get the hardware register ($2118) as location to where to write the data.
    sta	$2116		; but we still need to specify WHERE in VRAM we want to write the data - what we are doing right now.

    lda	#SIZE		; number of bytes to be sent from the controller.
    sta	$4305+($10*DMA_CHANNEL)

    lda	#CPU_ADDR	; from where the data is supposed to be loaded from
    sta	$4302+($10*DMA_CHANNEL)

    sep	#$20		; set the accumulator (A) register into 8 bit mode

    ldy	#CPU_BANK		; from which bank the data is supposed to be loaded from
    sty	$4304+($10*DMA_CHANNEL)

    ldy	#$01		; set the mode on how the channel is supposed to do it's work. 1= word increment
    sty	$4300+($10*DMA_CHANNEL)

    ldy	#$18		; remember that I wrote "the controller will get the hardware register"? This is it. 2118 is the VRAM gate.
    sty	$4301+($10*DMA_CHANNEL)

    plp			; Restore the state of all registers before leaving the function.
    ply
    pla
.endm
