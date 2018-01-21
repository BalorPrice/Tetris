; MUSIC


music.jump_table: equ 253 						; Jump table sits at 253*256=64768
music.base:		equ 254 						; Handler    sits at 254*257=65278 258 bytes spare (253 bytes spare between table and handler)


music.src:
;++++++++++++++++++++++++++++++++++++++++++++++
				org 0
				dump MusicPage,0
				
music.data0:	mdat "music/intro1.raw"			; Compiled Protracker files
music.data1:	mdat "music/intro2.raw"
music.data2:	mdat "music/tanakatune.raw"
music.data3:	mdat "music/gameover.raw"
music.data4:	mdat "music/gameon.raw"
music.data5:	mdat "music/goexplode.raw"					

				ds 32
music.stack:	ds 1							; Simcoupe's monitor can't work out which label to use if I overload one address

music.play2:
				call music.output
				ld a,(music.speed)
	@loop:
				push af
				call music.process
				pop af
				dec a
				jr nz,@-loop
				call music.attenuate			; attentuate music before SFX overlaid
				
				ld a,(music.speed)
				cp 2
				ret nz
	@octave_up:
				ld a,(music.table+12)
				add &11
				ld (music.table+12),a
				ld a,(music.table+13)
				add &11
				ld (music.table+13),a
				ld a,(music.table+14)
				add &11
				ld (music.table+14),a
				ret		
				
				include "player.asm"			; player routine by Andrew Collier

;----------------------------------------------
music.attenuate:
; Set music volume for all channels.
	@prep_volume:
				ld c,0
				ld a,(music.on)					; Use volume as 0 if music is not on
				cp On
				jr nz,@+skip
	@prep_fade:
				ld a,(music.fade.on)
				cp On
				jr nz,@+no_fade
		@fade:
				ld a,(music.fade.timer)
				or a							; If timer run out, keep volume at 0
				jr z,@+skip
				dec a
				ld (music.fade.timer),a
				ld e,a
				ld d,0
				ld a,(music.volume)
				call maths.multADE
		@round:
				sla l
				jr nc,@+noround
				inc h
		@noround:
				ld c,h
				jr @+skip
				
		@no_fade:
				ld a,(music.volume)
				ld c,a
		@skip:
				
				ld de,music.table
				ld h,music.volume_table/256
				ld a,6
@loop:
				ex af,af'
	@left_channel:
				ld a,(de)
				and %11110000
				add c
				ld l,a
				ld a,(hl)
				for 4,add a
				ld b,a
	@right_channel:
				ld a,(de)
				for 4,add a
				add c
				ld l,a
				ld a,(hl)
	@output:
				or b
				ld (de),a
	@next:
				inc de
				ex af,af'
				dec a
				jr nz,@-loop
				ret

				ds align 256
music.volume_table:
				db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
				db 0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
				db 0,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2
				db 0,1,1,1,1,1,1,1,2,2,2,2,2,3,3,3
				db 0,1,1,1,1,1,2,2,2,2,3,3,3,3,4,4
				db 0,1,1,1,1,2,2,2,3,3,3,4,4,4,5,5
				db 0,1,1,1,2,2,2,3,3,4,4,4,5,5,6,6
				db 0,1,1,1,2,2,3,3,4,4,5,5,6,6,7,7
				db 0,1,1,2,2,3,3,4,4,5,5,6,6,7,7,8
				db 0,1,1,2,2,3,4,4,5,5,6,7,7,8,8,9
				db 0,1,1,2,3,3,4,5,5,6,7,7,8,9,9,10
				db 0,1,1,2,3,4,4,5,6,7,7,8,9,10,10,11
				db 0,1,2,2,3,4,5,6,6,7,8,9,10,10,11,12
				db 0,1,2,3,3,4,5,6,7,8,9,10,10,11,12,13
				db 0,1,2,3,4,5,6,7,7,8,9,10,11,12,13,14
				db 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15
				
				org music.src
				dump MainPage,music.src-32768
				
;++++++++++++++++++++++++++++++++++++++++++++++
music.lut:
; Lookup table for start addresses of each piece of music
music.intro1:	equ 0							; Gameboy main introduction music (with a touch of extra flavour)
				dw music.data0
music.intro2: 	equ 1							; Tetris DX (gameboy color version) rolling demo music
				dw music.data1
music.tanaka: 	equ 2							; Hirokazu Tanaka's tune (gameboy B music)
				dw music.data2
music.game_over: equ 3							; Tetrix DX ending music
				dw music.data3
music.game_on:	equ 4							; Player start noise in Protracker
				dw music.data4
music.go_explode: equ 5							; Game over explosion
				dw music.data5
music.korobushka: equ 6							; Korobeiniki / Korobushka (main gameboy famous tune)
				dw music.data6

music.lengths:	dw 2550,1925,0,0,35,100,0		; lengths of non-looping songs, in frames
				
;----------------------------------------------
music.table:	equ SOUNDTABLE 					; Protracker SOUNDTABLE offset
music.output:	equ PLAYROUTINE					; Tweaked Protracker playback routine.  Send output to chip
music.process:	equ AFTERSOUNDCHIP				; Process next Protracker frame.
music.setup:	equ STARTPLAYER					; Protracker prep tune call address

music.medley.len: equ 10000						; Length to play a tune before moving to next one in a medley (5 minutes)

music.on:		db On							; Set to on if music can be played
music.playing:	db On							; Set to on if current music has not run out
music.volume:	db 15							; 0-15 for overall music volume.  Envelopes don't cope well with volume 1
music.fade.on:	db Off							; Set to On if currently fading out (only one speed possible)
music.fade.timer: db 0
music.curr_len:	dw 120							; Length in frames of current music length, 0 for looping forever
music.curr_time: dw 0							; How long in frames current music has been playing
music.speed:	db 0							; speed 2 indicates double tempo and octave up for urgent music
music.curr_tune: db 0							; Currently playing music from music.lut
music.int_mode:	db int_mode.attract				; int_mode.attract or int_mode.game.  Attract mode uses extra line interrupt for palette change

int_mode.attract:	equ -1						; Interrupt modes:  .attract has a palette change at line 37
int_mode.game:		equ -2						; .game only needs music/sfx play and keyboard read at frame interrupt
int_mode.scroll:	equ -3						; .scroll is very tight on time, all extraneous stuff is ignored

;----------------------------------------------
music.off:
; Stop sound, but don't reset everything
@volume_down:									; Turn all volumes to 0
				ld bc,511
				ld d,5
				xor a
	@loop:
				call sfx.soundDA
				dec d
				jr nz,@-loop
	@envelopes_off:								; Envelopes don't respond to volume setting after already on
				ld d,24
				xor a
				call sfx.soundDA
				inc d
				call sfx.soundDA
				ret

;----------------------------------------------
music.setA:
; Set up tune A to play
				ld (music.curr_tune),a			; Save tune number
	@paging:									; Page music player into LMPR
				ex af,af'
				in a,(LMPR)
				ld (@+rest_lo+1),a
				ld a,MusicPage+32
				out (LMPR),a
				ex af,af'
				
	@find_offset:								; Get offset through tables
				add a
				ld e,a
				ld d,0
	@get_tune_addr:								; Get compiled music address
				ld hl,music.lut
				add hl,de
				ld c,(hl)
				inc hl
				ld b,(hl)
				ld (music.setup+1),bc
	@reset_timers:
				ld hl,music.lengths				; Get length from table
				add hl,de
				ld c,(hl)
				inc hl
				ld b,(hl)
				
				ld a,c							; set play routine check for looping forever
				or b
				ld (music.loop+1),a
				ld (music.curr_len),bc
				
				ld hl,0							; Reset current playing time in frames
				ld (music.curr_time),hl
				ld a,On							; Set music to currently playing
				ld (music.playing),a
				
				call music.setup
				ld a,1
				ld (music.speed),a
				
	@reset_fade:								; Reset settings and timings for fade out
				ld a,Off
				ld (music.fade.on),a
				ld a,255
				ld (music.fade.timer),a
				
	@rest_lo:	ld a,0
				out (250),a
				ret

;----------------------------------------------
music.set_modeA:
; Set interrupt mode for int_mode.game (just interrupt on frame int) or int_mode.attract (extra interrupt at line 37 for palette change)
				ld (music.int_mode),a
				cp int_mode.scroll
				jp nz,@+normal
	@scroll:
				ld hl,music.int_music.tight
				ld (music.int_jump+1),hl
				ld a,255
				out (StatusReg),a
				ret
	@normal:
				ld hl,music.int_music
				ld (music.int_jump+1),hl
				cp int_mode.attract
				ld a,37
				jr z,@+skip
				ld a,255
	@skip:
				out (StatusReg),a
				ret
				
;----------------------------------------------
music.play:
; Play a frame of currently-selected music.
@page_in:
				in a,(LMPR)
				ld (@+rest_lo+1),a
				ld a,MusicPage+32
				out (LMPR),a
				
				ld a,(music.speed)
				ld e,a							; E contains speed (1 or 2)
@test_length:									; If length is listed, check length before playing
	music.loop:	ld a,0
				or a
				jp nz,@+test_end				; If length=0, always play
@play_forever:
	@test_medley:								; If medley mode and timer run out, swap to other music
				ld a,(options.music.tune)
				cp options.tune.medley
				jr nz,@+skip
				ld a,(music.speed)				; Also, don't change music when in urgent music
				cp 2
				jr z,@+skip
				ld hl,(music.curr_time)
				ld bc,music.medley.len
				sbc hl,bc
				jr c,@+test_fade
		@swap:
				ld e,music.tanaka
				ld a,(music.curr_tune)
				cp music.korobushka
				jp z,@+next
				ld e,music.korobushka
		@next:
				ld a,e
				call music.setA
				jr @+update_timer
				
		@test_fade:								; Test for time remaining as 256, if so start fade
				ld a,h
				cp -1
				jr nz,@+skip
				ld a,l
				or a
				jr nz,@+skip
				ld a,Yes
				ld (music.fade.on),a
				
	@skip:
				call music.play2
				jr @+update_timer
				
@test_end:										; Test if music still playing
				ld hl,(music.curr_time)
				ld bc,(music.curr_len)
				sbc hl,bc
				jp nz,@+play
	@turn_off:									; If not playing, set variable for sfx to drive chip directly
				ld a,Off
				ld (music.playing),a
				call music.off
				jr @+update_timer
	@play:										; If playing, update music and timer 
				call music.play2
				
@update_timer:
				ld hl,(music.curr_time)
				inc hl
				ld (music.curr_time),hl
				
@page_out:
	@rest_lo:	ld a,0
				out (250),a
				ret

;----------------------------------------------
music.set_volA:
; Set music volume 0-15.  Envelopes don't play properly at volume 1.
@page_in:
				ex af,af'
				in a,(250)
				ld (@+rest_lo+1),a
				ld a,MusicPage+32
				out (250),a
				ex af,af'
				
				ld (music.volume),a
@page_out:
				ex af,af'
	@rest_lo:	ld a,0
				out (250),a
				ex af,af'
				ret

;----------------------------------------------
music.get_vol:
; Get music volume
@page_in:
				in a,(250)
				ld (@+rest_lo+1),a
				ld a,MusicPage+32
				out (250),a
				
				ld a,(music.volume)
@page_out:
				ex af,af'
	@rest_lo:	ld a,0
				out (250),a
				ex af,af'
				ret

;----------------------------------------------
music.setup_im2:
; Make IM2 mode for the music and SFX player routines				
				di
				im 2
				
	@set_interrupt_register:
				ld a,music.jump_table
				ld i,a
	@populate_vector_table:
				ld h,a
				ld l,0
				ld (hl),music.base				; Jump table will send interrupt to 65278, 258 bytes spare at upper memory
				ld e,1
				ld d,h
				ld bc,256
				ldir
	@reset_frame:								; Set only interrupt to be frame
				ld a,255
				out (StatusReg),a
	@reset_frame_flag:
				ld a,No
				ld (frame.elapsed),a
				ret

;++++++++++++++++++++++++++++++++++++++++++++++			
music.src2:
				dump MainPage,music.base*257-32768
				org music.base*257
music.int_rout:
; music and sound effects maintenance routine.  Called every frame
				di
				
				push af
				push bc
				push de
				push hl
				push ix
				push iy
				exx
				ex af,af'
				push af
				push bc
				push de
				push hl
music.int_jump:
				jp music.int_music
music.int_ret:
				pop hl
				pop de
				pop bc
				pop af
				ex af,af'
				exx
				pop iy
				pop ix
				pop hl
				pop de
				pop bc
				pop af
				
				ei
				ret
				
music.int_music:
; interrupt routine called on frame interrupt
	@set_frame_elapsed:
				ld a,Yes
				ld (frame.elapsed),a
				call house.set_curr_palette
				call keys.input
				
				call maths.rand
				call @update_speed
				
				call music.play
				call sfx.update.out
				
	@test_mode:
				ld a,(music.int_mode)
				cp int_mode.game
				jp z,music.int_ret
				
	@set_interrupt:
				ld hl,music.int_palette
				ld (music.int_jump+1),hl
				ld a,34
				out (StatusReg),a
				jp music.int_ret
				
@update_speed:
; urgent stack height speed changer
				ld a,(music.speed)			; Different thresholds based on current mode
				cp 1
				ld a,(curr.stack.height)
				jr nz,@check_urgent
	@check_normal:
				cp urgent_stack_height
				ret c
				ld a,2
				ld (music.speed),a
				ret
	@check_urgent:							; Have to get a bit lower to slow speed down, stops lots of changes
				cp urgent_stack_height-2
				ret nc
				ld a,1
				ld (music.speed),a
				ret

music.int_music.tight:
; music play interrupt mode when timing is tight
	@set_frame_elapsed:
				ld a,Yes
				ld (frame.elapsed),a
				call keys.input
				call music.play
				jp music.int_ret
				
music.int_palette:
; interrupt routine called in attract sequence when split palette showing
				call attract.set_stb_pal 
	@set_interrupt_elapsed:
				ld a,Yes
				ld (interrupt.elapsed),a
	@set_interrupt:
				ld hl,music.int_music
				ld (music.int_jump+1),hl
				ld a,255
				out (StatusReg),a
				jp music.int_ret
				
				
				dump MainPage,music.src2-32768
				org music.src2
;++++++++++++++++++++++++++++++++++++++++++++++
