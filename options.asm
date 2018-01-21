; OPTIONS MENU

; Palette change to recover
; Unbuffer screen for this area

;----------------------------------------------
options.msg2:
				db orange*&11,60,45
				dm "     OPTIONS"
				db eof
options.msg:									; Main menu structure
				db white*&11,60,44
				dm "     OPTIONS"
				db cr,cr,orange
				dm "RETURN"
				db cr
				dm "REDEFINE KEYS"
				db cr
				dm "MUSIC"
				db cr,pale_blue
				dm " VOLUME"
				db cr
				dm " TUNE"
				db cr,orange
				dm "SFX"
				db cr,pale_blue
				dm " VOLUME"
				db eof
				
				
options.on.msg:									; Generic on/off messages
				db white
				dm "ON"
				db blue
				dm "/"
				db orange
				dm "OFF"
				db eof
				
options.off.msg:
				db orange
				dm "ON"
				db blue
				dm "/"
				db white
				dm "OFF"
				db eof

				
options.music.tanaka.msg:						; Labels for tunes types available
				dm "TANAKA'S TUNE"
				db eof
options.music.korobushka.msg:
				dm "KOROBUSHKA"
				db eof
options.music.medley.msg:						; This should swap between tunes every few rounds
				dm "MEDLEY"
				db eof

;----------------------------------------------
options.tune.lut:
; Lookup table to find tune titles in ASCII form, and value to put in main.game_music 
@korobushka:	equ 0
				dw options.music.korobushka.msg
				db music.korobushka
@tanaka:		equ 1
				dw options.music.tanaka.msg
				db music.tanaka
@medley:		equ 2
options.tune.medley: equ 2
				dw options.music.medley.msg
				db music.korobushka				; Start with Korobushka
				
options.music.tune: db @medley					; Current music type
options.heart.y: db 1							; Current selection 0-6

options.functions.lut:
; Lookup table of functions when option selected, for moving left, right and pressing rotate
				dw options.nothing,options.return,options.return						; Return
				dw options.nothing,options.redefine,options.redefine					; Redefine keys
				dw options.set_music_on,options.set_music_off,options.toggle_music		; Music on/off
				dw options.music_vol_down,options.music_vol_up,options.music_vol_up_loop; Music volume
				dw options.tune_down,options.tune_up,options.tune_up_loop				; Music tune
				dw options.set_sfx_on,options.set_sfx_off,options.toggle_sfx			; SFX on/off
				dw options.sfx_vol_down,options.sfx_vol_up,options.sfx_vol_up_loop		; SFX volume
				
;----------------------------------------------
options.start:
; Invoked on attract mode when escape is pressed
				ld a,int_mode.game
				call music.set_modeA
				call house.double_buffer.off
				ld hl,house.palette
				call house.set_paletteHL
				call house.set_curr_palette
				call options.clear
				call options.print_logo
				xor a
				ld (options.heart.y),a
				call options.print_menu				
	@loop:
				call house.wait_frame_im2
				call options.reprint_heart
				ld a,(keys.processed)
				bit Escape,a
				jp nz,options.end
				bit Down,a
				call nz,options.down
				bit Up,a
				call nz,options.up
				bit Left,a
				call nz,@+function_left
				bit Right,a
				call nz,@+function_right
				bit RotateC,a
				call nz,@+function_fire
				bit RotateAC,a
				call nz,@+function_fire
				
				jp @-loop
				
	options.end:
				call house.double_buffer.on
				call house.clear_screens
				call attract.init
				di
				ld a,int_mode.attract
				call music.set_modeA
				ei
				pop hl
				jp main.attract.loop
				
@function_left:
				ld e,0
				jp @+process_function
@function_right:
				ld e,2
				jp @+process_function
@function_fire:
				ld e,4
@process_function:
				push af
				ld a,(options.heart.y)
				ld d,a
				add a
				add d
				add a
				add e
				ld e,a
				ld d,0
				ld hl,options.functions.lut
				add hl,de
				ld e,(hl)
				inc hl
				ld d,(hl)
				ld (@+addr+1),de
	@addr:		call 0
				pop af
				ret
				
;----------------------------------------------				
options.clear:
; clear lower portion of screen
				ld hl,37*128
				ld de,37*128+1
				ld (hl),0
				ld bc,(192-37)*128-1
				ldir
				ret

;----------------------------------------------
options.prep_logo:
; Make simple version of logo for printing when options screen is displayed
				ld hl,logo.data				
	@print_logo_loop:
				ld a,(hl)
	@test_term_token:
				cp -1
				jr z,@+outline
				
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
				call house.pal_up
				pop hl
				jp @-print_logo_loop
				
@outline:
				ld hl,&0442						; !  More magic numbers
				ld de,&23b8
				ld c,white
				ld b,%01011010
				ld ix,logo.fore_cols
				call gfx.outlineIXHLDEBC
				
@grab:
				ld a,33
				ld hl,&0342/2
				ld de,options.logo_data
	@yloop:
				push hl
				ld bc,60
				ldir
				call house.pal_up
				pop hl
				ld bc,128
				add hl,bc
				dec a
				jr nz,@-yloop
				
				call house.clear_screens
				ret

options.print_logo:
; Print logo for options menu, from previously cached copy
				ld de,&0342/2
				ld hl,options.logo_data
				ld a,33
	@yprint:
				ld bc,60
				ldir
				
				ld bc,128-60
				ex de,hl
				add hl,bc
				ex de,hl
				dec a
				jr nz,@-yprint
				ret

options.logo_data:
				ds 33*60
				
;----------------------------------------------
options.print_menu:
	@print_main:
				call font.set_masked
				ld hl,options.msg2
				call font.print_string.colHL
				ld hl,options.msg
				call font.print_string.colHL
				call font.set_simple
				call options.pick_tune
	@print_music_on:
				ld a,(music.on)
				ld de,&5c7c
				call @+print_onADE
	@print_music_vol:
				call music.get_vol
				ld de,&687c
				call @+print_volADE
	@print_sfx_on:
				ld a,(sfx.on)
				ld de,&807c
				call @+print_onADE
	@print_sfx_vol:
				ld a,(sfx.volume)
				ld de,&8c7c
				call @+print_volADE
				ret

;----------------------------------------------
options.pick_tune:
; Select the current tune, set to initiate, reprint title
	@clear_title:
				ld hl,&747c/2
				ld de,(&747c/2)+1
				ld a,7
		@loop:
				ld (hl),0
				ld bc,13*4-1
				ldir
				ld bc,128-(13*4)+1
				add hl,bc
				ex de,hl
				add hl,bc
				ex de,hl
				dec a
				jr nz,@-loop
				
				ld a,(options.music.tune)
				ld e,a
				add a
				add e
				ld e,a
				ld d,0
				ld hl,options.tune.lut
				add hl,de
				ld e,(hl)
				inc hl
				ld d,(hl)
				inc hl
	@store_current_tune:
				ld a,(hl)
				ld (main.game_music+1),a
				ex de,hl
	@print_tune_message:
				ld a,pale_blue
				call font.set_colA
				ld de,&747c
				call font.print_stringHLDE
				ret

;----------------------------------------------				
@print_onADE:
; Print on/off message mirroring A, to coords DE
				ld hl,options.on.msg
				cp On
				jp z,@+skip
				ld hl,options.off.msg
		@skip:
				call font.print_stringHLDE
				ret

;----------------------------------------------				
@print_volADE:
; Print volume graphic to volume A, to coords DE
				srl d
				rr e
				ex de,hl
				
				inc a
				ld c,a
				ld b,15
				ld a,white*&10
	@loop:
				dec c
				jp nz,@+skip
		@turn_off:
				ld a,orange*&10
		@skip:
				call @+print_bar
				inc hl
				djnz @-loop
				ret
				
@print_bar:
				push bc
				push hl
				
				ld b,7
				ld de,128
	@loop:
				ld (hl),a
				add hl,de
				djnz @-loop
				
				pop hl
				pop bc
				ret

;----------------------------------------------
options.reprint_heart:
	@clear:
		@prev_pos: ld hl,0
				ld e,l
				ld d,h
				inc e
				ld a,8
		@loop:
				ld (hl),0
				for 3,ldi
				ld bc,128-3
				add hl,bc
				ex de,hl
				add hl,bc
				ex de,hl
				dec a
				jp nz,@-loop
	@print:
				ld a,(options.heart.y)
				ld b,a
				add a
				add b
				add a
				add &22
				ld h,a
				ld l,&19
				ld (@-prev_pos+1),hl
				ld b,gfx.heart
				call gfx.print_blockBHL
				ret

;----------------------------------------------
options.down:
; Move down selected option if available
				push af
				ld a,(options.heart.y)
				cp 6
				jr z,@+end
				inc a
				ld (options.heart.y),a
	@end:
				pop af
				ret
				
options.up:
				push af
				ld a,(options.heart.y)
				or a
				jr z,@+end
				dec a
				ld (options.heart.y),a
	@end:
				pop af
				ret

;----------------------------------------------
; Functions supporting the menu

options.nothing:								; Some keypresses are ignored
				ret
				
options.return:
; Return to main attract sequence
				for 3,pop hl					; Junk three levels of call instructions
				jp options.end
				
options.redefine:
; Jump to redefine keys routine
				call keys.redefine
	@clear_lower:
				ld hl,38*128
				ld de,38*128+1
				ld (hl),0
				ld bc,(192-38)*128-1
				ldir
				jp options.return
				
				
options.set_music_on:
; Turn music on
				push af
				ld a,On
				ld (music.on),a
				ld de,&5c7c
				call @-print_onADE
				pop af
				ret
				
options.set_music_off:
; Turn music off
				push af
				ld a,Off
				ld (music.on),a
				ld de,&5c7c
				call @-print_onADE
				pop af
				ret
				
options.toggle_music:
; If fire pressed, assume toggle between options
				push af
				ld a,(music.on)
				xor &ff
				ld (music.on),a
				
				ld de,&5c7c
				call @-print_onADE
				pop af
				ret

options.music_vol_down:
; Reduce volume if possible, send to global music volume setting, reprint graphic
				push af
				call music.get_vol
				or a
				jr z,@+end
				dec a
	@check_vol1:								; Volume 1 is silent for envelope voices, so skip this setting
				cp 1
				jr nz,@+skip
				dec a
	@skip:
				call music.set_volA
				ld de,&687c
				call @-print_volADE				
	@end:
				pop af
				ret

options.music_vol_up:
; Increase volume if possible
				push af
				call music.get_vol
				cp 15
				jr z,@+end
				inc a
	@check_vol1:
				cp 1
				jr nz,@+skip
				inc a
	@skip:
				call music.set_volA
				ld de,&687c
				call @-print_volADE				
	@end:
				pop af
				ret
				
options.music_vol_up_loop:
; Increase volume unless we're at the maximum, then reset to 0
				push af
				call music.get_vol
				cp 15
				jr nz,@+skip
	@reset:
				ld a,-1
	@skip:
				inc a
	@check_vol1:
				cp 1
				jr nz,@+skip
				inc a
	@skip:
				call music.set_volA
				ld de,&687c
				call @-print_volADE
				pop af
				ret

options.set_sfx_on:
; Turn SFX on, reprint graphic, make sound effect to reflect this
				push af
				ld a,On
				ld (sfx.on),a
				ld de,&807c
				call @-print_onADE
				ld c,sfx.move_side
				call sfx.setC.out
				pop af
				ret
				
options.set_sfx_off:
; Turn SFX off, no sound effect this time
				push af
				ld a,Off
				ld (sfx.on),a
				ld de,&807c
				call @-print_onADE
				pop af
				ret
				
options.toggle_sfx:
; Toggle sound effect value.  Sound effect won't sound if turned off
				push af
				ld a,(sfx.on)
				xor &ff
				ld (sfx.on),a
				ld de,&807c
				call @-print_onADE
				
				ld c,sfx.move_side
				call sfx.setC.out
				pop af
				ret
				
options.sfx_vol_down:
; Reduce SFX volume if possible, reprint graphic, and make sound to give feedback to player
				push af
				ld a,(sfx.volume)
				or a
				jr z,@+end
				dec a
				ld (sfx.volume),a
				ld de,&8c7c
				call @-print_volADE				
	@end:
				ld c,sfx.move_side
				call sfx.setC.out
				
				pop af
				ret

options.sfx_vol_up:
; Increase SFX volume if possible
				push af
				ld a,(sfx.volume)
				cp 15
				jr z,@+end
				inc a
				ld (sfx.volume),a
				ld de,&8c7c
				call @-print_volADE				
	@end:
				ld c,sfx.move_side
				call sfx.setC.out
				
				pop af
				ret
				
options.sfx_vol_up_loop:
; Volume up unless we're at the top, then reset to 0
				push af
				ld a,(sfx.volume)
				cp 15
				jr nz,@+skip
	@reset:
				ld a,-1
	@skip:
				inc a
	@check_vol1:
				cp 1
				jr nz,@+skip
				inc a
	@skip:
				ld (sfx.volume),a
				ld de,&8c7c
				call @-print_volADE
				
				ld c,sfx.move_side
				call sfx.setC.out
				
				pop af
				ret

options.tune_down:
; Swap to previous tune option (only two tunes and 'medley' available), set to play, reprint tune title
				push af
				ld a,(options.music.tune)
				or a
				jr z,@+end
				dec a
				ld (options.music.tune),a
				call options.pick_tune
	@end:
				pop af
				ret
				
options.tune_up:
; Swap to next tune option.
				push af
				ld a,(options.music.tune)
				cp 2
				jr z,@+end
				inc a
				ld (options.music.tune),a
				call options.pick_tune
	@end:
				pop af
				ret
				
options.tune_up_loop:
; Swap to next tune option unless at final choice, then loop to start
				push af
				ld a,(options.music.tune)
				cp 2
				jr nz,@+skip
	@reset:
				ld a,-1
	@skip:
				inc a
				ld (options.music.tune),a
				call options.pick_tune
				pop af
				ret
