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

; Physics constants
.define fairy_maxv  $0300
.define fairy_speed $40
.define fairy_fric  $18

; Memory addresses
.define vblank_done $0000

.define p1_control      $0002
.define p1_control_l    $0002
.define p1_control_h    $0003

.define fairy_x     $0004
.define fairy_xl    $0004
.define fairy_xh    $0005
.define fairy_y     $0006
.define fairy_yl    $0006
.define fairy_yh    $0007

.define fairy_vx    $0008
.define fairy_vxl   $0008
.define fairy_vxh   $0009
.define fairy_vy    $0010
.define fairy_vyl   $0010
.define fairy_vyh   $0011

.define fairy_attr  $0012

VBlank:
    lda fairy_xh
    ldy fairy_yh

    ; Reset our OAM read/ write address to access first spot
    stz $2102
    stz $2103

    ; Update x and y values
    sta $2104
    sty $2104

    ; We're finished rendering the frame
    ; Set vblank_done so the next frame can be started
    lda #$01
    sta vblank_done

    RTI

Start:
    ; Initialize the SNES.
    Snes_Init

    ; Set the A register to 8-bit
    ACC8

    ; Start FBlank by turning off the screen
    lda #%10000000
    sta $2100

    ; Setting starting values
    lda #$30
    sta fairy_xh
    stz fairy_xl

    lda #$75
    sta fairy_yh
    stz fairy_yl

    stz fairy_vxh
    stz fairy_vxl

    stz fairy_vyh
    stz fairy_vyl

    ; Fairy attributes
    ; vhoopppn
    ; v = vertical flip
    ; h = horizontal flip
    ; o = priority
    ; p = palette
    ; n = Name table (i.e. msb of tile)
    ; Here I am setting priority, horizontal flip, palette = 1
    lda #%01110010
    sta fairy_attr

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
    lda fairy_x
    sta $2104
    ; Starting y = $57
    lda fairy_y
    sta $2104
    ; Tile number = 0
    lda #$00
    sta $2104
    ; Object attributes
    lda fairy_attr
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

    ; Enable NMI and Controller Auto Read
    lda #$81
    sta $4200


    ; Loop forever.
MainLoop:
    ; Starting a new frame, reset vblank_done
    stz vblank_done

    ; Read controllers
    jsr ReadController

    ; Do physics
    jsr DoPhysics

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
    ACC16

    ; Check if right is pressed
    lda p1_control_l
    and #%00000001
    bne P1RightDown

    ; Check if left is pressed
    lda p1_control_l
    and #%00000010
    beq YMovement

    ; TODO flip fairy sprite here
P1LeftDown:
    lda fairy_vx
    sbc #fairy_speed
    sta fairy_vx
    bra YMovement
P1RightDown:
    lda fairy_vx
    adc #fairy_speed
    sta fairy_vx

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
    lda fairy_vy
    sbc #fairy_speed
    sta fairy_vy
    bra CalcFriction
P1DownDown:
    lda fairy_vy
    adc #fairy_speed
    sta fairy_vy

CalcFriction:
    ;Starting with x friction first
    lda fairy_vx
    bmi MovingLeft
MovingRight:
    ; Check against max vel
    sbc #fairy_maxv
    ; If this is negative, we are slower than max velocity
    bmi FrictionRight
    ; Otherwise we cap it here
    lda #fairy_maxv
    sta fairy_vx

FrictionRight:
    ; Subtract friction constant from velocity
    lda fairy_vx
    sbc #fairy_fric
    sta fairy_vx
    ; If this value is still positive we are fine
    bpl FrictionY

    ; Otherwise we've turned the positive value negative
    ; So we'll zero it here
    stz fairy_vx
    bra FrictionY

MovingLeft:
    ; Check against max vel
    adc #fairy_maxv
    ; If this is positive, we are slower than max velocity
    bpl FrictionLeft
    ; Otherwise we cap it here
    lda #-fairy_maxv
    sta fairy_vx

FrictionLeft:
    ; Add friction constant to velocity
    lda fairy_vx
    adc #fairy_fric
    sta fairy_vx
    ; If this value is still negative we are fine
    bmi FrictionY

    ; Otherwise we've turned the negative value positive
    ; So we'll zero it here
    stz fairy_vx
    bra FrictionY

    ; Done with the x friction, lets do the y friction now
FrictionY:
    lda fairy_vy
    bmi MovingUp
MovingDown:
    ; Check against max vel
    sbc #fairy_maxv
    ; If this is negative, we are slower than max velocity
    bmi FrictionDown
    ; Otherwise we cap it here
    lda #fairy_maxv
    sta fairy_vy

FrictionDown:
    ; Subtract friction constant from velocity
    lda fairy_vy
    sbc #fairy_fric
    sta fairy_vy
    ; If this value is still positive we are fine
    bpl AddVelocities

    ; Otherwise we've turned the positive value negative
    ; So we'll zero it here
    stz fairy_vy
    bra AddVelocities

MovingUp:
    ; Check against max vel
    adc #fairy_maxv
    ; If this is positive, we are slower than max velocity
    bpl FrictionUp
    ; Otherwise we cap it here
    lda #-fairy_maxv
    sta fairy_vy

FrictionUp:
    ; Add friction constant to velocity
    lda fairy_vy
    adc #fairy_fric
    sta fairy_vy
    ; If this value is still negative we are fine
    bmi AddVelocities

    ; Otherwise we've turned the negative value positive
    ; So we'll zero it here
    stz fairy_vy
    bra AddVelocities


AddVelocities:
    lda fairy_x
    adc fairy_vx
    sta fairy_x

    lda fairy_y
    adc fairy_vy
    sta fairy_y

    ACC8

    rts
