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

    AXY16

    lda #_sizeof_entity

@PhysicsLoop:
    sec
    sbc #_sizeof_entity.0

    sta scratch.0

    clc
    adc #entity
    sta scratch.2

    tax

    ; Check if the obj is active
    ; Currently this just means kind is not 0
    ; TODO use stack to preseve x register
    A8
    lda game_obj.kind, x
    A16
    beq @LoopCheck

    jsr (game_obj.phys, x)

    ldx scratch.2
    jsr (game_obj.collide, x)

    ldx scratch.2
    jsr WallBounces

    ldx scratch.2
    jsr AddVelocities

@LoopCheck:
    lda scratch.0
    bne @PhysicsLoop

    plp
    pla

    rts


FairyMovement:
    pha
    php

    ; Check if right is pressed
    lda p1_control_l
    and #%00000001
    bne @P1RightDown

    ; Check if left is pressed
    lda p1_control_l
    and #%00000010
    ; If not we're finished with XMovement
    beq @YMovement

@P1LeftDown:
    ; If we have left down the fairy should face left
    ; This corresponds to hflip bit = 0
    A8
    lda game_obj.attr, x
    and #%10111111
    sta game_obj.attr, x
    A16

    ; Subtract constant speed value to velocity (accelerate)
    lda game_obj.vx, x
    sec
    sbc #fairy_speed
    sta game_obj.vx, x

    bra @YMovement
@P1RightDown:
    ; If we have right down the fairy should face right
    ; This corresponds to hflip bit = 1
    A8
    lda game_obj.attr, x
    ora #%01000000
    sta game_obj.attr, x
    A16

    ; Add constant speed value to velocity (accelerate)
    lda game_obj.vx, x
    clc
    adc #fairy_speed
    sta game_obj.vx, x

@YMovement:
    ; Check if down is pressed
    lda p1_control_l
    and #%00000100
    bne @P1DownDown

    ; Check if up is pressed
    lda p1_control_l
    and #%00001000
    beq @CalcFriction

@P1UpDown:
    lda game_obj.vy, x
    sec
    sbc #fairy_speed
    sta game_obj.vy, x
    bra @CalcFriction
@P1DownDown:
    lda game_obj.vy, x
    clc
    adc #fairy_speed
    sta game_obj.vy, x

@CalcFriction:
    ;Starting with x friction first
    lda game_obj.vx, x
    bmi @MovingLeft
@MovingRight:
    ; Check against max vel
    sec
    sbc #fairy_maxv
    ; If this is negative, we are slower than max velocity
    bmi @FrictionRight
    ; Otherwise we cap it here
    lda #fairy_maxv
    sta game_obj.vx, x

@FrictionRight:
    ; Subtract friction constant from velocity
    lda game_obj.vx, x
    sec
    sbc #fairy_fric
    sta game_obj.vx, x
    ; If this value is still positive we are fine
    bpl @FrictionY

    ; Otherwise we've turned the positive value negative
    ; So we'll zero it here
    stz game_obj.vx, x
    bra @FrictionY

@MovingLeft:
    ; Check against max vel
    clc
    adc #fairy_maxv
    ; If this is positive, we are slower than max velocity
    bpl @FrictionLeft
    ; Otherwise we cap it here
    lda #-fairy_maxv
    sta game_obj.vx, x

@FrictionLeft:
    ; Add friction constant to velocity
    lda game_obj.vx, x
    clc
    adc #fairy_fric
    sta game_obj.vx, x
    ; If this value is still negative we are fine
    bmi @FrictionY

    ; Otherwise we've turned the negative value positive
    ; So we'll zero it here
    stz game_obj.vx, x
    bra @FrictionY

    ; Done with the x friction, lets do the y friction now
@FrictionY:
    lda game_obj.vy, x
    bmi @MovingUp
@MovingDown:
    ; Check against max vel
    sec
    sbc #fairy_maxv
    ; If this is negative, we are slower than max velocity
    bmi @FrictionDown
    ; Otherwise we cap it here
    lda #fairy_maxv
    sta game_obj.vy, x

@FrictionDown:
    ; Subtract friction constant from velocity
    lda game_obj.vy, x
    sec
    sbc #fairy_fric
    sta game_obj.vy, x
    ; If this value is still positive we are fine
    bpl @done

    ; Otherwise we've turned the positive value negative
    ; So we'll zero it here
    stz game_obj.vy, x
    bra @done

@MovingUp:
    ; Check against max vel
    clc
    adc #fairy_maxv
    ; If this is positive, we are slower than max velocity
    bpl @FrictionUp
    ; Otherwise we cap it here
    lda #-fairy_maxv
    sta game_obj.vy, x

@FrictionUp:
    ; Add friction constant to velocity
    lda game_obj.vy, x
    clc
    adc #fairy_fric
    sta game_obj.vy, x
    ; If this value is still negative we are fine
    bmi @done

    ; Otherwise we've turned the negative value positive
    ; So we'll zero it here
    stz game_obj.vy, x
    bra @done

@done
    plp
    pla

    rts


    ; Finish up physics by adding velocities to postitions
AddVelocities:
    pha
    php

    lda game_obj.x, x
    clc
    adc game_obj.vx, x
    sta game_obj.x, x

    lda game_obj.y, x
    clc
    adc game_obj.vy, x
    sta game_obj.y, x

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
    lda game_obj.vx, x
    bmi @CheckLeftWall

@CheckRightWall:
    ; We set this check up so that if the physics object would go across the edge
    ; the carry flag will be set
    lda game_obj.x, x

    ; TODO this width is currently hardcoded
    ; It'll be fine as long as our sprites are all 16 pixels large
    ; Offset with width (16 pixels)
    adc #$1000
    adc game_obj.vx, x
    bcc @CheckYWalls

    ; Move game_obj object to screen edge
    lda #-$1000
    sta game_obj.x, x

    ; Negate velocity
    lda #$00
    sbc game_obj.vx, x
    sta game_obj.vx, x

    bra @CheckYWalls

@CheckLeftWall:
    ; We set this check up so that if the physics object would go across the edge
    ; the carry flag will be clear
    lda game_obj.x, x
    adc game_obj.vx, x
    bcs @CheckYWalls

    ; Move physics object to screen edge and negate velocity
    lda #$0000
    sta game_obj.x, x
    sbc game_obj.vx, x
    sta game_obj.vx, x

@CheckYWalls:
    ; Which Y Wall do we need to check?
    ; If we're moving up (negative) check that wall
    ; Otherwise check bottom
    lda game_obj.vy, x
    bmi @CheckTopWall

@CheckBottomWall:
    ; We set this check up so that if the physics object would go across the edge
    ; the carry flag will be set
    lda game_obj.y, x

    ; TODO this height is currently hardcoded
    ; It'll be fine as long as our sprites are all 16 pixels large
    ; Offset with height (16 pixels)
    ; Screen is 224 pixels (shifted left because we're measuring in subpixels)
    adc #$1000 + (($100 - 224) << 8)
    adc game_obj.vy, x
    bcc @done

    ; Move physics object to screen edge
    lda #-1 * ($1000 + (($100 - 224) << 8))
    sta game_obj.y, x

    ; Negate velocity
    lda #$00
    sbc game_obj.vy, x
    sta game_obj.vy, x

    bra @done

@CheckTopWall:
    ; We set this check up so that if the physics object would go across the edge
    ; the carry flag will be clear
    lda game_obj.y, x
    adc game_obj.vy, x
    bcs @done

    ; Move physics object to screen edge and negate velocity
    lda #$00
    sta game_obj.y, x
    sbc game_obj.vy, x
    sta game_obj.vy, x

    ; Finished checking all four walls, return
@done
    plp
    pla

    rts
