.include "include/Header.inc"
.include "include/Snes_Init.asm"
.include "include/Util.asm"
.include "include/Physics.asm"
.include "include/Common.asm"
.include "include/Setup.asm"
.include "include/VBlankHandler.asm"

Start:
    ; Initialize the SNES.
    Snes_Init

    jsr Setup

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

