; HEADS-UP DISPLAY

;----------------------------------------------
next_tet.width:	equ 8*4/2-1
next_tet.depth:	equ 16

hud.right_panel:
; List of rectangles X,Y,width,height,and colour values
				db 188,24,250,176,black*&11
				db 184,20,246,172,blue*&11
				db 186,22,244,170,dark_grey*&11
				db 182,18,0
				db 240,18,0
				db 182,166,0
				db 240,166,0

				db 84,24,180,176,black*&11

				db 8,24,76,176,black*&11
				db 4,20,72,172,blue*&11
				db 6,22,70,170,dark_grey*&11
				db 2,18,0
				db 66,18,0
				db 2,166,0
				db 66,166,0

				db -1,-1

hud.stats_data_blocks:
				db tet.j,6,28
				db tet.z,6,38
				db tet.o,4,48
				db tet.s,6,58
				db tet.l,2,68
				db tet.i,4,78
				db tet.t,6,18
				db -1

hud.panel.data:
				db pink*&11,192,95
				dm "SCORE"
				db cr,cr
				dm "LEVEL"
				db cr,cr
				dm "LINES"
				db eof
hud.panel.data2:
				db red*&11,192,96
				dm "SCORE"
				db cr,cr
				dm "LEVEL"
				db cr,cr
				dm "LINES"
				db eof
hud.panel.data3:
				db yellow*&11,192,92
				db cr
				dm "000000"
				db cr,cr
				dm "00"
				db cr,cr
				dm "0000"
				db eof

hud.next.data:
				db pale_green*&11,200,&18
				dm "NEXT"
				db eof
hud.next.data2:
				db green*&11,200,&19
				dm "NEXT"
				db eof

hud.stats.data:
				db pale_blue*&11,20,24
				dm "STATS"
				db eof

hud.stats.data2:
				db blue*&11,20,25
				dm "STATS"
				db eof

hud.go_msg:
				db red*&11,100,36
				dm "GAME"
				db cr
				dm "  OVER"
				db eof

hud.go_msg3:
				db orange*&11,100,37
				dm "GAME"
				db cr
				dm "  OVER"
				db eof
hud.go_msg2:
				db white*&11,100,104
				dm "PLEASE"
				db cr
				dm "  TRY"
				db cr
				dm " AGAIN"
				db eof
hud.go_msg4:
				db pale_blue*&11,100,105
				dm "PLEASE"
				db cr
				dm "  TRY"
				db cr
				dm " AGAIN"
				db eof

;----------------------------------------------
hud.init:
	@clear_scores_data:
				ld hl,curr.lines
				ld de,curr.lines+1
				ld (hl),0
				ld bc,19						; !!! Magic number: length of the stats data - 1
				ldir
	@place_score_terminator:
				ld hl,curr.score+6
				ld (hl),eof
	@reset_score:
				ld hl,0
				ld (curr.score.bin),hl
				ld (curr.score.bin+1),hl
				ret

hud.update:
				call hud.print_score
				call hud.print_lines
				call hud.print_level
				call hud.print_next_tet
				call stats.print_all			; Only reprint stats that have changed
				ret

;----------------------------------------------
hud.print_next_tet:
; print next tetronimo.  This is very hacky but there you go
	@clear:
				ld hl,&1228+60					; ! Magic number warnings
				ld de,&1228+61
				ld a,next_tet.depth
	@loop:
				ld (hl),dark_grey*&11
				ld bc,next_tet.width
				ldir
				ld bc,128-next_tet.width
				add hl,bc
				ex de,hl
				add hl,bc
				ex de,hl
				dec a
				jp nz,@-loop

	@print:
				ld a,(tet.next.type)
				ld bc,0
				ld iy,&050f						; !
				ld de,0
				call gfx.print_tetAIYBCDE
				ret

hud.print_panelIX:
				ld l,(ix)
				inc ix
				ld h,(ix)
				inc ix
				ld a,l
				and h
				cp -1
				ret z
				ld e,(ix)
				inc ix
				ld a,e
				cp 0
				jp z,@+print_block
	@print_rect:
				ld d,(ix)
				inc ix
				ld a,(ix)
				inc ix
				call gfx.print_byte_rectHLDEA
				jp hud.print_panelIX
	@print_block:
				ex de,hl
				call gfx.print_pyramidDE
				jp hud.print_panelIX

;----------------------------------------------
hud.print_first:
; Print all the HUD display stuff for the first time.
				call font.set_masked

				ld b,2
	@loop:
				push bc

				ld ix,hud.right_panel
				call hud.print_panelIX
				ld hl,hud.next.data2
				call font.print_string.colHL
				ld hl,hud.next.data
				call font.print_string.colHL
				ld hl,hud.panel.data2
				call font.print_string.colHL
				ld hl,hud.panel.data
				call font.print_string.colHL
				ld hl,hud.panel.data3
				call font.print_string.colHL
				ld hl,hud.stats.data2
				call font.print_string.colHL
				ld hl,hud.stats.data
				call font.print_string.colHL
				call @+print_stats_blocks

				call house.swap_screens

				pop bc
				djnz @-loop

				call font.set_simple
				ret

@print_stats_blocks:
; Print the statistics blocks on the left and move into position.
				ld ix,hud.stats_data_blocks
	@loop:											; Check data for end marker
				ld a,(ix)
				cp -1
				jp z,@+end

				call @+clear_block					; Clear the initial block place at top of list

	@print:											; Print block to initial position
				ld iy,&04f8
				ld bc,0
				ld de,0
				call gfx.print_tetAIYBCDE
	@move:											; Collect destination position and copy screen data
				ld hl,&1208
				ld e,(ix+1)
				ld d,(ix+2)
				call @+move_block
				for 3,inc ix
				jp @-loop
	@end:											; Clear detritus under top block
				ld hl,&1212
				call @blank
				ld hl,&160e
				call @blank
				ret

@clear_block:
				push af
				ld hl,&1208							; ! Magic numbers
				ld de,&1209
				ld a,16
		@loop:
				ld (hl),0
				ld bc,15
				ldir
				ld bc,128-15
				add hl,bc
				ex de,hl
				add hl,bc
				ex de,hl
				dec a
				jp nz,@-loop
				pop af
				ret

@move_block:
				ld a,16
	@loop:
				ex af,af'
				ld bc,16
		@loop2:
				ld a,(hl)
				or a
				jp z,@+next
				ld (de),a
		@next:
				inc l
				inc e
				dec c
				jp nz,@-loop2

				ld bc,128-16
				add hl,bc
				ex de,hl
				add hl,bc
				ex de,hl
				ex af,af'
				dec a
				jp nz,@-loop
				ret

@blank:
				xor a
				ld (hl),a
				inc l
				ld (hl),a
				inc h
				ld (hl),a
				dec l
				ld (hl),a
				inc h
				ld (hl),a
				inc l
				ld (hl),a
				inc h
				ld (hl),a
				dec l
				ld (hl),a
				ld bc,128
				add hl,bc
				ld (hl),a
				inc l
				ld (hl),a
				dec h
				ld (hl),a
				dec l
				ld (hl),a
				dec h
				ld (hl),a
				inc l
				ld (hl),a
				dec h
				ld (hl),a
				dec l
				ld (hl),a
				ret

;----------------------------------------------
hud.print_score:
; Translate curr.score into ascii and print
; NB VERY hacky - the final bug I was prepared to fix before releasing.
	@test:										; Only print if score changed in the last two frames
				ld a,(curr.score.dirty)
				or a
				ret z
				dec a
				ld (curr.score.dirty),a

	@get_score:									; Make a copy of current score to play with
				ld hl,curr.score.bin
				ld de,@curr_score
				for 3,ldi

	@test_digits:
				ld de,@curr_score				; Do a repeated 3-byte subtract, Current score - 100000 to find this digit
				ld hl,@+num100000
				call @+get_big_digit
				ld (curr.score),a

				ld de,@curr_score				; Repeat with remainder to find 10000s
				ld hl,@+num10000
				call @+get_big_digit
				ld (curr.score+1),a

				ld de,@curr_score
				ld hl,@+num1000
				call @+get_big_digit
				ld (curr.score+2),a

				ld de,@curr_score
				ld hl,@+num100
				call @+get_big_digit
				ld (curr.score+3),a

				ld de,@curr_score
				ld hl,@+num10
				call @+get_big_digit
				ld (curr.score+4),a

				ld de,@curr_score
				ld hl,@+num1
				call @+get_big_digit
				ld (curr.score+5),a

	@print:
				call font.set_simple
				ld a,yellow*&11
				call font.set_colA
				ld de,&68c0
				ld hl,curr.score
				call font.print_stringHLDE
				ret

@curr_score:	db &10,&27,&00,0
@num100000:		db &a0,&68,&01				; 100000 in little-endian
@num10000:		db &10,&27,&00				; etc
@num1000:		db &e8,&03,&00
@num100:		db &64,&00,&00
@num10:			db &0a,&00,&00
@num1:			db &01,&00,&00

@get_big_digit:
				ld c,"0"
	@loop:
				ld ix,(@curr_score)
				ld iy,(@curr_score+2)
	@sub_big:
				ld a,(de)
				and a
				sub (hl)
				ld (de),a
				inc de
				inc hl
				ld a,(de)
				sbc (hl)
				ld (de),a
				inc de
				inc hl
				ld a,(de)
				sbc (hl)
				jr c,@+restore
				ld (de),a
				dec de
				dec hl
				dec de
				dec hl
				inc c
				jr @-loop
	@restore:								; When carried, ignore last subtract
				ld (@curr_score+2),iy		; Put back last whole operation to @curr_score
				ld (@curr_score),ix
				ld a,c						; Return with A=ASCII digit for this decimal cardinal
				ret

hud.add_scoreA:
; Add points to current score where A=number of lines
				call @+turn_score_dirty
	@convert_lines:							; Translate number of lines into base score
				ld de,40					; (level-1)*40 for one line.  100 for two lines etc
				cp 1
				jp z,@+mult_level
				ld de,100
				cp 2
				jp z,@+mult_level
				ld de,300
				cp 3
				jp z,@+mult_level
				ld de,1200
	@mult_level:							; multiply by level+1
				ld a,(curr.level)
				inc a
				ld c,a
				ld b,0
				call maths.multDEBC
				call @+add_scoreHL
				ret

@turn_score_dirty:
; Set score to reprint for next two frames
				ld hl,curr.score.dirty
				ld (hl),2
				ret

@add_scoreHL:
; Add HL to current score and put in score as 24-bit number
				ld de,(curr.score.bin)		; Add to current score
				add hl,de
				ld (curr.score.bin),hl
				ret nc
				ld hl,curr.score.bin+2
				inc (hl)
				ret

hud.inc_score:
; Increase score by one
				push de
				push hl
				call @-turn_score_dirty
				ld hl,1
				call @-add_scoreHL
				pop hl
				pop de
				ret

;----------------------------------------------
hud.print_lines:
	@test:										; Only print if score changed in the last two frames
				ld a,(curr.lines.dirty)
				or a
				ret z
				dec a
				ld (curr.lines.dirty),a

		@test_bright:
				cp 2
				ld a,orange*&11
				jp nc,@+next
				ld a,yellow*&11
		@next:
				call font.set_colA

				ld b,4
				ld hl,curr.lines
				ld de,&98c0
	@loop:
				push bc

				ld a,(hl)
				add "0"
				push hl
				push de
				call font.print_char
				pop de
				ld a,8
				add e
				ld e,a
				pop hl
				inc hl

				pop bc
				djnz @-loop
				ret

hud.inc_linesA:
; Increase lines by A
				push af
				push bc
				push hl

				push af
	@turn_lines_dirty:
				ld hl,curr.lines.dirty
				ld (hl),16

				ld hl,curr.lines+3
				add (hl)
				ld (hl),a
				cp 10
				jp c,@+end
				sub 10
				ld (hl),a
				dec hl

				call hud.inc_level

				ld a,9
				ld b,2
	@loop:
				inc (hl)
				cp (hl)
				jp nc,@+end
				ld (hl),0
				dec hl
				djnz @-loop
	@end:
				pop af
				call hud.add_scoreA

				pop hl
				pop bc
				pop af
				ret

;----------------------------------------------
hud.print_level:
	@test:
				ld a,(curr.level.dirty)
				or a
				ret z
				dec a
				ld (curr.level.dirty),a

		@test_bright:							; If level just became dirty then print brighter version
				cp 2
				ld a,red*&11
				jp nc,@next
				ld a,yellow*&11
		@next:
				call font.set_colA

				ld b,2
				ld hl,curr.level
				ld de,&80c0
	@loop:
				push bc

				ld a,(hl)
				add "0"
				push hl
				push de
				call font.print_char
				pop de
				ld a,8
				add e
				ld e,a
				pop hl
				inc hl

				pop bc
				djnz @-loop
				ret

hud.inc_level:
; Increase level by one
				push af
				push bc
				push hl

	@check_top_level:							; Doesn't go up if level 30
				ld hl,(curr.level)
				ld bc,&3033						; = level 30 in two ascii characters
				and a
				sbc hl,bc
				jp z,@+end

	@turn_level_dirty:							; Set level number to print for next 2 frames
				ld hl,curr.level.dirty
				ld (hl),16
	@speed_up:									; Drop speed speeds up by 2 frames per level
				ld a,(drop_spd)
				sub 2
				cp 4
				jp p,@+next
				ld a,4
		@next:
				ld (drop_spd),a

	@update_level:
				ld hl,curr.level.bin			; Update actual level number
				inc (hl)

				ld hl,curr.level+1				; Update printed characters
				inc (hl)
				ld a,9
				cp (hl)
				jp nc,@+set_palette
				ld (hl),0
				dec hl
				inc (hl)

	@set_palette:								; Change palette colour of background if increased 5 levels
				ld a,(curr.level.bin)
				ld l,a
				ld h,0
				ld c,5
				call maths.divHLC
				ld de,gfx.level.colours
				add hl,de
				ld a,(hl)
				ld (house.palette+8),a

	@play_sfx:
				ld c,sfx.level_up
				call sfx.setC.out
	@end:
				pop hl
				pop bc
				pop af
				ret

;----------------------------------------------
hud.print_game_over:
; Print game over message
				push af

				ld hl,&2064
				ld de,&48a2
				ld a,dark_grey*&10+black
				call gfx.print_byte_rectHLDEA
				ld hl,&1b60
				ld de,&439e
				ld a,white*&10+pale_green
				call gfx.print_byte_rectHLDEA

				ld hl,&6064
				ld de,&98a2
				ld a,dark_grey*&10+black
				call gfx.print_byte_rectHLDEA
				ld hl,&5b60
				ld de,&939e
				ld a,dull_purple*&10+brown
				call gfx.print_byte_rectHLDEA

				call font.set_masked

				ld hl,hud.go_msg3
				call font.print_string.colHL
				ld hl,hud.go_msg
				call font.print_string.colHL
				ld hl,hud.go_msg4
				call font.print_string.colHL
				ld hl,hud.go_msg2
				call font.print_string.colHL

				ld b,gfx.heart
				ld hl,&1245
				call gfx.print_block_maskedBHL
				ld b,gfx.heart
				ld hl,&3a34
				call gfx.print_block_maskedBHL

				pop af
				ret
