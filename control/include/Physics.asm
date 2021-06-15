.include "include/Physics/Friction.asm"
.include "include/Physics/FairyCollision.asm"
.include "include/Physics/FairyMovement.asm"
.include "include/Physics/HomingMovement.asm"

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

