; ROLLING ATTRACT MODE

;----------------------------------------------
attract.tight_mode:	db Off						; The scroll is really hard, every little helps

attract.pause.len:	equ 310

attract.credits.msg:
				db pale_blue*&11,16,44
				dm "PROGRAM:     "
				db orange
				dm "HOWARD PRICE"
				db cr,pale_blue
				dm "PLAYTESTING: "
				db orange
				dm "DAVID LEDBURY"
				db cr,cr,pale_blue
				dm "MUSIC PROGRAM:"
				db cr,white
				dm " PROTRACKER  "
				db orange
				dm "JAREK BURCZYNSKI"
				db cr,white
				dm " COMPILER    "
				db orange
				dm "ANDREW COLLIER"
				db cr,cr,pale_blue
				dm "MADE WITH:"
				db cr,white
				dm " PYZ80       "
				db orange
				dm "ANDREW COLLIER"
				db cr,white
				dm " SIMCOUPE    "
				db orange
				dm "SIMON OWEN"
				db cr,white
				dm " NOTEPAD++   "
				db orange
				dm "DON HO ++"
				db eof

attract.keys.msg:
				db orange*&11,16,56
				dm "         LEFT: "
				db white
@display.left:	dm "O        "
				db cr,orange
				dm "        RIGHT: "
				db white
@display.right:	dm "P        "
				db cr,orange
				dm "           UP: "
				db white
@display.up:	dm "Q        "
				db cr,orange
				dm "    DOWN/DROP: "
				db white
@display.down:	dm "A        "
				db cr,orange
				dm "  ROTATE LEFT: "
				db white
@display.rotateAC: dm "SPACE    "
				db cr,orange
				dm " ROTATE RIGHT: "
				db white
@display.rotateC: dm "RETURN   "
				db cr,orange
				dm "        PAUSE: "
				db pale_blue
				dm "ESCAPE"
				db cr,cr
				dm "    JOYSTICK "
				db blue
				dm "+"
				db pale_blue
				dm " SHIFT "
				db blue
				dm "+"
				db pale_blue
				dm " SYMBOL"
				db cr
				dm "    CURSORS  "
				db blue
				dm "+"
				db pale_blue
				dm " F0    "
				db blue
				dm "+"
				db pale_blue
				dm " ."
				db eof

attract.keys.pos:								; List of addresses for redefined keys
				dw @display.left,@display.right,@display.up,@display.down,@display.rotateAC,@display.rotateC

attract.piano_roll:								; List of attract routines to call
				dw attract.palette_change_off, attract.wipe_up
				dw attract.set_mode.stb, attract.print_stb, attract.fix_stb
				dw attract.palette_change_on
				dw attract.print_logo, attract.outline_logo
				dw attract.pause_flash, attract.wipe_up, attract.palette_change_off
				dw attract.print_creds
				dw attract.pause,attract.wipe_up
				dw attract.print_keys
				dw attract.pause, attract.wipe_down, attract.clear_upper
				dw attract.set_mode.stb, attract.print_stb, attract.fix_stb
				dw attract.palette_change_on, attract.print_logo, attract.outline_logo
				dw attract.pause_flash, attract.wipe_up, attract.clear_upper
				dw attract.roll_demo
				dw attract.loop

stb.palette:	db 8,0,2,6,7,10,14,15,32,38,44,98,110,99,118,119
stb.print.on:	db Off

;----------------------------------------------
; Rolling attract mode
attract.pause:
	@count:		ld hl,attract.pause.len
				dec hl
				ld (@-count+1),hl
				ld a,h
				or l
				or a
				ret nz
				ld hl,attract.pause.len
				ld (@-count+1),hl
				call attract.fetch_new
				ret

attract.init:
				call music.setup_im2
				call house.set_curr_palette
				ld a,On
				ld (auto_swap.on),a
				call house.clear_screens
				call attract.reset
attract.loop:									; loop to beginning of list, then call first routine to not miss this frame
				ld hl,attract.piano_roll
attract.store:
				ld (attract.curr_instr+1),hl
				ld e,(hl)
				inc hl
				ld d,(hl)
				ld (attract.update+1),de
				ret

attract.fetch_new:
; Move to new attract mode routine
	@update_instruction:
attract.curr_instr: ld hl,0						; Move to next word in FEList
				inc hl
				inc hl
				jp attract.store

attract.update:	jp 0

;----------------------------------------------
attract.reset:
; Reset all counters
				ld hl,attract.pause.len
				ld (attract.pause+1),hl
				ld hl,stb.depth*2
				ld (stb.count+1),hl
				ld hl,logo.data
				ld (attract.print_logo+1),hl
				ld a,255
				ld (attract.outline_logo+1),a
				xor a
				ld (attract.push_start.count+1),a
				ld a,3
				ld (attract.print_creds+1),a
				ld (attract.print_keys+1),a
				ld a,Off
				ld (attract.tight_mode),a
				ld (demo.mode.on),a

				call attract.set_wait_type.int

				ld a,On
				ld (auto_swap.on),a
				ret

;----------------------------------------------
attract.set_stb_pal:
; Change palette to St Basil.  Called from attract interrupt mode at line 36
	@pal_on:	ld a,0
				cp Off
				ret z

				ld hl,stb.palette+15
				ld bc,4344
				otdr
				ret

attract.palette_change_off:
; Set palette changer to quit without changing
				ld a,Off
				ld (@-pal_on+1),a
				call attract.fetch_new
				ret

attract.palette_change_on:
; Set palette changer to run
				ld a,On
				ld (@-pal_on+1),a

				call attract.fetch_new
				ret

attract.set_wait_type.frame:
; Update wait type in attract loop
				ld hl,house.wait_frame_im2
				ld (main.attract_wait+1),hl
				ld a,255
				out (StatusReg),a
				ret

attract.set_wait_type.int:
; Set wait type in attract loop to interrupt
				ld hl,house.wait_int_im2
				ld (main.attract_wait+1),hl
				ld a,37
				out (StatusReg),a
				ret

;----------------------------------------------
attract.set_mode.stb:
; Set interrupt mode for frame interrupt only, set palette to St Basil palette
				di
	@set_mode:									; interrupt mode to frame only
				ld a,int_mode.scroll
				call music.set_modeA
	@set_palette:								; palette to be St Basil palette
				ld hl,stb.palette
				call house.set_paletteHL
				call house.set_curr_palette
				call attract.set_wait_type.frame
				ld a,Off
				ld (auto_swap.on),a
				ld a,On
				ld (stb.print.on),a
				call attract.fetch_new
				ei
				ret

attract.set_mode.attract:
; Set interrupt mode back to frame and line interrupts, set palette to house palette
	@set_mode:
				ld a,int_mode.attract
				call music.set_modeA
	@set_palette:
				ld hl,house.palette
				call house.set_paletteHL
				call attract.set_wait_type.int
				ld a,On
				ld (auto_swap.on),a
				ret

attract.print_stb:
; Print St Basil cathedral graphic
				ld a,On
				ld (attract.tight_mode),a

				di								; disable interrupts because there is the occasional time we miss the deadline :(
	stb.count:	ld hl,stb.depth*2
				dec hl
				ld (stb.count+1),hl
				bit 7,h
				jr z,@+skip
@steady:										; Draw an extra few frames at same height to steady final image
				ld bc,4
				add hl,bc
				jp nc,@+reset
				ld a,l
				and %00000001
				ld l,a
				ld h,0
				jp @+skip
@reset:
				ld a,Off
				ld (stb.print.on),a
				ld hl,stb.depth*2
				ld (stb.count+1),hl
				call attract.set_mode.attract
				call attract.fetch_new

				ld a,Off
				ld (attract.tight_mode),a
				ei
				ret
@skip:											; Print in 25fps, flip between frames each call
				srl h
				rr l
				jp c,@+frame0
	@frame1:
				ld a,1
				call stb.printHLA
				call house.swap_screens
				ei
				ret
	@frame0:
				xor a
				call stb.printHLA
				ei
				ret


attract.fix_stb:
; On final print, correct 5x bytes that aren't cleared from
				call house.swap_screens
				xor a
				ld (&1dc1),a
				ld (&1f41),a
				ld (&2eb7),a
				ld (&4b21),a
				ld (&4d21),a
				call house.swap_screens
				call attract.fetch_new
				ret
;----------------------------------------------
attract.push_start.update:
; Update the counter for push start icon
				push af
attract.push_start.count: ld a,0
				dec a
				ld (attract.push_start.count+1),a
				pop af
				ret

attract.push_start.print:
; Print push start icon if counter in correct phase
				ld bc,&0ff0						; Used in print routine
				ld a,(attract.push_start.count+1)
				bit 5,a
				jp nz,push_start.print
				ret

attract.push_start.clear:
				push hl
				ld a,(attract.push_start.count+1)
				bit 5,a
				call z,@+clear
	@end:
				pop hl
				ret

@clear:
				ld a,(stb.print.on)
				cp On
				jp nz,stb.reprint_start
@stb:
				ld (@+rest_sp+1),sp

				ld hl,&509b
				ld de,128-6
				ld bc,&0400
	@loop:
				ld (hl),c
				inc l
				ld (hl),c
				inc l
				ld (hl),c
				inc l
				ld (hl),c
				inc l
				ld (hl),c
				inc l
				ld (hl),c
				inc l
				ld (hl),c
				add hl,de
				djnz @-loop

@print_blank:									; Print 7 lines of blank under bottom seam of scroll image
				ld b,7
				ld hl,&52e4
				ld (@+start_pos2+1),hl
				ld de,0
				ld iy,@+ret2
@loop2:
	@start_pos2: ld sp,0
				ld hl,128
				add hl,sp
				ld (@-start_pos2+1),hl
				for 37,push de
	@ret2:
				djnz @-loop2

	@rest_sp:	ld sp,0
				ret

;----------------------------------------------
attract.print_logo:
	@pos:		ld hl,logo.data
				inc hl
				inc hl
				ld (@-pos+1),hl
				dec hl
				dec hl

				ld b,2
	@get_coords:
				ld a,(hl)
	@test_term_token:
				cp -1
				jr nz,@+skip
		@reset:
				ld hl,logo.data
				ld (@-pos+1),hl
				call attract.fetch_new
				ret
		@skip:
				push bc
				ld e,a
				inc hl
				ld d,(hl)
				inc hl
				push hl

				ld c,e
				ld b,d
				ex de,hl
				add hl,hl
				add hl,hl
				add hl,bc
				ld bc,&0444
				add hl,bc
				ex de,hl

				call attract.print_block
				pop hl
				pop bc
				djnz @-get_coords

				call attract.push_start.update
				di
				call attract.push_start.clear
				ei
				call attract.push_start.print
				ret

logo.data:
; coords of the TETRIS logo.  Gets printed over many frames
				db 0,0

				db 0,0,1,0,2,0,1,1
				db 1,2,1,3,1,4,1,5

				db 4,0,5,0,6,0,4,1
				db 4,2,4,3,5,3,6,3
				db 4,4,4,5,5,5,6,5

				db 8,0,9,0,10,0,9,1
				db 9,2,9,3,9,4,9,5

				db 12,0,13,0,12,1,12,2
				db 14,0,14,1,14,2,14,3
				db 12,3,12,4,13,4,12,5

				db 14,5

				db 16,0,17,0,18,0,17,1
				db 17,2,17,3,17,4,17,5

				db 16,5,18,5

				db 20,0,21,0,22,0,20,1
				db 20,2,20,3,21,3,22,3
				db 22,4,22,5,21,5,20,5

				db 20,5

				db -1

attract.print_block:
; Print block in Tetris logo.
				push hl
				push de
				push bc
				push af

				srl d
				rr e
				jp c,@+print_block2				; If carried, print to odd x-coord

				ld hl,gfx.data+68
				ld a,6
	@loop:
				push af
				ld b,3
		@loop2:
				ld a,(de)
				or (hl)
				ld (de),a
				inc hl
				inc de
				djnz @-loop2

				ld bc,128-3
				add hl,bc
				ex de,hl
				add hl,bc
				ex de,hl

				pop af
				dec a
				jp nz,@-loop

				pop af
				pop bc
				pop de
				pop hl
				ret
@print_block2:
				ld hl,gfx.data+71
				ld a,6
	@loop:
				push af
				ld b,4
		@loop2:
				ld a,(de)
				or (hl)
				ld (de),a
				inc hl
				inc de
				djnz @-loop2

				ld bc,128-4
				add hl,bc
				ex de,hl
				add hl,bc
				ex de,hl

				pop af
				dec a
				jp nz,@-loop

				pop af
				pop bc
				pop de
				pop hl
				ret

;----------------------------------------------
attract.outline_logo:
	@counter:	ld a,255
				inc a
				ld (@-counter+1),a
				cp 66
				jp nz,@+print
	@reset:
				ld a,255
				ld (@-counter+1),a
				call attract.fetch_new
				ret

	@print:
				srl a
				ld de,60
				push af
				call maths.multADE
				pop af
				add 3
				ld d,a
				ld e,&42
				srl d
				rr e

				ld bc,options.logo_data
				add hl,bc
				ld bc,60
				ldir

				call attract.push_start.update
				di
				call attract.push_start.clear
				ei
				call attract.push_start.print
				ret

logo.fore_cols:
				db 1,2,3,5,7,8,9,10,11,12,13,14,15,-1

;----------------------------------------------
attract.pause_flash:
				call attract.push_start.update
				di
				call attract.push_start.clear
				ei
				call attract.push_start.print
				jp attract.pause

;----------------------------------------------
attract.print_creds:
; print credits screen
	@counter:	ld a,3
				dec a
				ld (@-counter+1),a
				jp nz,@+print
	@reset:
				ld a,3
				ld (@-counter+1),a
				call attract.fetch_new
				ret
	@print:
				ld hl,attract.credits.msg
				call font.print_string.colHL
				ret

;----------------------------------------------
attract.print_keys:
; print current keys screen
	@counter:	ld a,3
				dec a
				ld (@-counter+1),a
				jp nz,@+print
	@reset:
				ld a,3
				ld (@-counter+1),a
				call attract.fetch_new
				ret
	@print:
				ld hl,attract.keys.msg
				call font.print_string.colHL
				ret

;----------------------------------------------
attract.wipe_down:
; Wipe lower screen in 12 frames
	@counter:	ld a,12*2+1
				dec a
				ld (@-counter+1),a
				jr z,@+reset
	@clear_down:
				neg
				add 12*2+1
				call @+clear
				ret
@reset:
				ld a,12*2+1
				ld (@-counter+1),a
				call attract.fetch_new
				ret

attract.end_wipe:
; Final wipe down - not part of attract sequence piano roll.
	@counter:	ld a,12*2+1
				dec a
				ld (@-counter+1),a
				jr z,@+reset
	@clear_down:
				neg
				add 12*2+1
				call @+clear
				ret
@reset:
				ld a,12*2+1
				ld (@-counter+1),a
				ret

attract.wipe_up:
; Wipe lower screen in 12 frames
	@counter:	ld a,12*2+1
				dec a
				ld (@-counter+1),a
				jr nz,@+clear
@reset:
				ld a,12*2+1
				ld (@-counter+1),a
				call attract.fetch_new
				ret

@clear:
				inc a
				srl a
				ld l,0
				ld h,a
				ld c,l
				ld b,h
	@mult13:
				add hl,hl
				add hl,bc
				add hl,hl
				add hl,hl
				add hl,bc

				ld a,36
				add h
				ld h,a

				srl h
				rr l

				ld (@+rest_sp+1),sp
				ld sp,hl
				ld b,13
				ld de,&0000
	@loop:
				for 64,push de
				dec b
				jp nz,@-loop

	@rest_sp:	ld sp,0
				ret

attract.clear_upper:
				ld b,2
@loop:
				push bc
	@clear:
				ld hl,0
				ld de,1
				ld bc,37*128
				ld (hl),0
				ldir
				call house.swap_screens

				pop bc
				djnz @-loop

				call attract.fetch_new
				ret

;----------------------------------------------
attract.roll_demo:
; Run the rolling demo
				ld a,keys.mode.demo
				ld (keys.mode),a
				ld a,On
				ld (demo.mode.on),a
				call demo.reset_input
				call demo.reset_tet
				call demo.reset_timer

				call main.game_start

				call attract.demo_off

				call attract.reset
				pop hl
				call main.attract_mode

attract.demo_off:
				ld a,keys.mode.normal
				ld (keys.mode),a
				ld a,Off
				ld (demo.mode.on),a
				ret

;----------------------------------------------
attract.compile_start:
; Compile quick print version of PRESS START flashing icon
	@stb_palette:
				ld hl,stb.palette+15
				ld bc,4344
				otdr
	@print_sign:
				call font.set_simple
				ld hl,@+test_msg
				call font.print_string.colHL
	@compress_line_space:
				ld de,9*128
				ld hl,13*128
				ld bc,12*128
				ldir
	@outline:
				ld b,%01011010
				ld c,&f
				ld hl,&0202
				ld de,&1591
				ld ix,@+col_list
				call gfx.outlineIXHLDEBC

				ld b,%00000010
				ld c,1
				ld hl,&0201
				ld de,&1692
				ld ix,@+col_list2
				call gfx.outlineIXHLDEBC
	@grab_data:
				call build.start

				call house.clear_screens
				ret

@test_msg:
				db &99,2,2
				dm "   FIRE TO PLAY"
				db cr
				dm "ESCAPE FOR OPTIONS"
				db eof

@col_list:		db &9,255
@col_list2:		db &9,&f,255

