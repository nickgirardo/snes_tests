.include "include/Header.inc"
.include "include/Snes_Init.asm"
.include "include/Util.asm"

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

; Physics constants
.define fairy_maxv  $0320
.define fairy_speed $42
; NOTE currently friction is just done by subtracting the constant every frame
; this isn't very accurate to life, but it's more than good enough for now
; I may revisit this later but I don't think it's necessary
.define fairy_fric  $18

; Memory addresses
.define vblank_done $0000

.define p1_control      $0002
.define p1_control_l    $0002
.define p1_control_h    $0003

; This enum should be 9 bytes (phys_obj is 8, and attrs)
.enum $0004
fairy instanceof phys_obj
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

    SetupVramDMA 0 sprite_fairy_rom 0 $4000 _sizeof_sprite_fairy
    SetupPaletteDMA 1 palette_rom $90 _sizeof_palette

    ; Start the transfers
    ; Enabling the first two bits corresponds to the first two channels
    ; In this case, channel 0 is for palettes and 1 is for vram
    lda	#%00000011
    sta	$420b

    SetupPaletteDMA 1 palette_rom 0 $a0 palette_size

    ; Start the transfer, bit one for channel 0
    lda	#$01
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

    ; NOTE the following subroutines probably should just be normal branches?
    ; Read controllers
    jsr ReadController

    ; Do physics
    jsr DoPhysics

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


; TODO bounce off walls
DoPhysics:
    A16

    ; Check if right is pressed
    lda p1_control_l
    and #%00000001
    bne P1RightDown

    ; Check if left is pressed
    lda p1_control_l
    and #%00000010
    beq YMovement

P1LeftDown:
    ; If we have left down the fairy should face left
    ; This corresponds to hflip bit = 0
    A8
    lda fairy.attr
    and #%10111111
    sta fairy.attr
    A16

    lda fairy.vx
    sbc #fairy_speed
    sta fairy.vx
    bra YMovement
P1RightDown:
    ; If we have right down the fairy should face right
    ; This corresponds to hflip bit = 1
    A8
    lda fairy.attr
    ora #%01000000
    sta fairy.attr
    A16

    lda fairy.vx
    adc #fairy_speed
    sta fairy.vx

YMovement:
    ; Check if down is pressed
    lda p1_control_l
    and #%00000100
    bne P1DownDown

    ; Check if up is pressed
    lda p1_control_l
    and #%00001000
    beq CalcFriction

P1UpDown:
    lda fairy.vy
    sbc #fairy_speed
    sta fairy.vy
    bra CalcFriction
P1DownDown:
    lda fairy.vy
    adc #fairy_speed
    sta fairy.vy

CalcFriction:
    ;Starting with x friction first
    lda fairy.vx
    bmi MovingLeft
MovingRight:
    ; Check against max vel
    sbc #fairy_maxv
    ; If this is negative, we are slower than max velocity
    bmi FrictionRight
    ; Otherwise we cap it here
    lda #fairy_maxv
    sta fairy.vx

FrictionRight:
    ; Subtract friction constant from velocity
    lda fairy.vx
    sbc #fairy_fric
    sta fairy.vx
    ; If this value is still positive we are fine
    bpl FrictionY

    ; Otherwise we've turned the positive value negative
    ; So we'll zero it here
    stz fairy.vx
    bra FrictionY

MovingLeft:
    ; Check against max vel
    adc #fairy_maxv
    ; If this is positive, we are slower than max velocity
    bpl FrictionLeft
    ; Otherwise we cap it here
    lda #-fairy_maxv
    sta fairy.vx

FrictionLeft:
    ; Add friction constant to velocity
    lda fairy.vx
    adc #fairy_fric
    sta fairy.vx
    ; If this value is still negative we are fine
    bmi FrictionY

    ; Otherwise we've turned the negative value positive
    ; So we'll zero it here
    stz fairy.vx
    bra FrictionY

    ; Done with the x friction, lets do the y friction now
FrictionY:
    lda fairy.vy
    bmi MovingUp
MovingDown:
    ; Check against max vel
    sbc #fairy_maxv
    ; If this is negative, we are slower than max velocity
    bmi FrictionDown
    ; Otherwise we cap it here
    lda #fairy_maxv
    sta fairy.vy

FrictionDown:
    ; Subtract friction constant from velocity
    lda fairy.vy
    sbc #fairy_fric
    sta fairy.vy
    ; If this value is still positive we are fine
    bpl AddVelocities

    ; Otherwise we've turned the positive value negative
    ; So we'll zero it here
    stz fairy.vy
    bra AddVelocities

MovingUp:
    ; Check against max vel
    adc #fairy_maxv
    ; If this is positive, we are slower than max velocity
    bpl FrictionUp
    ; Otherwise we cap it here
    lda #-fairy_maxv
    sta fairy.vy

FrictionUp:
    ; Add friction constant to velocity
    lda fairy.vy
    adc #fairy_fric
    sta fairy.vy
    ; If this value is still negative we are fine
    bmi AddVelocities

    ; Otherwise we've turned the negative value positive
    ; So we'll zero it here
    stz fairy.vy
    bra AddVelocities


AddVelocities:
    lda fairy.x
    adc fairy.vx
    sta fairy.x

    lda fairy.y
    adc fairy.vy
    sta fairy.y

    A8

    rts


    ; Copy fairy position to oam mirror
PrepareOAM:
    lda fairy.xh
    sta oam_buffer.0.x
    lda fairy.yh
    sta oam_buffer.0.y
    lda 0
    sta oam_buffer.0.tile
    lda fairy.attr
    sta oam_buffer.0.attr

    rts
