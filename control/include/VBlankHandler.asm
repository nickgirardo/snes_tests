; .include "include/Common.asm"

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

