; PRESS START routine builder

;----------------------------------------------
@x_pos:			db 0
@y_pos:			db 0
@tally:			db 0
push_start.print: equ 24576						; Address to compile the routine at.

build.start:
; Make static graphic to print PRESS FIRE message
				call @build						; Build the routine once
				call @move						; Then move underneath both screens
				ret

@build:
				ld hl,push_start.print			; compile address
				ld de,128						; source data
	@set_start_pos:
				ld a,54
				ld (@x_pos),a
				ld a,154
				ld (@y_pos),a
				ld b,18							; depth in pixels
@y_loop:
				push bc
				call @comp_start_lineXY			; find start of this line

	@reset_tally:								; Tally in bytes to next position
				xor a
				ld (@tally),a

				push de
				ld b,150/2						; width loop
@x_loop:
				call house.pal_up
				push bc
				ld a,(de)						; Check each pixel
				or a
				call nz,@compile_printer		; If not empty, compile move-to this place and print it
	@inc_tally:									; Increase the distance to next printed byte
				ld a,(@tally)
				inc a
				ld (@tally),a

				inc e							; move to next byte to check
				pop bc
				djnz @-x_loop

	@down_line:									; Move to next source line down
				pop de

				ex de,hl
				ld bc,128
				add hl,bc
				ex de,hl

				pop bc							; Repeat for whole graphic
				dec b
				call nz,@line_down				; Only compile move down if another line is needed
				jr nz,@-y_loop
	@comp_ret:
				ld (hl),ret_					; Finish with a return after finished.
				inc hl

	@get_length:
				ld de,push_start.print
				and a
				sbc hl,de
				ret

@move:
; Copy the routine under the other screen
				push hl
				ld hl,build.move.src			; First move the copying code into the screen
				ld de,build.move
				ld bc,build.move.len
				ldir
				pop hl
				ld (build.start.len+1),hl		; Populate the length of the routine into the code
				call build.move					; Then call it
				ret

build.move.src:
				org 0
build.move:
	@page_out:									; Page other page into upper memory
				in a,(HMPR)
				ld (@+rest_hi+1),a
				ld a,ScreenPage2
				out (HMPR),a
	@copy:										; Copy the routine to the same address under the other screen
				ld hl,push_start.print
				ld de,push_start.print+32768
build.start.len: ld bc,0
				ldir

	@rest_hi:	ld a,0							; Restore upper page
				out (HMPR),a
				ret
build.move.end:

build.move.len:	equ build.move.end-build.move

				org build.move.src+build.move.len
;----------------------------------------------
@compile_printer:
; Print this byte
	@move_to_tally:								; Move to position
				push af
				ld a,(@tally)
				call @comp_moveA
				pop af
	@test_left:									; Test left nibble
				ld c,a
				and %11110000
				or a
				jr nz,@test_right				; If blank, print right nibble masked
				ld a,c
				call @comp_print_rpixA
				ret
	@test_right:								; If left contains data, test right
				ld a,c
				and %00001111
				or a
				ld a,c
				call z,@comp_print_lpixA		; If blank, print left pixel masked
				call nz,@comp_print_byteA		; Else print straight byte
				ret

@line_down:
				push af
				ld a,(@y_pos)
				inc a
				ld (@y_pos),a
				pop af
				ret


@comp_start_lineXY:
; Set start of line
; compile LD (HL),[x*128]+[y]
				ld a,(@y_pos)
				ld b,a
				ld a,(@x_pos)
				ld c,a
				srl b
				rr c
				ld (hl),ld_hl.nn
				inc hl
				ld (hl),c
				inc hl
				ld (hl),b
				inc hl
				ret

@comp_print_byteA:
; Print straight byte of data
; compile LD (HL),[A]
				ld (hl),ld_.hl..n
				inc hl
				ld (hl),a
				inc hl
				ret

@comp_print_lpixA:
; print left pixel masked
; compile LD A,(HL); AND B; OR [A]; LD (HL),A
				push af
				ld (hl),ld_a..hl.
				inc hl
				ld (hl),and_b
				inc hl
				ld (hl),or_n
				inc hl
				ld (hl),a
				inc hl
				ld (hl),ld_.hl..a
				inc hl
				pop af
				ret

@comp_print_rpixA:
; print right pixel masked
; compile LD A,(HL); AND C; OR [A]; LD (HL),A
				ld (hl),ld_a..hl.
				inc hl
				ld (hl),and_c
				inc hl
				ld (hl),or_n
				inc hl
				ld (hl),a
				inc hl
				ld (hl),ld_.hl..a
				inc hl
				ret

@comp_moveA:
; compile INC L, A times, unless L>=3, then do LD A,[A]; ADD L; LD L,A
; NB I could have just done LD L,n, but I currently don't keep track of the actual x-byte position.
				or a
				ret z
				cp 3
				jr nc,@+comp_big
@comp_small:
				ld b,a
	@loop:
				ld (hl),inc_l
				inc hl
				djnz @-loop

				xor a
				ld (@tally),a
				ret

@comp_big:
				ld (hl),ld_a.n
				inc hl
				ld (hl),a
				inc hl
				ld (hl),add_l
				inc hl
				ld (hl),ld_l.a
				inc hl

				xor a
				ld (@tally),a
				ret
