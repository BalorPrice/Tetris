;----------------------------------------------
; HOUSEKEEPING ROUTINES

curr_palette:	dw house.palette+15

;----------------------------------------------
house.set_paletteHL:
; Set current palette to HL but don't update outputted palette yet
				push bc
				ld bc,15
				add hl,bc
				ld (curr_palette),hl
				pop bc
				ret

house.set_curr_palette:
; Output current palette
				ld bc,&10f8
				ld hl,(curr_palette)
				otdr
				ret

house.palette:	db 8,64,32,0,127,91,52,87,99,74,102,98,114,44,28,124

house.restore_background_palette:
; Reset background colour to level 0
				ld a,99
				ld (house.palette+8),a
				ret

house.palette_off:
				ld bc,4344
				ld a,8
	@loop:
				out (c),a
				djnz @-loop
				ret

;----------------------------------------------
house.border_up:
				ld a,0
				inc a
				and &07
				ld (house.border_up+1),a
				out (BorderReg),a
				ret

;----------------------------------------------
house.clear_screens:
; Clear both screens
				call @+clear
				call house.swap_screens
				call @+clear
				ret

@clear:
; Clear one screen, slow version
				ld hl,0							; Mode 4 is 192 rows of 128 bytes, each with 2 nibbles for a pixel of colour info.
				ld de,1
				ld (hl),dark_grey*&11			; Fill both nibbles with same colour
				ld bc,24576-1
				ldir
				ret

;----------------------------------------------
house.auto_swap:
; Swap screens if auto_swap.on is Yes
				ld a,(auto_swap.on)
				cp On
				ret nz
house.swap_screens:
; Swap displayed and buffer screens
				in a,(LMPR)
				xor 2
				out (LMPR),a
				in a,(VMPR)
				xor 2
				out (VMPR),a
				ret

house.wait_B_frames:
; Wait for B frames
	@loop:
				push bc
				call house.wait_frame
				call keys.input
				pop bc
				djnz @-loop
				ret

house.wait_B_frames_im2:
; Wait for B frames, use IM2 tallies
	@loop:
				push bc
				call house.wait_frame_im2
				pop bc
				djnz @-loop
				ret
;----------------------------------------------
house.wait_frame:
; Wait until frame interrupt occurred - this sets it to 50fps
				in a,(StatusReg)
				bit 3,a
				ret z
				jp house.wait_frame

house.wait_lineA:
				out (StatusReg),a
	@loop:
				in a,(StatusReg)
				bit 0,a
				ret z
				jp @-loop

;----------------------------------------------
house.wait_frame_im2:
; If IM2 is running, check flag for new frame
	@loop:
				ld a,(frame.elapsed)
				cp No
				jp z,@-loop
	@reset_frame_flag:
				ld a,No
				ld (frame.elapsed),a
				ret

house.wait_int_im2:
; If IM2 is running, check flag for new interrupt
	@loop:
				ld a,(interrupt.elapsed)
				cp No
				jp z,@-loop
	@reset_int_flag:
				ld a,No
				ld (interrupt.elapsed),a
				ret

;----------------------------------------------
house.double_buffer.off:
house.double_buffer.on:
; Toggle double buffering.  Labelled both ways for clarity of intent.
				in a,(LMPR)
				xor 2
				out (LMPR),a
				ret

;----------------------------------------------
house.pal_up:
; Output vague progess in decompression to palette 0
				nop								; Changed to RET after decompressing, so outline will still work when running
				push af
				push bc
	@pal:		ld a,0
				inc a
				and %01111111
				ld (@-pal+1),a
				ld bc,PaletteBaseReg
				out (c),a
				pop bc
				pop af
				ret

house.pal_up.set.off:
; Update house.pal_up to quit immediately, set palette 0 back to standard dark grey
				ld a,ret_
				ld (house.pal_up),a
	@reset_palette:
				ld a,8
				ld bc,PaletteBaseReg
				out (c),a
				ret
