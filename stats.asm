;----------------------------------------------
; STATS

stats.data:										; Count of amount of each block used each game
@t:				db 0
@j:				db 0
@z:				db 0
@o:				db 0
@s:				db 0
@l:				db 0
@i:				db 0


stats.print_data:								; Printable version of the stats.data
@t:
				db orange*&11,44,38				; Colours, x, y
				dm "000"						; 3 digits in ASCII
				db eof,0						; End of message token, dirty marker
@j:
				db orange*&11,44,58
				dm "000"
				db eof,0
@z:
				db orange*&11,44,78
				dm "000"
				db eof,0
@o:
				db orange*&11,44,98
				dm "000"
				db eof,0
@s:
				db orange*&11,44,118
				dm "000"
				db eof,0
@l:
				db orange*&11,44,138
				dm "000"
				db eof,0
@i:
				db orange*&11,44,158
				dm "000"
				db eof,0

;----------------------------------------------
stats.translateAIX:
; Turn number in A to 3-digit message to output.  Return message in 3 bytes to (IX).
				ld c,100
				call @+find_digit
				ld (ix+3),b
				ld c,10
				call @+find_digit
				ld (ix+4),b
				ld c,1
				call @+find_digit
				ld (ix+5),b
				ret

@find_digit:
				ld b,"0"
	@loop:
				sub c
				jp c,@+end
				inc b
				jp @-loop
	@end:
				add c
				ret

;----------------------------------------------
stats.incA:
; Increase stats for tet A
				push af
	@update_data:								; Update real data position
				ld e,a
				ld d,0
				ld hl,stats.data
				add hl,de
				inc (hl)
	@find_msg:									; Find message data for this stat
				for 3,add a
				ld e,a
				ld d,0
				ld ix,stats.print_data
				add ix,de
	@set_dirty:									; Find changed stat and set print flag to next 2 frames
				ld (ix+7),2
	@translate:
				ld a,(hl)
				call stats.translateAIX

				pop af
				ret

;----------------------------------------------
stats.print_all:
; print all stats that have a print flag against them
				call font.set_simple			; Turn off any print masking

				ld b,7
				ld ix,stats.print_data
	@loop:
				push bc
		@test_print:							; If print flag is not zero, print and decrease this
				ld a,(ix+7)
				or a
				jp z,@+next
		@update:
				dec (ix+7)
		@reprint:
				ld a,ixh
				ld h,a
				ld a,ixl
				ld l,a
				call font.print_string.colHL
	@next:
				ld bc,8
				add ix,bc

				pop bc
				djnz @-loop
				ret

;----------------------------------------------
stats.reset:
; Clear all the stats for a new game
	@clear_data:								; Set data to -1
				ld hl,stats.data
				ld de,stats.data+1
				ld (hl),-1
				ld bc,6
				ldir

	@update_print_data:							; Loop through all blocks and increase to 0 for printing
				ld a,7
		@loop:
				push af
				dec a
				call stats.incA
				pop af
				dec a
				jp nz,@-loop
				ret
