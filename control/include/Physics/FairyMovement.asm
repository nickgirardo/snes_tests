; Physics constants
.define fairy_maxv  $0320
.define fairy_speed $42
; NOTE currently friction is just done by subtracting the constant every frame
; this isn't very accurate to life, but it's more than good enough for now
; I may revisit this later but I don't think it's necessary
.define fairy_fric  $18

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

@CalcFriction
    jsr @Friction

@done
    plp
    pla

    rts

; Produces a label @Friction which runs the friction code
; Created as a macro for my ease, if rom space becomes an issue maybe revistit
MakeFriction fairy_fric fairy_maxv
