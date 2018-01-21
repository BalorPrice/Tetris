; PAUSE FUNCTION

;----------------------------------------------
pause.msg:
				db white*&11,192,68
				dm "PAUSED"
				db eof
pause.msg2:
				db pale_blue*&11,192,69
				dm "PAUSED"
				db eof

;----------------------------------------------
pause.start:
; Test for pause key pressed, run pause cycle if true
@test_pause:
	@test_gs:									; Can't pause if game is over
				ld a,(game_state)
				cp gs.game_over
				ret z
	@test_esc:									; Test escape key
				ld a,(keys.processed)
				bit Escape,a
				ret z

@pause:
				call house.double_buffer.off
@blanking:										; Blank out playing grid
	@loop:
				call house.wait_frame_im2

				call gs.blanker					; call blanking routine
				jp c,@-loop
	@reset_blanking_counter:
				call gs.blanking.reset_counter

@print_msg:										; print pause message and hearts
				call font.set_masked
				ld hl,pause.msg2
				call font.print_string.colHL
				ld hl,pause.msg
				call font.print_string.colHL

				ld b,gfx.heart
				ld hl,7774
				call gfx.print_blockBHL
				ld b,gfx.heart
				ld hl,10102
				call gfx.print_blockBHL

@sound_off:										; No sound for this part
				di
				ld d,28
				xor a
				call sfx.soundDABC

@wait_for_escape:
		@wait:
				call house.wait_frame
				call keys.input

				ld a,(keys.processed)
				bit Escape,a
				jp nz,@+end
				bit RotateC,a
				jp nz,@+end
				bit RotateAC,a
				jp nz,@+end
				jr @-wait

@end:
@reset_screen:
				call gfx.print_full_map1

				ld hl,&3cbc
				ld de,&54f4
				xor a
				call gfx.print_byte_rectHLDEA

				call house.double_buffer.on
	@sound_on:
				ld d,28
				ld a,1
				call sfx.soundDABC
				ei

				jp main.loop
