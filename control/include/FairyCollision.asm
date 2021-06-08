
; TODO the hitboxes are way too big right now :(
FairyCollision:
    pha
    php

    AXY16

    ; Current entity is scratch.2

    ; Loop through entities

    lda #_sizeof_entity
@CollisionLoop
    sec
    sbc #_sizeof_entity.0

    ; Store the index of the entity we are comparing against
    sta scratch.4

    ; Store the actual address of the entity we are comparing against
    clc
    adc #entity
    sta scratch.6

    ; Check to see if we should skip shit
    ; Right now we're only considering collisions with spikes
    ; The kind byte determines if an entity is active
    ; so we doen't need to check for that specifically
    ; Also, since the current entity is a fairy, not a spike
    ; so we don't have to worry about doing a collision check against itself
    A8
    lda (scratch.6)
    cmp #entity_spike
    A16
    bne @LoopCheck

    ; Actual collision check here
    ; All objects in the game are 16x16 pixels large
@XCheck
    ldy #game_obj.x
    lda (scratch.6), y
    sec
    sbc (scratch.2), y

    bcs @PositiveResultX

    ; Result is negative
    ; Check if it is greater than -$1000
    adc #$1000
    ; If the carry is still clear, no collision
    bcc @LoopCheck

    ; Otherwise we must check y now
    bra @YCheck

@PositiveResultX:
    ; Result is positive
    ; Check if it is less than $1000
    ; TODO store as global?
    sbc #$1000
    ; If the carry is still set, no collision
    bcs @LoopCheck

@YCheck
    ldy #game_obj.y
    lda (scratch.6), y
    sec
    sbc (scratch.2), y

    bcs @PositiveResultY

    ; Result is negative
    ; Check if it is greater than -$1000
    adc #$1000
    ; If the carry is still clear, no collision
    bcc @LoopCheck

    ; Otherwise we have found a collision
    bra @CollisionFound

@PositiveResultY:
    ; Result is positive
    ; Check if it is less than $1000
    ; TODO store as global?
    sbc #$1000
    ; If the carry is still set, no collision
    bcs @LoopCheck

@CollisionFound
    ; Garbage here just as a placeholder
    lda #entity_empty
    sta (scratch.6)


@LoopCheck:
    ; If the current index is 0 we are done
    ; Otherwise move to the next entity
    lda scratch.4
    bne @CollisionLoop

    plp
    pla

    rts
