; FONT PRINTING
;
;	font.print_string			Print string.  HL->Message, terminated with EOF.  (E,D) coords.  Font A
;	font.print_stringHL			Print string with header.  Byte 0=font number.  Byte 1: X coord, byte 2: Y coord
;	font.print_string.colHLDE	Print string colourised...... !!! Add instructions
; 	font.print_char				Print single character A at (E,D), with current font
;	font.print_hex_byteDEA		Print A as hex byte, at DE
;	font.print_hex_wordHLDE		Print HL as hex word, at DE

eof:			equ 255
cr:				equ 13
quote:			equ 34
cr_depth:		equ 12							; How many pixels down a carriage return executes

;----------------------------------------------
font.data:
				mdat "font.raw"
font.data.end:

;----------------------------------------------
font.set_masked:
				ld hl,@+masked_print
				ld (@+print_type+1),hl
				ret

font.set_simple:
				ld hl,@+simple_print
				ld (@+print_type+1),hl
				ret

font.set_colA:
				ld c,a
				for 4,add a
				or c
				ld (@+colour_val+1),a
				ret

font.print_string.colHL:
; printing with colourised text
				ld a,(hl)
				ld (@+colour_val+1),a			; Use font data as mask, AND with colour needed
				inc hl

font.print_stringHL:
; Extra print string stuff
				ld e,(hl)						; Get coords to print at
				inc hl
				ld d,(hl)
				inc hl

font.print_stringHLDE:
; Print string at HL, at coords DE.
				push de
	@chr_loop:
	@get_chr:
				ld a,(hl)
				inc hl
	@check_end_token:
				cp eof
				jp z,@+quit
	@check_CR_token:
				cp cr
				jp nz,@+skip_cr
	@carriage_return:
				pop de
				ld a,cr_depth
				add d
				ld d,a
				push de
				jp @-chr_loop
	@skip_cr:
				call font.print_char
				jp @-chr_loop
	@quit:
				pop de
				ret


font.print_stringHLDEB:
; Print B characters from string at HL, at coords DE.
				push de
	@chr_loop:
				push bc
	@get_chr:
				ld a,(hl)
				inc hl
	@check_end_token:
				cp eof
				jp z,@+quit
	@check_CR_token:
				cp cr
				jp nz,@+skip_cr
	@carriage_return:
				pop de
				ld a,cr_depth
				add d
				ld d,a
				push de
				jp @+next_chr
	@skip_cr:
				call font.print_char
	@next_chr:
				pop bc
				djnz @-chr_loop
				pop de
				ret
	@quit:
				pop bc
				pop de
				ret
;----------------------------------------------
font.print_char:
; Print ASCII character A at DE
	@test_space:
				cp " "
				jp nz,@+print
		@space:
				ld a,8
				add e
				ld e,a
				ret
	@print:
				cp 16
				jp nc,@+next
		@set_colour:
				call font.set_colA
				ret
		@next:
				push de
				push hl
	@get_src_data:								; Find source graphic data from ascii code
				sub " "
				add a
				ld l,a
				ld h,0
				ld bc,font.ascii_table
				add hl,bc
				ld a,(hl)
				inc hl
				ld h,(hl)
				ld l,a

	@find_screen_address:						; Translate coords into screen address
				srl d
				rr e

				ld b,7
	@colour_val: ld c,0							; mask colour value
	@print_loop:								; Print 7*5 character
				push bc

				ld b,4
	@char_loop:


	@print_type: call @+masked_print

				inc hl
				inc de
				djnz @-char_loop

				ld bc,128-4						; 96= width of the font grab data
				add hl,bc
				ld bc,128-4
				ex de,hl
				add hl,bc
				ex de,hl
				pop bc
				djnz @-print_loop

	@end_letter:
				pop hl
				pop de
	@next_letter_pos:
				ld a,8
				add e
				ld e,a
				ret

@simple_print:
				ld a,(hl)
				and c							; Colourise each byte
				ld (de),a
				ret

@masked_print:
				push bc
	@top_pix:
				ld a,(hl)
				and %11110000
				jp nz,@+colour
	@background:
				ld a,(de)
				and %11110000
				jp @+next
	@colour:
				and c
	@next:
				ld b,a
	@bottom_pix:
				ld a,(hl)
				and %00001111
				jp nz,@+colour
	@background:
				ld a,(de)
				and %00001111
				jp @+next
	@colour:
				and c
	@next:
				or b
				ld (de),a

				pop bc
				ret

;----------------------------------------------
font.print_hex_byteDEA:
; Print A as a hexadecimal number, at coords DE
				push af
	@top_nibble:
				for 4,rra
				and %00001111
				ld c,a
				ld b,0
				ld hl,font.hex_string
				add hl,bc
				ld a,(hl)
				call font.print_char
	@bottom_nibble:
				pop af
				and %00001111
				ld c,a
				ld b,0
				ld hl,font.hex_string
				add hl,bc
				ld a,(hl)
				call font.print_char
				ret

font.print_hex_wordHLDE:
; Print HL as a hexadecimal number, at coords DE
				push hl
				ld a,h
				call font.print_hex_byteDEA
				pop hl
				ld a,l
				call font.print_hex_byteDEA
				ret

font.hex_string: dm "0123456789ABCDEF"
;----------------------------------------------

font.ascii_table:
				dw 0							; space
				dw font.data+1088				; !
				dw font.data+1076				; "
				dw 0							; £
				dw 0							; $
				dw 0							; %
				dw 0							; &
				dw font.data+1072				; '
				dw font.data+1100				; (
				dw font.data+1104				; )
				dw 0							; *
				dw font.data+112				; +
				dw font.data+1068 				; ,
				dw font.data+104				; -
				dw font.data+1084				; .
				dw font.data+1080				; /
				dw font.data+1024				; 0
				dw font.data+1028				; 1
				dw font.data+1032				; 2
				dw font.data+1036				; 3
				dw font.data+1040				; 4
				dw font.data+1044				; 5
				dw font.data+1048				; 6
				dw font.data+1052				; 7
				dw font.data+1056				; 8
				dw font.data+1060				; 9
				dw font.data+108				; :
				dw 0							; ;
				dw font.data+1064				; <	(c) symbol
				dw 0							; =
				dw 0							; >
				dw font.data+1092				; ?
				dw font.data+1096 				; @
				dw font.data+0					; A
				dw font.data+4					; B
				dw font.data+8					; C
				dw font.data+12					; D
				dw font.data+16					; E
				dw font.data+20					; F
				dw font.data+24					; G
				dw font.data+28					; H
				dw font.data+32					; I
				dw font.data+36					; J
				dw font.data+40					; K
				dw font.data+44					; L
				dw font.data+48					; M
				dw font.data+52					; N
				dw font.data+56					; O
				dw font.data+60					; P
				dw font.data+64					; Q
				dw font.data+68					; R
				dw font.data+72					; S
				dw font.data+76					; T
				dw font.data+80					; U
				dw font.data+84					; V
				dw font.data+88					; W
				dw font.data+92					; X
				dw font.data+96					; Y
				dw font.data+100				; Z

font.data.len:	equ font.data.end-font.data

font.data.scrolled:
				ds font.data.len
