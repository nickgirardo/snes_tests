; Physics constants
.define homing_maxv         $0160
.define homing_speed        $35
.define homing_speed_diag   $40
; NOTE currently friction is just done by subtracting the constant every frame
; this isn't very accurate to life, but it's more than good enough for now
; I may revisit this later but I don't think it's necessary
.define homing_fric         $15


; TODO currently the fairy is in slot entity.0
; I'm hardcoding that here but it might not be ideal for the future
HomingMovement:
    pha
    php

    AXY16

    ; Calculate dx
    lda game_obj.x, x
    sec
    sbc entity.0.x
    sta scratch.4

    ; calculate -dx
    eor #$ffff
    inc a
    sta scratch.8

    ; Calculate dy
    lda game_obj.y, x
    sec
    sbc entity.0.y
    sta scratch.6

    ; Calculate -dy
    eor #$ffff
    inc a
    sta scratch.10

    lda scratch.4

    bmi @negDX
    jsr _PositiveDX
    bra @CalcFriction
@negDX:
    jsr _NegativeDX

@CalcFriction:
    ;Starting with x friction first
    lda game_obj.vx, x
    bmi @MovingLeft
@MovingRight:
    ; Check against max vel
    sec
    sbc #homing_maxv
    ; If this is negative, we are slower than max velocity
    bmi @FrictionRight
    ; Otherwise we cap it here
    lda #homing_maxv
    sta game_obj.vx, x

@FrictionRight:
    ; Subtract friction constant from velocity
    lda game_obj.vx, x
    sec
    sbc #homing_fric
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
    adc #homing_maxv
    ; If this is positive, we are slower than max velocity
    bpl @FrictionLeft
    ; Otherwise we cap it here
    lda #-homing_maxv
    sta game_obj.vx, x

@FrictionLeft:
    ; Add friction constant to velocity
    lda game_obj.vx, x
    clc
    adc #homing_fric
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
    sbc #homing_maxv
    ; If this is negative, we are slower than max velocity
    bmi @FrictionDown
    ; Otherwise we cap it here
    lda #homing_maxv
    sta game_obj.vy, x

@FrictionDown:
    ; Subtract friction constant from velocity
    lda game_obj.vy, x
    sec
    sbc #homing_fric
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
    adc #homing_maxv
    ; If this is positive, we are slower than max velocity
    bpl @FrictionUp
    ; Otherwise we cap it here
    lda #-homing_maxv
    sta game_obj.vy, x

@FrictionUp:
    ; Add friction constant to velocity
    lda game_obj.vy, x
    clc
    adc #homing_fric
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

_PositiveDX:
    pha
    php

    ; dx (the x difference between the objects) is positive
    ; check here dy to see if we are in quadrant 1 or 4

    lda scratch.6
    bmi @q4
    jsr _Q1
    bra @done
@q4:
    jsr _Q4

@done:
    plp
    pla

    rts


_Q1:
    pha
    php

    ; Positive dx, Positive dy (Quadrant 1)
    ; Check if dx > dy (both positive, no abs value needed)
    lda scratch.4
    sec
    sbc scratch.6

    bmi @DYGreater

    ; dx is greater
    ; let's check if half dx is greater than dy
    lda scratch.4
    lsr
    sec
    sbc scratch.6

    ; Half dx is lesser than dy, go along diagonal
    bmi @MoveDiagonal

    ; Half dx is greater than dy, go straight x
    lda game_obj.vx, x
    sec
    sbc #homing_speed
    sta game_obj.vx, x

    bra @done

@DYGreater
    ; dy is greater
    ; let's check if half dy is greater than dx
    lda scratch.6
    lsr
    sec
    sbc scratch.4

    ; Half dy is lesser, move along diagonal
    bmi @MoveDiagonal

    ; Half dy is greater than dx, go straight y
    lda game_obj.vy, x
    sec
    sbc #homing_speed
    sta game_obj.vy, x

    bra @done

@MoveDiagonal:
    ; Either dx > dy but half dx < dy
    ; or dy > dx but half dy < dx
    ; Either way, move along the diagonal here
    lda game_obj.vx, x
    sec
    sbc #homing_speed_diag
    sta game_obj.vx, x

    lda game_obj.vy, x
    sec
    sbc #homing_speed_diag
    sta game_obj.vy, x

@done:
    plp
    pla

    rts

_Q4:
    pha
    php

    ; Positive dx, Negative dy (Quadrant 4)
    ; Check if abs(dx) > abs(dy)
    ; Since we know dx is positive and dy is negative
    ; we'll use the previously calculated -dy
    lda scratch.4
    sec
    sbc scratch.10

    bmi @DYGreater

    ; abs(dx) > abs(dy)
    ; check if half abs(dx) > abs(dy)
    lda scratch.4
    lsr
    sec
    sbc scratch.10

    bmi @MoveDiagonal

    ; Half dx is greater, go straight x
    lda game_obj.vx, x
    sec
    sbc #homing_speed
    sta game_obj.vx, x

    bra @done

@DYGreater:
    ; abs(dx) < abs(dx)
    ; check if abs(dx) < half abs(dy)
    lda scratch.10
    lsr
    sec
    sbc scratch.4

    bmi @MoveDiagonal

    ; Half dy is greater, go stratight y
    lda game_obj.vy, x
    clc
    adc #homing_speed
    sta game_obj.vy, x

    bra @done

@MoveDiagonal:
    ; Either dx > dy but half dx < dy
    ; or dy > dx but half dy < dx
    ; Either way, move along the diagonal here
    lda game_obj.vx, x
    sec
    sbc #homing_speed_diag
    sta game_obj.vx, x

    lda game_obj.vy, x
    clc
    adc #homing_speed_diag
    sta game_obj.vy, x

@done:
    plp
    pla

    rts


_NegativeDX:
    pha
    php

    ; dx (the x difference between the objects) is negative
    ; check here dy to see if we are in quadrant 2 or 3

    lda scratch.6
    bmi @q3
    jsr _Q2
    bra @done
@q3:
    jsr _Q3

@done:
    plp
    pla

    rts

_Q2:
    pha
    php

    ; Positive dy, Negative dx (Quadrant 2)
    ; Check if abs(dx) > abs(dy)
    ; Since we know dx is negative and dy is positive
    ; we'll use the previously calculated -dx
    lda scratch.8
    sec
    sbc scratch.6

    bmi @DYGreater

    ; abs(dx) > abs(dy)
    ; check if half abs(dx) > abs(dy)
    lda scratch.8
    lsr
    sec
    sbc scratch.6

    bmi @MoveDiagonal

    ; Half dx is greater, go straight x
    lda game_obj.vx, x
    clc
    adc #homing_speed
    sta game_obj.vx, x

    bra @done

@DYGreater
    ; abs(dx) < abs(dy)
    ; check if abs(dx) < half abs(dy)
    lda scratch.6
    lsr
    sec
    sbc scratch.8

    bmi @MoveDiagonal

    ; Half dy is greater, go straight y
    lda game_obj.vy, x
    sec
    sbc #homing_speed
    sta game_obj.vy, x

    bra @done

@MoveDiagonal:
    ; Either dx > dy but half dx < dy
    ; or dy > dx but half dy < dx
    ; Either way, move along the diagonal here
    lda game_obj.vx, x
    clc
    adc #homing_speed_diag
    sta game_obj.vx, x

    lda game_obj.vy, x
    sec
    sbc #homing_speed_diag
    sta game_obj.vy, x

@done
    plp
    pla

    rts

_Q3:
    pha
    php

    ; Negative dx, Negative dy (Quadrant 3)
    ; Check if abs(dx) > abs(dy)
    ; Since we know dx and dy are negative
    ; we'll use the previously calculated -dx and -dy
    lda scratch.8
    sec
    sbc scratch.10

    bmi @DYGreater

    ; abs(dx) > abs(dy)
    ; check if half abs(dx) > abs(dy)
    lda scratch.8
    lsr
    sec
    sbc scratch.10

    bmi @MoveDiagonal

    ; Half dx is greater, go straight x
    lda game_obj.vx, x
    clc
    adc #homing_speed
    sta game_obj.vx, x

    bra @done

@DYGreater
    ; abs(dy) > abs(dx)
    ; check if half abs(dy) > abs(dx)
    lda scratch.10
    lsr
    sec
    sbc scratch.8

    bmi @MoveDiagonal

    ; Half dy is greater, go straight y
    lda game_obj.vy, x
    clc
    adc #homing_speed
    sta game_obj.vy, x

    bra @done

@MoveDiagonal
    ; Either dx > dy but half dx < dy
    ; or dy > dx but half dy < dx
    ; Either way, move along the diagonal here
    lda game_obj.vx, x
    clc
    adc #homing_speed_diag
    sta game_obj.vx, x

    lda game_obj.vy, x
    clc
    adc #homing_speed_diag
    sta game_obj.vy, x

@done
    plp
    pla

    rts

