;----------------------------------------------
; PRINTING ROUTINES


gfx.data:		mdat "gfx.raw"					; Gfx stored as tile data

gfx.blue:		equ 0							; Block numbers, stored at x*4 bytes into gfx.data
gfx.green:		equ 1
gfx.purple:		equ 2
gfx.red:		equ 3
gfx.orange:		equ 4
gfx.yellow:		equ 5
gfx.pink_top:	equ 6
gfx.pink_v_mid:	equ 7
gfx.pink_bottom: equ 8
gfx.pink_left:	equ 9
gfx.pink_h_mid:	equ 10
gfx.pink_right:	equ 11
gfx.wall:		equ 12
gfx.white:		equ 13
gfx.blanker:	equ 14
gfx.heart:		equ 15

gfx.level.colours:
; Palette colours for background for each 5 levels (up to 30 = 300 lines scored)
				; yellow, cyan, apple green, light grey, black, royal blue
				db 106,60,117,101,119,0,31

rotation_list:
; Rotation offsets:	Order of offsets to grab from tet data if rotated n degrees clockwise
rot.0:
				db  0, 1, 2, 3
				db  4, 5, 6, 7
				db  8, 9,10,11
				db 12,13,14,15
rot.90:
				db 12, 8, 4, 0
				db 13, 9, 5, 1
				db 14,10, 6, 2
				db 15,11, 7, 3
rot.180:
				db 15,14,13,12
				db 11,10, 9, 8
				db  7, 6, 5, 4
				db  3, 2, 1, 0
rot.270:
				db  3, 7,11,15
				db  2, 6,10,14
				db  1, 5, 9,13
				db  0, 4, 8,12

;----------------------------------------------
tet_data:
; data in easy form (could be compressed better, unnecessary)
@t:
				dm "    "
				dm "xxx "
				dm " x  "
				dm "    "
@j:
				dm "    "
				dm "xxx "
				dm "  x "
				dm "    "
@z:
				dm "    "
				dm "xx  "
				dm " xx "
				dm "    "
@o:
				dm "    "
				dm " xx "
				dm " xx "
				dm "    "
@s:
				dm "    "
				dm " xx "
				dm "xx  "
				dm "    "
@l:
				dm "    "
				dm " xxx"
				dm " x  "
				dm "    "
@i:
				dm "    "
				dm "xxxx"
				dm "    "
				dm "    "

tet.colours:
; Each tetronimo has its own colour associated - taken from Gameboy Color version
@t:				for 4,db gfx.green				; 4 blocks set as i-bar has a separate graphic for each bit
@j:				for 4,db gfx.blue
@z:				for 4,db gfx.orange
@o:				for 4,db gfx.yellow
@s:				for 4,db gfx.purple
@l:				for 4,db gfx.red
@i.vert:		db gfx.pink_top,  gfx.pink_v_mid, gfx.pink_v_mid, gfx.pink_bottom
@i.hor:			db gfx.pink_left, gfx.pink_h_mid, gfx.pink_h_mid, gfx.pink_right
@white:			for 8,db gfx.white


tet.rot.offsets:
; X and Y graphical offsets for each rotation of each tetronimo.
; This makes sure when rotating the tets they rotate around the right block.
@t.rots:		dw    0,  -1,-257,-256
@j.rots:		dw    0,  -1,-257,-256
@z.rots:		dw    0,  -1,  -1,-257
@o.rots:		dw    0,   0,   0,   0
@s.rots:		dw    0,   0,  -1,-256
@l.rots:		dw    0,-256,-255,   0
@i.rots:		dw    0,   0,-256,   0

tet.rot.offsets.logical:
; Rotation offsets as before, but for logical map (each line is 12 bytes wide)
@t.rots:		dw    0,  -1, -13, -12
@j.rots:		dw    0,  -1, -13, -12
@z.rots:		dw    0,  -1,  -1, -13
@o.rots:		dw    0,   0,   0,   0
@s.rots:		dw    0,   0,  -1, -12
@l.rots:		dw    0, -12, -11,   0
@i.rots:		dw    0,   0, -12,   0

;----------------------------------------------
gfx.clear_game_area:
; Clear the screen display, print walls and floor bricks
				call @+clear
				call house.swap_screens
				call @+clear
				ret

@clear:
				ld hl,&0a28
				ld de,&0a29
				ld a,well.depth.vis*8			; Clear 8 pixel rows deep per block
	@loop:
				ld (hl),bg_col*&11
				ld bc,well.width*8/2-1
				ldir
				ld bc,128-(well.width*8/2-1)
				add hl,bc
				ex de,hl
				add hl,bc
				ex de,hl
				dec a
				jp nz,@-loop

@print_walls:									; Print the walls to the well
				ld b,well.depth.vis
				ld hl,&0a28
	@loop:
				push bc

				ld b,gfx.wall
				ld l,&28+0
				call gfx.print_blockBHL
				ld l,&28+44
				call gfx.print_blockBHL
				ld a,4
				add h
				ld h,a
				pop bc
				djnz @-loop
@print_floor:
				ld b,12
				ld l,&28
	@loop:
				push bc
				ld b,gfx.wall
				call gfx.print_blockBHL
				ld a,4
				add l
				ld l,a
				pop bc
				djnz @-loop
				ret

;----------------------------------------------
gfx.print_tetAIYBCDE:
; Print a tetronimo A, to game grid coord IY with rotation B.  If C=0, print full, c=1, print shadow, C=2, clear tet.  E= colour
; If D is even, print with defined block graphics, else print with white block
; Returns grid position in IY and tet data in IX
				push af
				push bc
				push de
				push hl
				push ix
				push iy
				ld (@+tet+1),a
@store_colour:
				ex af,af'
				ld a,e
				ld (@+colour+1),a
				ex af,af'
@store_block_list:								; Lookup block list address from tet type
				bit 0,d
				jp z,@+cols
		@white:
				ld l,8
				jp @+skip
		@cols:
				ld l,a
		@skip:
				ld h,0
				for 2,add hl,hl
		@next:
				ld de,tet.colours
				add hl,de
	@test_tet_i:								; If printing I-beam and it's rotated, skip on another 4 bytes to the vertical block data addr
				cp tet.i
				jp nz,@+skip
				bit 0,b
				jp nz,@+skip
				ld de,4
				add hl,de
		@skip:
				push hl

@find_block_offset:								; add centring offset from rotation
				ld l,a
				ld h,0
				for 2,add hl,hl
				ld e,b
				ld d,0
				add hl,de
				add hl,hl
				ld de,tet.rot.offsets
				add hl,de
				ld e,(hl)
				inc hl
				ld d,(hl)
				add iy,de

@convert_grid_coord:							; Turn grid coord into screen pos
				ld a,iyl
				ld l,a
				ld a,iyh
				ld h,a

				for 2,add hl,hl
				ld a,-16
				add h
				ld h,a
				ld de,&0a28
				add hl,de
				ex de,hl
@rect_or_shadow:
				ld hl,gfx.print_blockBHL
				ld a,c
				cp 2
				jp nz,@+next
				ld hl,gfx.clear_rectHL
				jp @+skip
	@next:
				or a
				jp z,@+skip
				ld hl,gfx.print_shadowHLC
	@skip:
				ld (@+print_type+1),hl

@process_rotation:
	@find_offsets:								; Find list of offsets in data for this rotation
				ld a,b
				call find_rot_offsetsA

@get_tet:										; Get tet (tetronimo) data
	@tet:		ld c,0
				call get_tetC

				pop iy

				ld bc,&0404						; Set two loop counters
@y_loop:
				push bc
				push de
@x_loop:
				push bc
	@get_os:									; Find offset to process rotation
				ld a,(hl)
				inc hl
				ld (@+shape_os+2),a				; put into offset of IX+0

				push hl
				push de
				ex de,hl
	@colour:	ld c,pale_blue*&11

	@shape_os:	ld a,(ix+0)						; shape offset
				ld b,(iy)
				cp " "
				jp z,@+skip_print

				bit 7,h							; Skip if off the top of the screen
	@print_type: call z,0
				inc iy
	@skip_print:
				pop de
				pop hl

				ld a,4
				add e
				ld e,a

				pop bc
				djnz @-x_loop

				pop de
				ld a,4
				add d
				ld d,a
				pop bc
				dec c
				jp nz,@-y_loop

				pop iy
				pop ix
				pop hl
				pop de
				pop bc
				pop af
				ret

;----------------------------------------------
gfx.print_blockBHL:
; print block B to HL screen address
				push af
				push bc
				push de
				push hl

	@test_printable:
				ld a,h
				cp &0a							; Check not printing an undefined block
				jp c,@+end
				bit 7,h							; Check not printing to y-coord way out of bounds
				jp nz,@+end

				ld a,b
				ex de,hl
				add a
				add a
				ld c,a
				ld b,0
				ld hl,gfx.data
				add hl,bc
				ld a,8
	@loop:
				for 4,ldi
				ld bc,128-4
				add hl,bc
				ex de,hl
				add hl,bc
				ex de,hl
				dec a
				jp nz,@-loop

	@end:
				pop hl
				pop de
				pop bc
				pop af
				ret

;----------------------------------------------
gfx.print_block_maskedBHL:
; print block B to HL screen address, masking on colour 0
				push af
				push bc
				push de
				push hl

	@test_printable:
				ld a,h
				cp &0a
				jp c,@+end
				bit 7,h
				jp nz,@+end

				ld a,b
				ex de,hl
				add a
				add a
				ld c,a
				ld b,0
				ld hl,gfx.data
				add hl,bc
				ld a,8
	@loop:
				ex af,af'

				ld b,4
		@loop2:
				ld c,0
				ld a,(hl)
				and %11110000
				or a
				jp nz,@+next
				ld a,(de)
				and %11110000
				ld c,a
		@next:
				ld a,(hl)
				and %00001111
				or a
				jp nz,@+next
				ld a,(de)
				and %00001111
				or c
				ld c,a
		@next:
				ld a,(hl)
				or c
				ld (de),a
				inc e
				inc hl
				djnz @-loop2

				ld bc,128-4
				add hl,bc
				ex de,hl
				add hl,bc
				ex de,hl

				ex af,af'
				dec a
				jp nz,@-loop

	@end:
				pop hl
				pop de
				pop bc
				pop af
				ret

;----------------------------------------------
gfx.clear_blockHL:
; clear block size to HL screen address
				push af
				push bc
				push de
				push hl

				call gfx.clear_rectHL

				pop hl
				pop de
				pop bc
				pop af
				ret

;----------------------------------------------
gfx.clear_rectHL:
				ld a,h
				cp &0a
				ret c
				bit 7,h
				ret nz

				ld a,8
				ld e,l
				inc e
				ld d,h
	@loop:
				ld (hl),bg_col*&11
				for 3,ldi
				ld bc,128-3
				add hl,bc
				ex de,hl
				add hl,bc
				ex de,hl
				dec a
				jp nz,@-loop
				ret

;----------------------------------------------
gfx.print_rectHLC:
; Print a 6*6 pixel rectangle at HL with colour C
				ld de,128
				add hl,de
				ld a,c
				and &0f
				or bg_col*&10					; Hardcoded masking with game background
				ld e,a
				ld a,c
				and &f0
				or bg_col
				ld d,a
				ld a,c
				ex af,af'
				ld a,6
				ld bc,128-3
	@loop:
				ex af,af'
				ld (hl),e
				inc l
				ld (hl),a
				inc l
				ld (hl),a
				inc l
				ld (hl),d
				add hl,bc
				ex af,af'
				dec a
				jp nz,@-loop
				ret

;----------------------------------------------
gfx.print_shadowHLC:
; print outline of rectangle at HL with colour C (shadow of where block will fall)
				ld de,128
				add hl,de
				ld a,c
				and &0f
				or bg_col*&10
				ld e,a
				ld a,c
				and &f0
				or bg_col
				ld d,a
				ld a,c
				ld bc,128-3
				call @top_bottom
				ex af,af'
				ld a,4
	@loop:
				ld (hl),e
				for 3,inc l
				ld (hl),d
				add hl,bc
				dec a
				jp nz,@-loop
				ex af,af'
				call @top_bottom
				ret

	@top_bottom:							; Print just top and bottom rows
				ld (hl),e
				inc l
				ld (hl),a
				inc l
				ld (hl),a
				inc l
				ld (hl),d
				add hl,bc
				ret

;----------------------------------------------
gfx.print_full_map:
; print the whole map on both screens
				call @print_all
				call house.swap_screens
				call @print_all
				call house.swap_screens
				ret

gfx.print_full_map1:
; print the whole map on one screen only
@print_all:
				ld hl,well+(12*4)				; Only print visible part of map
				ld d,&0a						; Initial screen line
				ld c,18							; rows counter
	@row_loop:
				ld e,&2c						; Init x byte position
				inc hl							; Skip printing wall
				ld b,10							; block counter
	@block_loop:
				push bc

				ld a,(hl)						; Get block for this position
				cp -1							; If background then print background rectangle
				jp nz,@+print
		@clear:
				ex de,hl
				call gfx.clear_blockHL
				ex de,hl
				jp @+next
		@print:									; print block
				ld b,a
				ex de,hl
				call gfx.print_blockBHL
				ex de,hl
		@next:									; Update print position
				ld a,4
				add e
				ld e,a

				inc hl							; next block

				pop bc
				djnz @-block_loop

				inc hl							; skip final wall entry

				ld a,4							; Next row down
				add d
				ld d,a

				dec c
				jp nz,@-row_loop
				ret

;----------------------------------------------
gfx.print_byte_rectHLDEA:
; print a rectangle at coords (L,H) to (E,D) with colour A.  Byte accuracy only
				push af
	@get_depth_counter:
				ld a,d
				sub h
				ld b,a
	@get_dest_addr:
				srl h
				rr l
	@get_byte_dest:
				srl d
				rr e
	@get_width_counter:
				ld a,e
				sub l
				ld c,a

				pop af

	@y_loop:
				push bc
				push hl
	@x_loop:
				ld (hl),a
				inc l
				dec c
				jp nz,@-x_loop

				for 4,rrca

				pop hl
				ld de,128
				add hl,de

				pop bc
				djnz @-y_loop
				ret

;----------------------------------------------
gfx.outlineIXHLDEBC:
; Draw outline round graphic at (L,H) to (E,D) with colour C
; B sets which sides are outlined, from top-left to bottom right (bit 0 is top-left)
; IX points to list of colours to count as foreground, paint over any other colours, term with 255
; Don't check for sides of screen, draw outside of checking area if needed.
	@y_loop:									; loop through all pixels in area
				push hl
	@x_loop:
				call @get_pixHL					; check if pixel colour is a 'foreground' pixel
				call @is_fore_colA
				call z,@outline_pix				; If so, print outline pixels on all selected, over 'background' colour pixels only
	@next_x:
				call house.pal_up				; Test - if decompressing then palette will change as feedback
				inc l
				ld a,l
				cp e
				jp nz,@-x_loop
	@next_y:
				pop hl
				inc h
				ld a,h
				cp d
				jp nz,@-y_loop

				ret

@get_pixHL:
; Return colour of pixel (L,H) in A
				push hl
				srl h
				rr l
				ld a,(hl)
				jp c,@right
	@left:
				for 4,rra
	@right:
				and &0f
				pop hl
				ret

@is_fore_colA:
; Return Z if A is a foreground colour
				push bc
				push ix
				ld b,a
	@loop:
				ld a,(ix)
				inc ix
				cp 255
				jp z,@+back_found
				cp b
				jp nz,@-loop
	@fore_found:
				pop ix
				pop bc
				ret
	@back_found:
				cp 254
				pop ix
				pop bc
				ret

@outline_pix:
				dec h
				bit 6,b
				call nz,@plot_foreHLC
				inc l
				bit 5,b
				call nz,@plot_foreHLC
				inc h
				bit 3,b
				call nz,@plot_foreHLC
				inc h
				bit 0,b
				call nz,@plot_foreHLC
				dec l
				bit 1,b
				call nz,@plot_foreHLC
				dec l
				bit 2,b
				call nz,@plot_foreHLC
				dec h
				bit 4,b
				call nz,@plot_foreHLC
				dec h
				bit 7,b
				call nz,@plot_foreHLC
				inc l
				inc h
				ret

@plot_foreHLC:
; Plot colour C to (L,H) if current colour at HL is not foreground colour
				call @get_pixHL
				call @is_fore_colA
				call nz,@plotHLC
				ret

@plotHLC:
;Plot point (L,H) with colour C
				push af
				push hl

				srl h
				rr l
				jp nc,@plot_right
	@plot_left:
				ld a,(hl)
				and &f0
				or c
				ld (hl),a

				pop hl
				pop af
				ret

	@plot_right:
				push bc
				for 4,rlc c
				ld a,(hl)
				and &0f
				or c
				ld (hl),a
				pop bc

				pop hl
				pop af
				ret

;----------------------------------------------
gfx.print_pyramidDE:
; Print the HUD pyramid block to (E,D)
				push af
				push bc
				push de
				push hl

				srl d
				rr e
				ld hl,gfx.data+(152/2)
				ld a,8
	@loop:
				for 4,ldi
				ld bc,128-4
				add hl,bc
				ex de,hl
				add hl,bc
				ex de,hl
				dec a
				jp nz,@-loop

				pop hl
				pop de
				pop bc
				pop af
				ret
