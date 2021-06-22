
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

