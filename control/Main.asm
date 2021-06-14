.include "include/Header.inc"
.include "include/Snes_Init.asm"
.include "include/Util.asm"
.include "include/Physics.asm"

; TODO is there a better way of storing these rom addresses?
.define palette $40
.define palette_rom palette+$8000

; Load in the palette data from the binary file
.org palette
.incbin "bin/palette.bin" fsize _sizeof_palette

; TODO is there a better way of storing these rom addresses?
.define sprite_fairy $1000
.define sprite_fairy_rom sprite_fairy+$8000

; Load in the fairy sprite data from the binary file
.org sprite_fairy
.incbin "bin/fairy.bin" fsize _sizeof_sprite_fairy

; Entity kinds
.define entity_empty 0
.define entity_fairy 1
.define entity_spike 2

; Logical structs

; Layout of information in oam
.struct oam_obj
x       db
y       db
tile    db
attr    db
.endst

; Basics physics data for an object
; NOTE the . before the dw bellow cause the position to not advance
; So the words overlap with their component bytes
; This makes addressing the entire word or either byte very easy
.struct game_obj
; Currently this just acts like an active bit
; May store more data soon
kind    db
x       .dw
xl      db
xh      db
y       .dw
yl      db
yh      db
vx      .dw
vxl     db
vxh     db
vy      .dw
vyl     db
vyh     db
tile    db
attr    db
phys    dw
anim    dw
collide dw
.endst

; Memory addresses
; NOTE using the whole byte just to check if vblank is done
; If we have more, similar flags we can use some of these bytes
.define vblank_done $0000

; Ticks up every frame
; Since this is 8 bits, it will reset every ~4 seconds
; Used for animations currently
.define frame_count $0001

.define p1_control      $0002
.define p1_control_l    $0002
.define p1_control_h    $0003

.struct byte
. db
.endst

.define entity_count 8
.enum $0004
; Scratch for local, short lived vars
; on x86 I'd use some combination of ebp and esp for this
; but we don't have a register for a base pointer
; Will check if there's a better way for this
scratch instanceof byte $10 startfrom 0
; All of the entity information
entity instanceof game_obj entity_count startfrom 0
.ende

.enum $7e2000
oam_buffer instanceof oam_obj 128 startfrom 0
.ende

EmptyFn:
    rts

VBlank:
    SetupOamDMA 0 oam_buffer $00 _sizeof_oam_buffer

    ; Start the transfer
    ; Enabling the lsb corresponds to the first channels
    lda	#%00000001
    sta	$420b

    ; We're finished rendering the frame
    ; Set vblank_done so the next frame can be started
    lda #$01
    sta vblank_done

    rti

Start:
    ; Initialize the SNES.
    Snes_Init

    ; Set the A register to 8-bit
    A8

    ; Start FBlank by turning off the screen
    lda #%10000000
    sta $2100

    ; Clear oam mirror
    AXY16
    lda #_sizeof_oam_buffer
OamClearStart:
    sec
    sbc #_sizeof_oam_buffer.0
    tax

    lda #$00ff
    sta oam_buffer + oam_obj.x, x
    lda #$0000
    sta oam_buffer + oam_obj.tile, x

    txa
    bne OamClearStart


    A8
    XY16
    ; Clear entity table
    ldx #_sizeof_entity
EntityClearStart:
    dex

    lda #$00
    sta entity, x

    txa
    bne EntityClearStart

    AXY8

    ; Setting starting values
    stz frame_count

    ; Store first fairy
    lda #entity_fairy
    sta entity.0.kind

    lda #$30
    sta entity.0.xh
    stz entity.0.xl

    lda #$75
    sta entity.0.yh
    stz entity.0.yl

    stz entity.0.vxh
    stz entity.0.vxl

    stz entity.0.vyh
    stz entity.0.vyl

    stz entity.0.tile

    ; Fairy attributes
    lda #%01110010
    sta entity.0.attr

    A16
    lda #FairyMovement
    sta entity.0.phys

    lda #FairyAnimate
    sta entity.0.anim
    
    lda #FairyCollision
    sta entity.0.collide
    A8

    ; Store spike
    lda #entity_spike
    sta entity.1.kind

    lda #$90
    sta entity.1.xh
    stz entity.1.xl

    lda #$25
    sta entity.1.yh
    stz entity.1.yl

    stz entity.1.vxh
    stz entity.1.vxl

    lda #$01
    sta entity.1.vyh
    lda #$80
    sta entity.1.vyl

    stz entity.1.tile

    lda #%01110010
    sta entity.1.attr

    A16
    lda #EmptyFn
    sta entity.1.phys

    lda #SpikeAnimate
    sta entity.1.anim
    
    lda #EmptyFn
    sta entity.1.collide
    A8

    ; Store spike
    lda #entity_spike
    sta entity.2.kind

    lda #$90
    sta entity.2.xh
    stz entity.2.xl

    lda #$25
    sta entity.2.yh
    stz entity.2.yl

    lda #$01
    sta entity.2.vxh
    lda #$80
    sta entity.2.vxl

    lda #$01
    sta entity.2.vyh
    lda #$80
    sta entity.2.vyl

    stz entity.2.tile

    lda #%01110010
    sta entity.2.attr

    A16
    lda #EmptyFn
    sta entity.2.phys

    lda #SpikeAnimate
    sta entity.2.anim
    
    lda #EmptyFn
    sta entity.2.collide
    A8

    ; Store spike
    lda #entity_spike
    sta entity.3.kind

    lda #$90
    sta entity.3.xh
    stz entity.3.xl

    lda #$25
    sta entity.3.yh
    stz entity.3.yl

    lda #$01
    sta entity.3.vxh
    lda #$80
    sta entity.3.vxl

    stz entity.3.vyh
    stz entity.3.vyl

    stz entity.3.tile

    lda #%01110010
    sta entity.3.attr

    A16
    lda #EmptyFn
    sta entity.3.phys

    lda #SpikeAnimate
    sta entity.3.anim
    
    lda #EmptyFn
    sta entity.3.collide
    A8

    ; Store homing spike
    lda #entity_spike
    sta entity.4.kind

    lda #$90
    sta entity.4.xh
    stz entity.4.xl

    lda #$25
    sta entity.4.yh
    stz entity.4.yl

    stz entity.4.vxh
    stz entity.4.vxl

    stz entity.4.vyh
    stz entity.4.vyl

    stz entity.4.tile

    lda #%01110010
    sta entity.4.attr

    A16
    lda #HomingMovement
    sta entity.4.phys

    lda #SpikeAnimate
    sta entity.4.anim

    lda #EmptyFn
    sta entity.4.collide
    A8

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


    ; Loop forever.
MainLoop:
    ; Starting a new frame, reset vblank_done
    stz vblank_done

    ; Increment frame
    ; Using this for animation right now
    ; This is 8bit, so it repeats every ~4 seconds
    lda frame_count
    ina
    sta frame_count

    ; Read controllers
    jsr ReadController

    ; Do physics
    jsr Physics

    ; Handle animations
    jsr Animations

    ; Prepare OAM
    jsr PrepareOAM

; We're finished everything for our frame
; Wait here until Vblank is done
; Basically a spinwait with the flag vblank_done
VblankWait:
    ; Check if we've finished vblank
    ; If not, continue spinning
    lda vblank_done
    beq VblankWait

    ; We're finished vblank, do another frame
    jmp MainLoop


; Load in controller data
ReadController:
    ; The lsb of address $4212 stores the controller auto read status
    ; If it is set the controllers have not finished being auto read
ControllerAutoReadWait:
    lda $4212
    and #%00000001
    bne ControllerAutoReadWait

    ; Auto read ready, copy data to ram
    lda $4218
    sta p1_control_h
    lda $4219
    sta p1_control_l

    rts

.include "include/Animate.asm"

.include "include/PrepareOAM.asm"

