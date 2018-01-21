;----------------------------------------------
; MATHS ROUTINES

;==============================================
; Pseudo-random number generator - by Jon Ritman, Simon Brattel, Neil Mottershead
; We don't need to know anything here, just that it works and returns a random 16-bit number in HL.

maths.seed:		dm "o}_/"						; Any seed will do

maths.rand:
				ld hl,(maths.seed+2)
				ld d,l
				add hl,hl
				add hl,hl
				ld c,h
				ld hl,(maths.seed)
				ld b,h
				rl b
				ld e,h
				rl e
				rl d
				add hl,bc
				ld (maths.seed),hl
				ld hl,(maths.seed+2)
				adc hl,de
				res 7,h
				ld (maths.seed+2),hl
				jp m,@+skip
				ld hl,maths.seed
	@loop:
				inc (hl)
				inc hl
				jp z,@-loop
	@skip:
				ld hl,(maths.seed)
				ret

maths.rand.safe:
				push bc
				push de
				push hl
				call maths.rand
				pop hl
				pop de
				pop bc
				ret

;==============================================
; Other maths routines taken from http://map.grauw.nl/sources/external/z80bits.html
; By Milos Bazelides.

maths.multDEBC:
; Return DE:HL = DE*BC
				ld hl,0

				sla	e							; optimised 1st iteration
				rl d
				jp nc,$+5
				ld h,b
				ld l,c

	@loop: equ for 14
				add hl,hl
				rl e
				rl d
				jp nc,$+8						; Skip to next iteration if top bit of D not set
				add hl,bc
				jp nc,$+4
				inc de							; Increment most significant word if carried
	next @loop

	@final_iteration:
				add hl,hl
				rl e
				rl d
				ret nc
				add hl,bc
				ret nc
				inc de
				ret

;----------------------------------------------
maths.multADE:
; Input: A = Multiplier, DE = Multiplicand, HL = 0, C = 0
; Output: A:HL = Product
				ld hl,0
				ld c,0

				add	a
				jr nc,@+skip
				ld h,d
				ld l,e
	@skip:

	@loop: equ for 6
				add hl,hl
				rla
				jr nc,$+4
				add hl,de
				adc c
	next @loop
				add hl,hl
				rla
				ret nc
				add hl,de
				adc c
				ret

;----------------------------------------------
maths.divHLC:
; Return HL/C with HL = Quotient, A = Remainder
				xor a
	@loop: equ for 15
				add	hl,hl
				rla
				cp c
				jp c,$+5
				sub c
				inc l
	next @loop

	@final_iteration:
				add hl,hl
				rla
				cp c
				ret c
				inc l
				ret

