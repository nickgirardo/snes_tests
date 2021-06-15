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
    bra @doneMovement
@negDX:
    jsr _NegativeDX

@doneMovement:
    jsr @Friction

@done
    plp
    pla

    rts

; Produces a label @Friction which runs the friction code
; Created as a macro for my ease, if rom space becomes an issue maybe revistit
MakeFriction homing_fric homing_maxv

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

