; Handle animations
Animations:
    pha
    php

    AXY16

    lda #_sizeof_entity

@AnimLoop:
    sec
    sbc #_sizeof_entity.0

    sta scratch.0

    clc
    adc #entity
    sta scratch.2

    tax

    ; Check if the obj is active
    ; Currently this just means flags are set
    A8
    lda game_obj.flags, x
    A16
    beq @LoopCheck

    jsr (game_obj.anim, x)

@LoopCheck:
    lda scratch.0
    bne @AnimLoop

    plp
    pla

    rts


FairyAnimate:
    pha
    php

    A8

    ; Fairy wings animation
    ; Check if any of the arrow keys are pressed down
    ; If not, we're done with animations
    lda p1_control_l
    and #%00001111
    bne @FlapWings

    stz game_obj.tile, x
    stz game_obj.tile, x
    bra @done

@FlapWings:
    ; If we're here that means at least one arrow key is down
    ; Flap the fiary's wings
    lda frame_count
    and #%00001000
    lsr
    lsr
    sta game_obj.tile, x
    sta game_obj.tile, x

@done:
    plp
    pla

    rts

