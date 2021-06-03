.include "include/Header.inc"
.include "include/Snes_Init.asm"
.include "include/Util.asm"
.include "include/Physics.asm"

; TODO is there a better way of storing these rom addresses?
.define palette $40
.define palette_rom palette+$8000

; Load in the palette data from the binary file
.org palette
.incbin "bin/palette.bin" fsize _sizeof_palette

; TODO is there a better way of storing these rom addresses?
.define sprite_fairy $1000
.define sprite_fairy_rom sprite_fairy+$8000

; Load in the fairy sprite data from the binary file
.org sprite_fairy
.incbin "bin/fairy.bin" fsize _sizeof_sprite_fairy

; Logical structs

; Layout of information in oam
.struct oam_obj
x       db
y       db
tile    db
attr    db
.endst

; Basics physics data for an object
; NOTE the . before the dw bellow cause the position to not advance
; So the words overlap with their component bytes
; This makes addressing the entire word or either byte very easy
.struct phys_obj
x       .dw
xl      db
xh      db
y       .dw
yl      db
yh      db
vx      .dw
vxl     db
vxh     db
vy      .dw
vyl     db
vyh     db
.endst

; Memory addresses
; NOTE using the whole byte just to check if vblank is done
; If we have more, similar flags we can use some of these bytes
.define vblank_done $0000

; Ticks up every frame
; Since this is 8 bits, it will reset every ~4 seconds
; Used for animations currently
.define frame_count $0001

.define p1_control      $0002
.define p1_control_l    $0002
.define p1_control_h    $0003

; This enum should be 9 bytes (phys_obj is 8, and attrs)
.enum $0004
fairy instanceof phys_obj
fairy.tile db
fairy.attr db
.ende

.enum $7e2000
oam_buffer instanceof oam_obj 64 startfrom 0
.ende

VBlank:
    SetupOamDMA 0 oam_buffer $00 _sizeof_oam_buffer

    ; Start the transfer
    ; Enabling the lsb corresponds to the first channels
    lda	#%00000001
    sta	$420b

    ; We're finished rendering the frame
    ; Set vblank_done so the next frame can be started
    lda #$01
    sta vblank_done

    RTI

Start:
    ; Initialize the SNES.
    Snes_Init

    ; Set the A register to 8-bit
    A8

    ; Start FBlank by turning off the screen
    lda #%10000000
    sta $2100

    ; Setting starting values
    stz frame_count

    lda #$30
    sta fairy.xh
    stz fairy.xl

    lda #$75
    sta fairy.yh
    stz fairy.yl

    stz fairy.vxh
    stz fairy.vxl

    stz fairy.vyh
    stz fairy.vyl

    stz fairy.tile

    ; Fairy attributes
    ; vhoopppn
    ; v = vertical flip
    ; h = horizontal flip
    ; o = priority
    ; p = palette
    ; n = Name table (i.e. msb of tile)
    ; Here I am setting priority, horizontal flip, palette = 1
    lda #%01110010
    sta fairy.attr

    ; Clear oam mirror
    ; 64 objects, 4 bytes each
    ldx #$ff
OamClearStart:
    dex
    lda #0
    sta oam_buffer,x
    txa
    bne OamClearStart

    SetupVramDMA 0 sprite_fairy_rom $4000 _sizeof_sprite_fairy
    SetupPaletteDMA 1 palette_rom $90 _sizeof_palette

    ; Start the transfers
    ; Enabling the first two bits corresponds to the first two channels
    ; In this case, channel 0 is for palettes and 1 is for vram
    lda	#%00000011
    sta	$420b

    SetupPaletteDMA 1 palette_rom 0 $a0 palette_size

    ; Start the transfer, bit one for channel 0
    lda	#%00000001
    sta	$420b

    ; Set OAM addresses and object priority
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

    ; Enable NMI and Controller Auto Read
    lda #$81
    sta $4200


    ; Loop forever.
MainLoop:
    ; Starting a new frame, reset vblank_done
    stz vblank_done

    ; Increment frame
    ; Using this for animation right now
    ; This is 8bit, so it repeats every ~4 seconds
    lda frame_count
    ina
    sta frame_count

    ; Read controllers
    jsr ReadController

    ; Do physics
    jsr Physics

    ; Handle animations
    jsr Animations

    ; Prepare OAM
    jsr PrepareOAM

; We're finished everything for our frame
; Wait here until Vblank is done
; Basically a spinwait with the flag vblank_done
VblankWait:
    ; Check if we've finished vblank
    ; If not, continue spinning
    lda vblank_done
    beq VblankWait

    ; We're finished vblank, do another frame
    jmp MainLoop


; Load in controller data
ReadController:
    ; The lsb of address $4212 stores the controller auto read status
    ; If it is set the controllers have not finished being auto read
ControllerAutoReadWait:
    lda $4212
    and #%00000001
    bne ControllerAutoReadWait

    ; Auto read ready, copy data to ram
    lda $4218
    sta p1_control_h
    lda $4219
    sta p1_control_l

    rts

    ; Handle animations
Animations:

    ; Fairy wings animation
    ; Check if any of the arrow keys are pressed down
    ; If not, we're done with animations
    lda p1_control_l
    and #%00001111
    bne FlapWings

    stz fairy.tile
    bra DoneAnimations

FlapWings:
    ; If we're here that means at least one arrow key is down
    ; Flap the fiary's wings
    lda frame_count
    and #%00001000
    lsr
    lsr
    sta fairy.tile

DoneAnimations:
    rts

    ; Copy fairy position to oam mirror
PrepareOAM:
    lda fairy.xh
    sta oam_buffer.0.x
    lda fairy.yh
    sta oam_buffer.0.y
    lda fairy.tile
    sta oam_buffer.0.tile
    lda fairy.attr
    sta oam_buffer.0.attr



    rts
