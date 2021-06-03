; Physics constants
.define fairy_maxv  $0320
.define fairy_speed $42
; NOTE currently friction is just done by subtracting the constant every frame
; this isn't very accurate to life, but it's more than good enough for now
; I may revisit this later but I don't think it's necessary
.define fairy_fric  $18

Physics:
    pha
    php

    A16

    ; Check if right is pressed
    lda p1_control_l
    and #%00000001
    bne P1RightDown

    ; Check if left is pressed
    lda p1_control_l
    and #%00000010
    ; If not we're finished with XMovement
    beq YMovement

P1LeftDown:
    ; If we have left down the fairy should face left
    ; This corresponds to hflip bit = 0
    A8
    lda fairy.attr
    and #%10111111
    sta fairy.attr
    A16

    ; Subtract constant speed value to velocity (accelerate)
    lda fairy.vx
    sec
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

    ; Add constant speed value to velocity (accelerate)
    lda fairy.vx
    clc
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
    sec
    sbc #fairy_speed
    sta fairy.vy
    bra CalcFriction
P1DownDown:
    lda fairy.vy
    clc
    adc #fairy_speed
    sta fairy.vy

CalcFriction:
    ;Starting with x friction first
    lda fairy.vx
    bmi MovingLeft
MovingRight:
    ; Check against max vel
    sec
    sbc #fairy_maxv
    ; If this is negative, we are slower than max velocity
    bmi FrictionRight
    ; Otherwise we cap it here
    lda #fairy_maxv
    sta fairy.vx

FrictionRight:
    ; Subtract friction constant from velocity
    lda fairy.vx
    sec
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
    clc
    adc #fairy_maxv
    ; If this is positive, we are slower than max velocity
    bpl FrictionLeft
    ; Otherwise we cap it here
    lda #-fairy_maxv
    sta fairy.vx

FrictionLeft:
    ; Add friction constant to velocity
    lda fairy.vx
    clc
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
    sec
    sbc #fairy_maxv
    ; If this is negative, we are slower than max velocity
    bmi FrictionDown
    ; Otherwise we cap it here
    lda #fairy_maxv
    sta fairy.vy

FrictionDown:
    ; Subtract friction constant from velocity
    lda fairy.vy
    sec
    sbc #fairy_fric
    sta fairy.vy
    ; If this value is still positive we are fine
    bpl BeforeWallBounces

    ; Otherwise we've turned the positive value negative
    ; So we'll zero it here
    stz fairy.vy
    bra BeforeWallBounces

MovingUp:
    ; Check against max vel
    clc
    adc #fairy_maxv
    ; If this is positive, we are slower than max velocity
    bpl FrictionUp
    ; Otherwise we cap it here
    lda #-fairy_maxv
    sta fairy.vy

FrictionUp:
    ; Add friction constant to velocity
    lda fairy.vy
    clc
    adc #fairy_fric
    sta fairy.vy
    ; If this value is still negative we are fine
    bmi BeforeWallBounces

    ; Otherwise we've turned the negative value positive
    ; So we'll zero it here
    stz fairy.vy
    bra BeforeWallBounces

BeforeWallBounces:
    ldx #fairy
    jsr WallBounces

    ldx #fairy
    jsr AddVelocities

    plp
    pla

    rts


    ; Finish up physics by adding velocities to postitions
AddVelocities:
    pha
    php

    lda phys_obj.x, x
    clc
    adc phys_obj.vx, x
    sta phys_obj.x, x

    lda phys_obj.y, x
    clc
    adc phys_obj.vy, x
    sta phys_obj.y, x

    plp
    pla

    rts


    ; Bounce of walls section
WallBounces:

    pha
    php

    AXY16

    ; Which X Wall do we need to check?
    ; If we're moving left (negative) check that wall
    ; Otherwise check right
    lda phys_obj.vx, x
    bmi CheckLeftWall

CheckRightWall:
    ; We set this check up so that if the physics object would go across the edge
    ; the carry flag will be set
    lda phys_obj.x, x

    ; TODO this width is currently hardcoded
    ; It'll be fine as long as our sprites are all 16 pixels large
    ; Offset with width (16 pixels)
    adc #$1000
    adc phys_obj.vx, x
    bcc CheckYWalls

    ; Move physics object to screen edge
    lda #-$1000
    sta phys_obj.x, x

    ; Negate velocity
    lda #$00
    sbc phys_obj.vx, x
    sta phys_obj.vx, x

    bra CheckYWalls

CheckLeftWall:
    ; We set this check up so that if the physics object would go across the edge
    ; the carry flag will be clear
    lda phys_obj.x, x
    adc phys_obj.vx, x
    bcs CheckYWalls

    ; Move physics object to screen edge and negate velocity
    lda #$0000
    sta phys_obj.x, x
    sbc phys_obj.vx, x
    sta phys_obj.vx, x

CheckYWalls:
    ; Which Y Wall do we need to check?
    ; If we're moving up (negative) check that wall
    ; Otherwise check bottom
    lda phys_obj.vy, x
    bmi CheckTopWall

CheckBottomWall:
    ; We set this check up so that if the physics object would go across the edge
    ; the carry flag will be set
    lda phys_obj.y, x

    ; TODO this height is currently hardcoded
    ; It'll be fine as long as our sprites are all 16 pixels large
    ; Offset with height (16 pixels)
    ; Screen is 224 pixels (shifted left because we're measuring in subpixels)
    adc #$1000 + (($100 - 224) << 8)
    adc phys_obj.vy, x
    bcc .done

    ; Move physics object to screen edge
    lda #-1 * ($1000 + (($100 - 224) << 8))
    sta phys_obj.y, x

    ; Negate velocity
    lda #$00
    sbc phys_obj.vy, x
    sta phys_obj.vy, x

    bra .done

CheckTopWall:
    ; We set this check up so that if the physics object would go across the edge
    ; the carry flag will be clear
    lda phys_obj.y, x
    adc phys_obj.vy, x
    bcs .done

    ; Move physics object to screen edge and negate velocity
    lda #$00
    sta phys_obj.y, x
    sbc phys_obj.vy, x
    sta phys_obj.vy, x

    ; Finished checking all four walls, return
.done
    plp
    pla

    rts
