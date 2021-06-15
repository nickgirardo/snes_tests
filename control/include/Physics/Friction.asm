
.macro MakeFriction args FRIC MAXV
@Friction:
    pha
    php

    ;Starting with x friction first
    lda game_obj.vx, x
    bmi @@MovingLeft
@@MovingRight:
    ; Check against max vel
    sec
    sbc #MAXV
    ; If this is negative, we are slower than max velocity
    bmi @@FrictionRight
    ; Otherwise we cap it here
    lda #MAXV
    sta game_obj.vx, x

@@FrictionRight:
    ; Subtract friction constant from velocity
    lda game_obj.vx, x
    sec
    sbc #FRIC
    sta game_obj.vx, x
    ; If this value is still positive we are fine
    bpl @@FrictionY

    ; Otherwise we've turned the positive value negative
    ; So we'll zero it here
    stz game_obj.vx, x
    bra @@FrictionY

@@MovingLeft:
    ; Check against max vel
    clc
    adc #MAXV
    ; If this is positive, we are slower than max velocity
    bpl @@FrictionLeft
    ; Otherwise we cap it here
    lda #-MAXV
    sta game_obj.vx, x

@@FrictionLeft:
    ; Add friction constant to velocity
    lda game_obj.vx, x
    clc
    adc #FRIC
    sta game_obj.vx, x
    ; If this value is still negative we are fine
    bmi @@FrictionY

    ; Otherwise we've turned the negative value positive
    ; So we'll zero it here
    stz game_obj.vx, x
    bra @@FrictionY

    ; Done with the x friction, lets do the y friction now
@@FrictionY:
    lda game_obj.vy, x
    bmi @@MovingUp
@@MovingDown:
    ; Check against max vel
    sec
    sbc #MAXV
    ; If this is negative, we are slower than max velocity
    bmi @@FrictionDown
    ; Otherwise we cap it here
    lda #MAXV
    sta game_obj.vy, x

@@FrictionDown:
    ; Subtract friction constant from velocity
    lda game_obj.vy, x
    sec
    sbc #FRIC
    sta game_obj.vy, x
    ; If this value is still positive we are fine
    bpl @@done

    ; Otherwise we've turned the positive value negative
    ; So we'll zero it here
    stz game_obj.vy, x
    bra @@done

@@MovingUp:
    ; Check against max vel
    clc
    adc #MAXV
    ; If this is positive, we are slower than max velocity
    bpl @@FrictionUp
    ; Otherwise we cap it here
    lda #-MAXV
    sta game_obj.vy, x

@@FrictionUp:
    ; Add friction constant to velocity
    lda game_obj.vy, x
    clc
    adc #FRIC
    sta game_obj.vy, x
    ; If this value is still negative we are fine
    bmi @@done

    ; Otherwise we've turned the negative value positive
    ; So we'll zero it here
    stz game_obj.vy, x
    bra @@done

@@done:
    plp
    pla

    rts

.endm
