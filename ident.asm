; IDENT

;----------------------------------------------
ident.gfx:		mdat "ident.raw"				; graphics

ident.anim_data:
; Animation data, each entry is frame, delay, position
				db 6,1
				dw (91*256+123)/2				; Fade in
				db 7,1
				dw (91*256+123)/2
				db 8,1
				dw (91*256+123)/2
				db 9,25
				dw (91*256+123)/2

				db 10,1							; Red blink x2
				dw (91*256+123)/2
				db 11,1
				dw (91*256+123)/2
				db 12,1
				dw (91*256+123)/2
				db 11,4
				dw (91*256+123)/2
				db 10,1
				dw (91*256+123)/2
				db 9,30
				dw (91*256+123)/2
				db 10,1
				dw (91*256+123)/2
				db 11,1
				dw (91*256+123)/2
				db 12,1
				dw (91*256+123)/2
				db 11,4
				dw (91*256+123)/2
				db 10,1
				dw (91*256+123)/2
				db 9,15
				dw (91*256+123)/2

				db 0,2							; Open circle
				dw (86*256+123)/2
				db 1,2
				dw (86*256+123)/2
				db 2,2
				dw (86*256+123)/2
				db 3,2
				dw (86*256+123)/2
				db 4,2
				dw (86*256+123)/2
				db 5,0
				dw (86*256+123)/2
				db 13,0
				dw (86*256+129)/2

				db 19,1							; Scroll on logo
				dw (86*256+129)/2
				db 18,1
				dw (86*256+129)/2
				db 17,1
				dw (86*256+129)/2
				db 16,1
				dw (86*256+129)/2
				db 15,1
				dw (86*256+129)/2
				db 21,1
				dw (86*256+129)/2
				db 14,70
				dw (86*256+129)/2

				db 21,0
				dw (86*256+129)/2
				db 20,1
				dw (86*256+129+50)/2
				db 15,0
				dw (86*256+129)/2
				db 20,1
				dw (86*256+129+44)/2
				db 16,0
				dw (86*256+129)/2
				db 20,1
				dw (86*256+129+36)/2
				db 17,0
				dw (86*256+129)/2
				db 20,1
				dw (86*256+129+28)/2
				db 18,0
				dw (86*256+129)/2
				db 20,1
				dw (86*256+129+20)/2
				db 19,0
				dw (86*256+129)/2
				db 20,1
				dw (86*256+129+12)/2
				db 20,1
				dw (86*256+129)/2

				db 4,2
				dw (86*256+123)/2
				db 3,2
				dw (86*256+123)/2
				db 2,2
				dw (86*256+123)/2
				db 1,2
				dw (86*256+123)/2
				db 0,20
				dw (86*256+123)/2

				db 9,1
				dw (91*256+123)/2
				db 8,1
				dw (91*256+123)/2
				db 7,1
				dw (91*256+123)/2
				db 6,1
				dw (91*256+123)/2

				db 0,255,0,0

;----------------------------------------------
ident.frame_data:
				dw ident.gfx+0					;0 Opening circle
				db 5,20
				dw ident.gfx+5
				db 5,20
				dw ident.gfx+10
				db 5,20
				dw ident.gfx+15
				db 5,20
				dw ident.gfx+20
				db 5,20
				dw ident.gfx+25
				db 3,20
				dw ident.gfx+54					;6 Fade in circle
				db 5,10
				dw ident.gfx+59
				db 5,10
				dw ident.gfx+64
				db 5,10
				dw ident.gfx+69					;9 Full circle (black spot)
				db 5,10
				dw ident.gfx+74					; Dark red
				db 5,10
				dw ident.gfx+79					; red
				db 5,10
				dw ident.gfx+84					; Yellow
				db 5,10
				dw ident.gfx+89					;13 Blank
				db 2,20
				dw ident.gfx+28					;14 rest of logo anims
				db 26,20
				dw ident.gfx+32
				db 22,20
				dw ident.gfx+36
				db 18,20
				dw ident.gfx+40
				db 14,20
				dw ident.gfx+44
				db 10,20
				dw ident.gfx+94
				db 6,20
				dw ident.gfx+89					;20 bigger blank
				db 10,20
				dw ident.gfx+29
				db 25,20

ident.palette:	db 8,62,50,33,2,15,38,40,10,112,4,12,66,106,119,127

;----------------------------------------------
ident.run:
				call house.clear_screens
				call house.double_buffer.off
	@set_palette:
				ld hl,ident.palette+15
				ld bc,&10f8
				otdr

				ld a,30
				call PauseA
				ld ix,ident.anim_data
	@loop:
				call ident.get_frame
				cp 255
				jp z,@+end
				call ident.print
				cp 0
				jp z,@-loop
				call PauseA

				jp @-loop

	@end:
				call house.double_buffer.on
				call house.clear_screens
				ret

ident.get_frame:
				ld a,(ix)
				inc ix

				add a
				add a
				ld e,a
				ld d,0
				ld hl,ident.frame_data
				add hl,de
				ld e,(hl)
				inc hl
				ld d,(hl)
				inc hl
				ld b,(hl)						; b=width
				inc hl
				ld c,(hl)						; c=depth
				ex de,hl						; hl=source

				ld a,(ix)						; a=delay
				inc ix
				ld e,(ix)						; de=print position
				inc ix
				ld d,(ix)
				inc ix
				ret

ident.print:
				push af
	@loop2:
				push bc

				push hl
				push de

	@loop1:
				push bc
				ldi
				pop bc
				djnz @-loop1

				pop hl
				ld bc,128
				add hl,bc
				ex de,hl
				pop hl
				add hl,bc

				pop bc
				dec c
				jp nz,@-loop2
				pop af
				ret

PauseA:
				ld b,a
	@loop:
				call house.wait_frame
				dec b
				ret z
				ld a,191
				call house.wait_lineA
				jp @-loop
