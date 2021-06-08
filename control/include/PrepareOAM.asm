    ; Copy fairy position to oam mirror
; Handle animations
PrepareOAM:
    pha
    php

    AXY16

    lda #loword((_sizeof_oam_buffer.0 * entity_count) + oam_buffer)
    sta scratch.2

    A8
    lda #bankbyte((_sizeof_oam_buffer.0 * entity_count) + oam_buffer)
    sta scratch.4
    A16

    lda #_sizeof_entity

@OAMLoop:
    sec
    sbc #_sizeof_entity.0

    sta scratch.0

    clc
    adc #entity
    tax

    lda scratch.2
    sec
    sbc #_sizeof_oam_buffer.0
    sta scratch.2

    ; Check if the obj is active
    ; Currently this just means kind is not 0
    A8
    lda game_obj.kind, x
    beq @LoopCheck

    ldy #$0

    lda game_obj.xh, x
    sta [scratch.2], y
    iny
    lda game_obj.yh, x
    sta [scratch.2], y
    iny
    lda game_obj.tile, x
    sta [scratch.2], y
    iny
    lda game_obj.attr, x
    sta [scratch.2], y

    A16

@LoopCheck:
    A16

    lda scratch.0
    bne @OAMLoop

    plp
    pla

    rts


