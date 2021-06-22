; Entity kinds for initialization
; These differ from the entity types used elsewhere as many of these types
; can map to the same entity type
; For instance, entity_init_spike and entity_init_homing both produce entitys
; with type entity_spike, however the associated functions differ
.define entity_init_empty   0
.define entity_init_fairy   1
.define entity_init_spike   2
.define entity_init_homing  3

; Initialize an entity
; KIND should be one of the entity initialization types defined above
.macro InitEntity args SLOT KIND X Y VX VY ATTR
    pha
    php

    stz SLOT + game_obj.tile

    ; Fairy attributes
    lda #ATTR
    sta SLOT + game_obj.attr

    A16
    lda #X
    sta SLOT + game_obj.x

    lda #Y
    sta SLOT + game_obj.y

    lda #VX
    sta SLOT + game_obj.vy

    lda #VY
    sta SLOT + game_obj.vy

    ; Load functions based on entity init type
.if KIND == entity_init_empty
    A8

    lda #entity_empty
    sta SLOT + game_obj.kind
.endif

.if KIND == entity_init_fairy
    lda #FairyMovement
    sta SLOT + game_obj.phys

    lda #FairyAnimate
    sta SLOT + game_obj.anim
    
    lda #FairyCollision
    sta SLOT + game_obj.collide

    A8

    lda #entity_fairy
    sta SLOT + game_obj.kind
.endif

.if KIND == entity_init_spike
    lda #EmptyFn
    sta SLOT + game_obj.phys
    sta SLOT + game_obj.collide

    lda #SpikeAnimate
    sta SLOT + game_obj.anim

    A8

    lda #entity_spike
    sta SLOT + game_obj.kind
.endif

.if KIND == entity_init_homing
    lda #HomingMovement
    sta SLOT + game_obj.phys

    lda #SpikeAnimate
    sta SLOT + game_obj.anim

    lda #EmptyFn
    sta SLOT + game_obj.collide

    A8

    lda #entity_spike
    sta SLOT + game_obj.kind
.endif

    plp
    pla
.endm

Setup:
    pha
    php

    A8

    ; Start FBlank by turning off the screen
    lda #%10000000
    sta $2100

    ; Clear oam mirror
    AXY16
    lda #_sizeof_oam_buffer
@OamClearStart:
    sec
    sbc #_sizeof_oam_buffer.0
    tax

    lda #$00ff
    sta oam_buffer + oam_obj.x, x
    lda #$0000
    sta oam_buffer + oam_obj.tile, x

    txa
    bne @OamClearStart


    A8
    XY16
    ; Clear entity table
    ldx #_sizeof_entity
@EntityClearStart:
    dex

    lda #$00
    sta entity, x

    txa
    bne @EntityClearStart

    AXY8

    ; Setting starting values
    stz frame_count

    ; slot kind x y vx vy attrs
    InitEntity entity.0 entity_init_fairy $3000 $7500 $0000 $0000 %01110010
    InitEntity entity.1 entity_init_spike $9000 $2500 $0180 $0000 %01110010
    InitEntity entity.2 entity_init_spike $9000 $2500 $0180 $0180 %01110010
    InitEntity entity.3 entity_init_spike $9000 $2500 $0000 $0180 %01110010
    InitEntity entity.4 entity_init_homing $9000 $9500 $0000 $0000 %01110010

    SetupVramDMA 0 sprite_fairy_rom $4000 _sizeof_sprite_fairy
    SetupPaletteDMA 1 palette_rom $90 _sizeof_palette

    ; Start the transfers
    ; Enabling the first two bits corresponds to the first two channels
    ; In this case, channel 0 is for palettes and 1 is for vram
    lda	#%00000011
    sta	$420b

    SetupPaletteDMA 1 palette_rom 0 $a0 palette_size

    ; Start the transfer, bit one for channel 0
    lda	#%00000001
    sta	$420b

    ; Set OAM addresses and object priority
    lda #00
    sta $2102
    lda #01
    sta $2103

    ; Setting sprite size/ msb of x
    ; If sprite size = 0, sprite is 8x8
    ; If sprite size = 1, sprite is 16x16
    ; Here I set sprite size = 1, msb x = 0
    ; TODO this is important
    lda #$aa
    sta $2104
    lda #$02
    sta $2104

    ; End FBlank, set brightness to 15 (100%)
    lda #%00001111
    sta $2100

    ; Enable NMI and Controller Auto Read
    lda #$81
    sta $4200

    plp
    pla

    rts
