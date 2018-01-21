; SOUND EFFECTS

; Taken directly from Thrust and repurposed

;----------------------------------------------
; Jump table for sound effect attack/decay/sustain part and release part
sfx.jump_table:
					dw 0,0
sfx.clear_tetris:	equ 4
					dw sfx.clear_tetris.dataADS, 0
sfx.clear_lines:	equ 8
					dw sfx.clear_lines.dataADS, 0
sfx.lock_tet:		equ 12
					dw sfx.lock_tet.dataADS, 0
sfx.move_side:		equ 16
					dw sfx.move_side.dataADS, 0
sfx.game_over:		equ 20						; Unused, Protracker was better for this
					dw sfx.game_over.dataADS, 0
sfx.move_down:		equ 24
					dw sfx.move_down.dataADS, 0
sfx.rotate:			equ 28
					dw sfx.rotate.dataADS, 0
sfx.level_up:		equ 32
					dw sfx.level_up.dataADS, 0

sfx.mode:			db @single_channel
@single_channel:	equ 0
@dual_channel:		equ 1

; Control characters
sfx.end:			equ -1
sfx.loop:			equ -2
sfx.ADS:			equ 0
sfx.R:				equ 2						; Add to a sound equate when calling sfx.setA to trigger its Release envelope
sfx.retriggerOK:	equ On
sfx.retriggerOff:	equ Off

; Slots structure
sfx.data.len:		equ 14
sfx.slots.count:	equ 16
sfx.data:			ds sfx.data.len*sfx.slots.count

@curr_sound.os:		equ 0						; Current sound playing.  0 for idle
@sound_pos.os:		equ 1						; Pointer to current sound data
@retrigger.os:		equ 3						; On/Off if restarting sound is allowed
@rand_pitch.os:		equ 4						; Modulus value to retrict overall pitch
@x_pos_addr:		equ 6						; Address of object's map X pos for panning
@sound_enable.os:	equ 8						; Main fundamental channel data
@noise_enable.os:	equ 9
@noise_type.os:		equ 10						; Main channel keeps noise data
@curr_freq.os:		equ 11
@curr_oct.os:		equ 12
@curr_vol.os:		equ 13

sfx.init.data:		for sfx.data.len, db 0		; Blank slot

;----------------------------------------------
sfx.init.out:
; Only required if Protracker music is not playing
				ld bc,511
	@reset_SAA:
				ld d,&1c
				ld a,2
				call sfx.soundDA
	@turn_on_SAA:
				dec a
				call sfx.soundDA
				ret

sfx.soundDABC:
				ld bc,511
sfx.soundDA:
				out (c),d
				dec b
				out (c),a
				inc b
				ret

;----------------------------------------------
sfx.setC.out:
; Start new sound effect C.  Set bit 7 for release part of sound, reset for ADS part.
; HL points to 16-bit x-pos map coord of object creating noise, for live panning
	@check_sfx_on:
				ld a,(sfx.on)
				cp On
				ret nz

				push ix
				push iy
				push hl
	@find_new_slot:								; Find spare slot to process sound
				ld ix,sfx.data
				ld de,sfx.data.len
				ld b,sfx.slots.count
				xor a
	@find_slot_loop:
				cp (ix)
				jp z,@+success
	@next_slot:
				add ix,de
				djnz @-find_slot_loop
	@failure:
				pop hl
				pop iy
				pop ix
				ret

@success:
	@find_data:									; Find source data
				ld b,0
				ld hl,sfx.jump_table
				add hl,bc
				ld e,(hl)
				inc hl
				ld d,(hl)
				ex de,hl

	@test_retrigger:							; If playing a unique sound (only one possible at once) check it's not already playing elsewhere
				ld a,(hl)
				and %11000000
				jp z,@+set_sound
		@find_sound:
				ld iy,sfx.data
				ld de,sfx.data.len
				ld a,c
				and %11111101					; Ignore Release bit for now
				ld b,sfx.slots.count
		@find_sound_loop:
				cp (iy)
				jp z,@+check_release
			@next_slot:
				add iy,de
				djnz @-find_sound_loop
				jp @+set_sound
		@check_release:							; If sound is found, if releasing then continue, update this slot
				bit 1,c
				jp z,@+quit
		@update_slot:
				push iy
				pop ix
	@set_sound:
				ld (ix+@curr_sound.os),c
	@set_retrigger:
				ld e,(hl)
				inc hl
				xor a
				sla e
				rla
				sla e
				rla
				ld (ix+@retrigger.os),a
	@set_sound_enable:
				xor a
				sla e
				rla
				sla e
				rla
				ld (ix+@sound_enable.os),a
	@set_noise_enable:
				xor a
				sla e
				rla
				sla e
				rla
				ld (ix+@noise_enable.os),a
	@set_noise_type:
				xor a
				sla e
				rla
				sla e
				rla
				ld (ix+@noise_type.os),a
	@set_rand_val:								; Get randomize pitch size
				ld a,(hl)
				inc hl
				ld (@+rand_size+1),a
	@end:
				ld (ix+@sound_pos.os),l
				ld (ix+@sound_pos.os+1),h
	@prep_rand:									; Make variation on pitch for each sound effect
				call maths.rand
				ld a,(maths.seed)
	@rand_size: and 0
				ld l,a
				ld h,0
				srl a
				ld e,a
				ld d,0
				and a
				sbc hl,de
				ld (ix+@rand_pitch.os),l
				ld (ix+@rand_pitch.os+1),h
	@set_x_pos:
				pop hl
				ld (ix+@x_pos_addr),l
				ld (ix+@x_pos_addr+1),h
				pop iy
				pop ix
				ret
	@quit:
				pop hl
				pop iy
				pop ix
				ret

;----------------------------------------------
sfx.update.out:
; Update all sound effects and output
	@check_sfx_on:
				ld a,(sfx.on)
				cp On
				ret nz

				push ix
				push iy
	@page_in:
				ex af,af'
				in a,(LMPR)
				ld (@+rest_lo+1),a
				ld a,MusicPage+32
				out (LMPR),a
				ex af,af'

				call @process_effects
	; @check_mode:								; Check mode to see how many sounds output
				; ld a,(sfx.mode)
				; cp @single_channel
				call @outputIY
				; cp @dual_channel
				; call z,@outputIYIX

	@rest_lo:	ld a,0
				out (LMPR),a

				pop iy
				pop ix
				ret

;----------------------------------------------
@process_effects:
; Process each effect separately, return with IY=>loudest sound, IX=>2nd loudest
				ld ix,sfx.data
				ld iy,sfx.init.data				; Set iy to loudest sound, start in a blank sfx record
				ld de,sfx.init.data
				ld b,sfx.slots.count
	@update_loop:
				push bc
		@check_active:
				ld a,(ix+@curr_sound.os)
				or a
				jp z,@+next_slot
		@update:
				push de
				call sfx.updateIX
				pop de
		@test_volume:							; If loudest noise so far, point IY to it to play
				ld a,(iy+@curr_vol.os)
				cp (ix+@curr_vol.os)
				jp nc,@+next_slot
		@update_loudest_sound:
				ld e,iyl						; Use D'E' for 2nd loudest sound
				ld d,iyh
				push ix							; Use IY for loudest sound
				pop iy
		@next_slot:
				ld bc,sfx.data.len
				add ix,bc
				pop bc
				djnz @-update_loop

				ld ixl,e
				ld ixh,d
				ret

;----------------------------------------------
sfx.updateIX:
; Update sound effect at IX
	@get_current_pos:
				ld l,(ix+@sound_pos.os)
				ld h,(ix+@sound_pos.os+1)
	@test_live:									; If end token found, turn sound off and reset retrigger
				ld a,(hl)
				cp sfx.end
				jp nz,@+test_loop
	@deactivate_sfx:
				ld (ix+@curr_sound.os),0
				ret
	@test_loop:									; If loop token found, reset position counter and reread
				cp sfx.loop
				jp nz,@+read_pitch
	@apply_loop:
				inc hl
				ld e,(hl)
				inc hl
				ld d,(hl)
				ex de,hl
				jp @-test_live
	@read_pitch:
				ld d,(hl)
				inc hl
				ld e,(hl)
				inc hl
	@add_randomness:
				push hl
				ld l,(ix+@rand_pitch.os)
				ld h,(ix+@rand_pitch.os+1)
				add hl,de
				ld (ix+@curr_oct.os),h
				ld (ix+@curr_freq.os),l
				pop hl
	@read_volume:
				ld a,(demo.mode.on)				; If demo mode on, no sound effects please
				cp On
				ld a,0
				jr z,@+skip
				ld a,(hl)
		@skip:
				call sfx.attenuateA				; Apply overall sfx volume
				inc hl
				ld (ix+@curr_vol.os),a
	@store_pos:
				ld (ix+@sound_pos.os),l
				ld (ix+@sound_pos.os+1),h
				ret

;----------------------------------------------
sfx.volume:		db 15

sfx.attenuateA:
; Set sfx volume for all channels.
				push bc
				push de
				push hl

				ld d,a
				ld a,(sfx.volume)
				ld c,a
				ld h,sfx.volume_table/256
@loop:
	@left_channel:
				ld a,d
				and %11110000
				add c
				ld l,a
				ld a,(hl)
				for 4,add a
				ld b,a
	@right_channel:
				ld a,d
				for 4,add a
				add c
				ld l,a
				ld a,(hl)
	@output:
				or b

				pop hl
				pop de
				pop bc
				ret

				ds align 256
sfx.volume_table:
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

;----------------------------------------------
@outputIY:
; Output single loudest sound effect to channel A
				push af

@output_protracker:
	@test_sfx_playing:
				ld a,(iy+@curr_vol.os)			; If loudest volume is 0 then don't overwrite channel
				or a
				jp z,@+end

	@set_sound_enable:
				ld a,(music.table+15)
				or %00100000
				ld (music.table+15),a
	@set_noise_enable:
				ld a,(music.table+16)
				and %00011111
				ld e,a
				ld a,(iy+@noise_type.os)
				for 2,rrca
				or e
				ld (music.table+16),a
	@set_octave:
				ld a,(music.table+14)
				and %00001111
				ld e,a
				ld a,(iy+@curr_oct.os)
				for 4,add a
				or e
				ld (music.table+14),a
	@set_frequency:
				ld a,(iy+@curr_freq.os)
				ld (music.table+11),a
	@get_volume:
				ld a,(iy+@curr_vol.os)			; Apply panning to volume before outputting
				; ld l,(iy+@x_pos_addr)
				; ld h,(iy+@x_pos_addr+1)
				; call sfx.panEHL
				ld (music.table+5),a
	@end:
				pop af
				ret

;----------------------------------------------
; @outputIYIX:
; ; Output loudest sound effect to channel A, second loudest to channel D (2nd variable pitch noise generator)
				; ld bc,&01ff
	; @sound_enable:
				; ld a,(ix+@sound_enable.os)		; Merge outputs for sound/noise enable and noise type
				; for 3,add a
				; or (iy+@sound_enable.os)
				; ld d,&14
				; call sfx.soundDA
	; @noise_enable:
				; ld a,(ix+@noise_enable.os)
				; for 3,add a
				; or (iy+@noise_enable.os)
				; ld d,&15
				; call sfx.soundDA
	; @noise_type:
				; ld a,(ix+@noise_type.os)
				; for 4,add a
				; or (iy+@noise_type.os)
				; ld d,&16
				; call sfx.soundDA
	; @octaves:
				; ld a,(iy+@curr_oct.os)
				; ld d,&10
				; call sfx.soundDA
				; ld a,(ix+@curr_oct.os)
				; for 4,add a
				; ld d,&11
				; call sfx.soundDA
	; @frequencies:
				; ld a,(iy+@curr_freq.os)
				; ld d,&08
				; call sfx.soundDA
				; ld a,(ix+@curr_freq.os)
				; ld d,&0b
				; call sfx.soundDA
	; @volumes:
				; ld e,(iy+@curr_vol.os)			; Apply panning to volume before outputting
				; ld l,(iy+@x_pos_addr)
				; ld h,(iy+@x_pos_addr+1)
				; call sfx.panEHL
				; ld d,&00
				; call sfx.soundDABC

				; ld e,(ix+@curr_vol.os)			; Apply panning to volume before outputting
				; ld l,(ix+@x_pos_addr)
				; ld h,(ix+@x_pos_addr+1)
				; call sfx.panEHL
				; ld d,&03
				; call sfx.soundDABC
				; ret

;----------------------------------------------
sfx.panEHL:
; Pan mono volume E to X-position in HL.  Return volume in A
	; @test_pan_on:
				; ld a,e					; If both nibbles same, pan sound, otherwise just output it
				; for 4,rlca
				; cp e
				; jp z,@+panned_sound
				; ld a,e
				; ret

	@panned_sound:
				push hl
		; @get_x_pos:						; Find distance from camera to sound source x position
				; ld a,(hl)
				; inc hl
				; ld h,(hl)
				; ld l,a
		; @find_scr_x_coord:
				; ld bc,(tet.curr.pos.x) 	;(camera.x_pos)
				; and a
				; sbc hl,bc
		; @test_onscreen:					; If onscreen pan normally
				; ld a,h
				; or a
				; jp z,@+on_screen
				; bit 7,h					; If offscreen, reduce volume
				; jp nz,@+off_screen_right
		; @off_screen_left:
				; ld a,e
				; and %00001110
				; for 3,add a
				; jp @+next
		; @off_screen_right:
				; ld a,e
				; and %00001110
				; srl a
				; add 15
				; jp @+next
		@on_screen:
				ld a,e
				for 4,add a
				add 8
				; for 4,srl l
				; add l
		@next:
				ld l,a
				ld h,Pantable/256
				ld a,(hl)
				pop hl
				ret

;Pan data.  Precalculated sine wave power law.
				ds align 256
PanTable:		db  0, 0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
				db  1, 1,  1,  1, 17, 17, 17, 17, 17, 17, 17, 17, 16, 16, 16, 16
				db  2,18, 18, 18, 18, 18, 18, 17, 17, 33, 33, 33, 33, 33, 33, 32
				db 19,19, 19, 19, 35, 34, 34, 34, 34, 34, 34, 50, 49, 49, 49, 49
				db 20,20, 36, 36, 35, 35, 51, 51, 51, 51, 50, 50, 66, 66, 65, 65
				db 21,37, 37, 36, 52, 52, 52, 52, 67, 67, 67, 67, 66, 82, 82, 81
				db 22,38, 38, 53, 53, 69, 69, 68, 68, 84, 84, 83, 83, 98, 98, 97
				db 23,39, 54, 54, 70, 70, 69, 85, 85, 84,100,100, 99, 99,114,113
				db 24,40, 55, 71, 71, 86, 86, 86,101,101,101,116,116,115,130,129
				db 41,57, 72, 72, 88, 87,103,103,118,118,117,133,132,132,147,146
				db 42,58, 73, 89, 88,104,104,119,119,134,134,133,149,148,163,162
				db 43,58, 74, 90,105,105,120,136,136,135,150,150,165,164,163,178
				db 44,75, 91,107,106,122,137,137,152,152,167,166,182,181,180,194
				db 45,76, 92,107,123,139,138,153,153,168,184,183,182,197,196,210
				db 46,77,109,124,124,139,155,170,170,185,184,199,199,214,212,226
				db 63,94,110,125,141,156,172,171,186,202,201,216,215,230,229,243

;----------------------------------------------
sfx.example.dataADS:
; Attack-Decay-Sustain data
				db %01000101,0			; Header format: retrigger, sound_en, noise_en, noise_type; pitch limiter
				db &00,&00,&11			; Main data
				db &00,&00,&22
	@loop:
				db &00,&00,&44
				db sfx.loop
				dw @-loop				; Finish with loop instruction if release data is going to join the sound together
sfx.example.dataR:
; Release data
				db %01000101,0
				db &03,&00,&33
				db &03,&00,&22
				db &03,&00,&11
				db sfx.end

;----------------------------------------------
sfx.clear_tetris.dataADS:
; 4 lines full winning effect
				db %00010100,%00001111
				db &05,&21,&ef
				db &05,&24,&fe
				db &05,&21,&ef
				db &05,&1c,&fe
				db &05,&20,&ef

				db &04,&c0,&ef
				db &04,&bc,&fe
				db &04,&c3,&ef
				db &04,&be,&fe
				db &04,&bf,&ef

				db &05,&21,&ef
				db &05,&24,&fe
				db &05,&21,&ef
				db &05,&1c,&fe
				db &05,&20,&ef

				db &04,&c0,&ef
				db &04,&bc,&fe
				db &04,&c3,&ef
				db &04,&be,&fe
				db &04,&bf,&ef

				db &03,&00,&ef
				db &03,&18,&fe
				db &03,&30,&ef
				db &03,&48,&fe
				db &03,&60,&ef
				db &03,&78,&fe
				db &03,&80,&ef
				db &03,&98,&fe
				db &03,&80,&ef
				db &03,&98,&fe
				db &03,&b0,&ef
				db &03,&b0,&fe
				db &03,&98,&ef
				db &03,&78,&fe
				db &03,&60,&ef
				db &03,&48,&fe
				db &03,&30,&ef
				db &03,&18,&fe
				db &03,&00,&ef

				db sfx.end


;----------------------------------------------
sfx.clear_lines.dataADS:
; Normal 1-3 lines winning effect
				db %00010000,0
				db &03,&40,&cd
				db &03,&60,&dc
				db &03,&80,&cd
				db &03,&a0,&dc
				db &03,&c0,&cd
				db &03,&e0,&dc

				db &03,&70,&cd
				db &03,&90,&dc
				db &03,&b0,&cd
				db &03,&d0,&dc
				db &03,&f0,&cd
				db &04,&10,&dc

				db &03,&a0,&cd
				db &03,&c0,&dc
				db &03,&e0,&cd
				db &04,&00,&dc
				db &04,&20,&cd
				db &04,&40,&dc

				db &03,&c0,&cd
				db &03,&e0,&dc
				db &04,&00,&cd
				db &04,&20,&dc
				db &04,&40,&cd
				db &04,&60,&dc
				db sfx.end

;----------------------------------------------
sfx.level_up.dataADS:
; Played when level increases
				db %00010000,0
				db &05,&51,&c9
				db &05,&41,&c9
				db &05,&31,&c9
				db &05,&21,&c9
				db &05,&21,&00
				db &05,&21,&00

				db &05,&84,&c9
				db &05,&84,&c9
				db &05,&84,&c9
				db &05,&84,&c9
				db &05,&84,&00
				db &05,&84,&00

				db &05,&c0,&c9
				db &05,&c0,&c9
				db &05,&c0,&c9
				db &05,&c0,&c9
				db &05,&c0,&00
				db &05,&c0,&00

				db &05,&55,&9c
				db &05,&55,&9c
				db &05,&55,&9c
				db &05,&55,&9c
				db &05,&55,&00
				db &05,&55,&00

				db &05,&ad,&9c
				db &05,&ad,&9c
				db &05,&ad,&9c
				db &05,&ad,&9c
				db &05,&ad,&00
				db &05,&ad,&00

				db &05,&e3,&9c
				db &05,&e3,&9c
				db &05,&e3,&9c
				db &05,&e3,&9c
				db &05,&e3,&00
				db &05,&e3,&00

				db &05,&84,&c9
				db &05,&84,&c9
				db &05,&84,&c9
				db &05,&84,&c9
				db &05,&84,&00
				db &05,&84,&00

				db &05,&d2,&c9
				db &05,&d2,&c9
				db &05,&d2,&c9
				db &05,&d2,&c9
				db &05,&d2,&00
				db &05,&d2,&00

				db &06,&05,&c9
				db &06,&05,&c9
				db &06,&05,&c9
				db &06,&05,&c9
				db &06,&05,&00
				db &06,&05,&00

				db sfx.end

;----------------------------------------------
sfx.lock_tet.dataADS:
; Thump when tet is finally locked into place
				db %00000111,%00111111
				db &05,&80,&dc
				db &05,&40,&cd
				db &04,&80,&bc
				db &04,&40,&ba
				db &03,&60,&98
				db &03,&20,&86
				db &02,&90,&57
				db sfx.end

;----------------------------------------------
sfx.move_side.dataADS:
; Twinkle when tet is moved left or right
				db %00010000,0
				db &05,&99,&45
				db &05,&99,&54
				db &05,&d2,&34
				db &05,&d2,&43
				db &05,&f3,&23
				db &05,&f3,&32
				db sfx.end

;----------------------------------------------
sfx.game_over.dataADS:
; Played as the screen fills up with blank tiles	 - not used in final version
				; db %00010100,%01111111
				; db &03,&e3,&66
				; db &03,&e0,&66
				; db &03,&f0,&66
				; db &03,&e8,&66
				; db &03,&e4,&66
				; db &03,&e0,&66
				; db &03,&db,&66
				; db &03,&da,&66
				; db &03,&d8,&66
				; db &03,&d3,&66
				; db &03,&d0,&66
				; db &03,&ca,&66
				; db &03,&c7,&66
				; db &03,&e3,&66
				; db &03,&e3,&66
				; db &03,&e3,&66
				; db &03,&e3,&66
				; db &03,&e3,&66
				; db &03,&e3,&66

				db sfx.end

;----------------------------------------------
sfx.move_down.dataADS:
; Thump when rest of blocks drop down after clearing any full lines
				db %00000111,%00111111
				db &03,&80,&ba
				db &03,&40,&ab
				db &02,&80,&78
				db &02,&40,&87
				db &01,&60,&56
				db &01,&40,&34
				db sfx.end

;----------------------------------------------
sfx.rotate.dataADS:
; Bigger twinkle when player rotates tet
				db %00010000,0
				db &05,&6d,&ab
				db &05,&f3,&98
				db &06,&6d,&78
				db &06,&f3,&87
				db &07,&6d,&67
				db &07,&f3,&76
				db &05,&6d,&78
				db &05,&f3,&87
				db &06,&6d,&67
				db &06,&f3,&75
				db &07,&6d,&45
				db &07,&f3,&43
				db &06,&6d,&32
				db &06,&f3,&12
				db &07,&6d,&21
				db &07,&f3,&12
				db sfx.end

;==============================================