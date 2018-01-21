; CC TETRIS! by tobermory@cookingcircle.co.uk. 10-Nov-17 to 10-Jan-18


; v1.1:			21/1/18:  Bugfixes and feature corrections
;				* Fixed corruption on logo on real SAMs, buffer now initialised
;				* Redefine keys now excludes Escape and any duplicate
;				* Corrected some flashing pixels when St Basil scroll has stopped

; v1.0:			10/1/18:  Initial build

;----------------------------------------------
; Entry point
auto.start:
				dump 1,0
				autoexec
				org 32768

				di
	@set_low_page:
				ld a,screenPage2+32				; 32=Turn ROM0 off, screen is in 0-24575
				out (LMPR),a
	@set_video_page:
				ld a,ScreenPage1+96				; 96=Mode 4, double-buffered screen system
				out (VMPR),a
	@set_stack:
				ld sp,@+stack
				jp main.start

				ds 64
@stack:

music.data6:	mdat "music/korobushka.raw"		; Final music (sat in weird place, see music module)

;----------------------------------------------
; GLOBAL VARIABLES

MainPage:		equ 1							; Main game logic here
MusicPage:		equ 3							; Compiled music here (also one tune in main page)
StBasilPage:	equ 5							; Cathedral graphic uncompressed
ScreenPage1:	equ 8							; Double-buffered screen allocation
ScreenPage2:	equ 10							; Also sometimes treated as working screen to copy into/out of
BuildPage:		equ 12							; Used for building quick print routines, for St Basil scroll

Yes:			equ 0							; Some equates to make code easier to read
No:				equ -1
Success:		equ 0
Failure:		equ -1
On:				equ 0
Off:			equ -1
True:			equ 0
False:			equ -1

LMPR:			equ 250							; Equates for ports used
HMPR:			equ 251
VMPR:			equ 252
PaletteBaseReg:	equ 248
StatusReg:		equ 249
KeyboardReg:	equ 254
BorderReg:		equ 254
HPEN:			equ 504

sfx.on:			db On

dark_grey:		equ 0							; All colours are labelled
dark_green:		equ 1
red:			equ 2
black:			equ 3
white:			equ 4
pale_blue:		equ 5
dull_purple:	equ 6
cyan:			equ 7
bg_col:			equ 8
green:			equ 9
yellow:			equ 10
orange:			equ 11
pink:			equ 12
brown:			equ 13
blue:			equ 14
pale_green:		equ 15

tet.t:			equ 0							; each type of tetronimo is labelled
tet.j:			equ 1
tet.z:			equ 2
tet.o:			equ 3
tet.s:			equ 4
tet.l:			equ 5
tet.i:			equ 6

; The 'well' is the main playing area
well.width:		equ 12							; main game grid parameters
well.depth:		equ 23
well.depth.vis:	equ 18							; There is a usable invisible area above screen for rotating tets
well.len:		equ well.width*(well.depth+1)
well:			ds well.len						; game grid played out here

tet.curr.type:	db 0							; Current tetronimo
tet.next.type:	db 0							; Upcoming tetronimo (printed in the HUD)

init_drop_spd:	equ 30
drop_spd:		db 0							; Amount of delay between each block falling
drag_down_spd:	equ 2							; When dragging down block, speed it goes

tet.curr.drop_counter: db 0						; Current countdown til drops to next position down
tet.curr.pos:
tet.curr.pos.x:	db 0							; When dropping/locking, the current coords and rotation
tet.curr.pos.y:	db 0
tet.curr.rot:	db 0
tet.prev1.pos:									; Previous positions need to be in the same format as current
tet.prev1.pos.x: db 0
tet.prev1.pos.y: db 0
tet.prev1.rot:	db 0
tet.prev2.pos:
tet.prev2.pos.x: db 0
tet.prev2.pos.y: db 0
tet.prev2.rot:	db 0

tet.curr.well_pos: dw 0

game_state:		db 0							; Current game state tests - uses state machine for updates
gs.create:		equ 0							; Creating new tet for top of screen
gs.dropping:	equ 1							; block being dropped
gs.flash_lock:	equ 2							; flash block as it's being locked into place
gs.locking:		equ 3							; block at bottom (might be unnecessary)
gs.flashing:	equ 4							; Flashing successful lines
gs.clearing:	equ 5							; Removing completed lines, move down
gs.blanking: 	equ 6							; Filling screen when game over
gs.game_over:	equ 7							; end, wait for keypress to start again
gs.end:			equ 8

full_lines:		for 4,db 0						; list of up to 4 lines that are currently flashing, to be removed

flash.timer:	db flash.time					; Timer for flashing of full lines
flash.time:		equ 35

curr.lines:		db 0,0,0,0						; Amount of lines scored in one-byte-per-decimal format
curr.lines.dirty: db 0							; If amount of lines gone up in last two frames, this is set to >0
curr.level:		db 0,0							; Current level number in ASCII
curr.level.bin:	db 0							; current level in binary
curr.level.dirty: db 0							; If >0, amount of frames to reprint level number
curr.score:		dm "000000"						; 6 digit score in ASCII format
				db eof
curr.score.bin:	db 0,0,0						; Current score in binary
curr.score.dirty: db 0							; If >0, amount of frames to reprint score
curr.stack.height: db 0							; Y coord of tallest block in the well

frame.elapsed:	db No							; IM2-controlled flag - set when new frame has occured
interrupt.elapsed: db No						; IM2-controleld flag - set when line interrupt has occured
auto_swap.on: 	db Yes							; Set to No to supress screen swap on frame interrupt
urgent_stack_height: equ 12						; Height at which music speeds up (4 lower before music slows again)
go_length:		equ 3300						; Amount of frames to play game over message tune before returning
demo.mode.on:	db Off							; Set on for rolling demo, game uses mechanised input and tet generation

;----------------------------------------------
; MODULES
				include "house.asm"				; Housekeeping routines
				include "maths.asm"				; maths routines
				include "compile.asm"			; compile equates for builder routines
				include "keys.asm"				; key reading and interpretation
				include "redefine.asm"			; redefine keys  imported from Split
				include "gfx.asm"				; Graphics data and printing routines
				include "hud.asm"				; HUD stuff
				include "pause.asm"				; pause menu
				include "options.asm"			; options menu in attract sequence
				include "stats.asm"				; statistics panel
				include "sfx.asm"				; Sound effects module imported from Thrust
				include "font.asm"				; Font printing stuff from Thrust
				include "st basil.asm"			; St Basil graphic scroll compiler
				include "attract.asm"			; Front end stuff
				include "ident.asm"				; Cooking Circle animation
				include "demo.asm"				; Rolling demo
				include "music.asm"				; Protracker music
				include "build.asm"				; 'Press fire' sprite builder

;----------------------------------------------
; MAIN GAME LOOP
main.start:
				call main.setup					; Run one-time only setup routines
				call ident.run					; Run one-time only Cooking Circle ident flash

main.attract_mode:								; Attract mode and game go round in a loop
				call attract.init
				ld a,int_mode.attract
				call music.set_modeA
				ld a,music.intro1
				call music.setA
				ei

main.attract.loop:
main.attract_wait: call house.wait_int_im2
				call house.auto_swap			; Swap screens if
				call attract.update				; Call update of attract mode

	@test_start:								; Test keys for start game (fire to play)
				ld a,(keys.processed)
				bit RotateAC,a
				jp nz,main.game_start
				bit RotateC,a
				jp nz,main.game_start
	@test_options:								; Press escape for options - breaks out of attract loop
				bit Escape,a
				call nz,options.start

				jp main.attract.loop

main.game_start:								; Main game start
				call main.start_transition		; Play start game sound, wipe off screen
				call main.reset_game
main.loop:
				call house.wait_frame_im2
				call house.swap_screens
				call hud.update
				call pause.start

	@test_timer:
				call demo.update_timer			; If running rolling demo, update timer
				ret z

	@test_state:								; Use state machine for all gameplay updates
				ld a,(game_state)
				cp gs.end						; After game over, break out to attract sequence
				jp z,main.attract_mode

				cp gs.create					; Making a new tetronimo
				call z,gs.create_tet
				cp gs.dropping					; Tet is dropping down, being moved and rotated by player
				call z,gs.drop_block
				cp gs.locking					; Nowhere to drop to, lock piece into place
				call z,gs.lock_tet
				cp gs.flash_lock				; Flash piece to show locked
				call z,gs.flash_lock_tet
				cp gs.flashing					; If completed lines, flash them
				call z,gs.flash_lines
				cp gs.clearing					; Completed lines, clear them progressively
				call z,gs.clear_lines

				cp gs.blanking					; If no space, do game over blanking out of well
				call z,gs.blank_screen
				cp gs.game_over					; If blanking has completed, print game over message
				call z,gs.print_go_msg


				jp main.loop

;----------------------------------------------
main.setup:
; One-time only setup routines.
				call house.clear_screens
				call house.swap_screens			; ! This is one time when I have to start on correct screen
				call options.prep_logo			; Make logo and store in normal format, for options menu
				call attract.compile_start		; Make quick print routine to print Fire to play message
				call stb.compile				; Make St Basil quick print raster routines
				call house.pal_up.set.off
				ret

;----------------------------------------------
main.start_transition:
; Play start-game noise, clear the screen, wait for a short delay.
; Direct-mode routine, this does not quit to the main structure.
				ld a,(demo.mode.on)
				cp Off
				jr z,@+normal
@demo:											; If part of attract mode, skip this section
				call house.clear_screens
				ret
@normal:
				ld a,music.game_on
				call music.setA

				ld b,30
	@loop:
				push bc
				call house.wait_frame_im2
				call house.swap_screens
				call attract.end_wipe
				pop bc
				djnz @-loop
				ret

;----------------------------------------------
main.reset_game:
				call house.palette_off
				call music.off
@set_music:										; initiate game music mode (no extra interrupt for palette changes)
				di
				call music.setup_im2
				ld a,int_mode.game
				call music.set_modeA

				call house.clear_screens		; Clear both screens
				ld hl,house.palette
				call house.set_paletteHL
				call house.restore_background_palette ; Set colours to game palette

@empty_well:									; Clear playing area (the logical gamespace)
				ld hl,well
				ld de,well+1
				ld bc,well.len-1
				ld (hl),-1
				ldir
@set_walls:										; Put walls on left and right of well
				ld b,well.depth-1
				ld hl,well
	@loop:
				ld (hl),gfx.wall
				ld de,well.width-1
				add hl,de
				ld (hl),gfx.wall
				inc hl
				djnz @-loop
@set_floor:										; Put floor on bottom of well
				ld b,well.width
	@loop:
				ld (hl),gfx.wall
				inc hl
				djnz @-loop

@init_tets:
				call generate_tet.first
				call hud.init
				call hud.print_first
				call sfx.init.out
				call stats.reset				; Clear statistics for game
				call gfx.clear_game_area

@init_go_timer:									; Reset timer for game over music
				ld hl,go_length
				ld (go_timer+1),hl

@init_drop_speed:
				ld a,init_drop_spd
				ld (drop_spd),a
@init_stack_height:
				xor a
				ld (curr.stack.height),a

@init_game_state:
				ld a,gs.create
				ld (game_state),a
@reset_flash:
				ld a,flash.time
				ld (flash.timer),a

				call house.set_curr_palette

@test_demo_mode:								; If rolling demo, use a different tune
				ld a,(demo.mode.on)
				cp On
				ld a,music.intro2
				jr z,@+skip
main.game_music: ld a,music.korobushka			; Set in-game music - changed by options.pick_tune and the medley function
	@skip:
				call music.setA
				ei
				ret

;----------------------------------------------
gs.create_tet:
; Game state - run when making a new block for top of screen
				push af
				call generate_tet				; Create new tet
@set_curr_spd:									; Set drop speed - this should speed up with higher scores etc
				ld a,(drop_spd)
				ld (tet.curr.drop_counter),a
@set_curr_pos:									; Initiate position
				ld hl,&0304
				ld (tet.curr.pos),hl
				ld (tet.prev1.pos),hl
				ld (tet.prev2.pos),hl
@init_rotation:
				xor a							; Initiate rotation
				ld (tet.curr.rot),a
				ld (tet.prev1.rot),a
				ld (tet.prev2.rot),a
@test_space:									; Check tet fits on screen
				ld a,(tet.curr.type)
				ld c,a
				ld a,(tet.curr.rot)
				call test_tet_fitCA
				jp z,@+success
@failed:										; If not, set game over state
				ld a,music.go_explode
				call music.setA

				ld a,gs.blanking
				jp @+next
@success:
				ld a,gs.dropping				; If successful, set general dropping state
	@next:
				ld (game_state),a
				pop af
				ret

;----------------------------------------------
generate_tet:
; Move next tet into current, create new tet type
@update_tets:									; Turn next type into current
				ld a,(tet.next.type)
				ld (tet.curr.type),a

				call stats.incA

				ld a,(demo.mode.on)
				cp Off
				jp z,@+get_tet
	@demo_mode:
				call demo.get_tet
				ld (tet.next.type),a
				ret
	@get_tet:
				call @rand7
	@test_same:									; If same tet type comes up, give another roll of the die
				ld hl,tet.curr.type
				cp (hl)
				call z,@rand7
				ld (tet.next.type),a
				ret

@rand7:											; Get random number *7 as new tet type
				call maths.rand
				ld hl,(maths.seed)
				ld e,l
				ld h,0
				ld d,h
				add hl,hl
				add hl,de
				add hl,hl
				add hl,de
				ld a,h
				ret

generate_tet.first:
				ld a,(demo.mode.on)
				cp On
				call z,demo.reset_tet
				jp generate_tet

;----------------------------------------------
gs.blank_screen:
; When game over, blank screen out with orange tiles
				xor a
				ld (curr.stack.height),a
				call gs.blanker
				call nc,@end
				ret

gs.blanker:
@update_line:
	@line:		ld a,18*2						; Does one line on each screen per frame
				add -1
				ret nc
				ld (@-line+1),a
@find_print_coords:
				srl a
				ld h,a
				ld l,0
				add hl,hl
				add hl,hl
				ld a,&0a
				add h
				ld h,a
				ld l,&28+4
@print_loop:
				ld b,10
	@loop:
				push bc
				ld b,gfx.blanker
				call gfx.print_blockBHL
				ld a,4
				add l
				ld l,a
				pop bc
				djnz @-loop
				scf
				ret

@end:
				call gs.blanking.reset_counter
	@set_game_state:
				ld a,gs.game_over
				ld (game_state),a
	@set_music:
				ld a,music.game_over
				call music.setA
	@prep_go_dirty:								; prepare the dirty state for printing game over message
				ld a,3
				ld (go_msg_dirty+1),a
				ret

gs.blanking.reset_counter:
; Reset counter.  Also used to reset by pause routine
				ld a,18*2
				ld (@-line+1),a
				ret
;----------------------------------------------
gs.drop_block:
; Game state loop.  This is run when block is being dropped, moved or rotated
				push af

				call age_tet
				call @+update_drop
				ld a,(game_state)				; Check newest version of game state to see if still able to move
				cp gs.dropping
				jr nz,@+skip
				call @+update_move
				call @+update_rotate
	@skip:
				push de
				ld d,0							; Always print with correct colours at this stage
				call reprint_tetD
				pop de

				pop af
				ret

;----------------------------------------------
age_tet:
; Age the current tet states
				ld de,tet.prev2.rot
				ld hl,tet.prev1.rot
				ld bc,6
				lddr
				ret

;----------------------------------------------
@update_drop:
; Update drop by one frame, moving block down if time and there's space for it.
				ld hl,tet.curr.drop_counter
	@test_drag_down:							; If down pressed, decrease drop delay
				ld a,(keys.curr)				; This is the only keypress that supports immediate input for repeating
				bit Down,a
				jp z,@+skip_drag_down
				ld a,drag_down_spd
				cp (hl)
				jp nc,@+skip_drag_down
				ld (hl),a
				call hud.inc_score
		@skip_drag_down:
				dec (hl)
				ret nz							; If delay outstanding, quit here

	@process_move_down:
		@reset_drop_counter:
				ld a,(drop_spd)
				ld (hl),a
		@move_down:
				ld hl,tet.curr.pos.y
				inc (hl)
				ld a,(tet.curr.type)
				ld c,a
				ld a,(tet.curr.rot)
				call test_tet_fitCA				; Check new position fits in grid
				ret z
	@quit_drop:									; If not, undo last move and set game state to lock in place
		@undo_move_down:
				dec (hl)
		@update_state:
				ld a,gs.locking
				ld (game_state),a
				ret

;----------------------------------------------
@update_move:
; Move tet left or right based on new key presses
				ld a,(keys.processed)
				ld e,a
				ld a,(tet.curr.type)
				ld c,a
				ld a,(tet.curr.rot)
				ld hl,tet.curr.pos.x
	@test_move_left:
				bit Left,e
				jp z,@+test_move_right
				dec (hl)
				call test_tet_fitCA
				jp z,@skip_undo
		@undo:
				inc (hl)
				jp @+test_move_right
		@skip_undo:
				push hl							; Set sound effect
				ld c,sfx.move_side
				call sfx.setC.out
				pop hl

	@test_move_right:
				bit Right,e
				ret z
				inc (hl)
				call test_tet_fitCA
				jp z,@+skip_undo
		@undo:
				dec (hl)
				ret
		@skip_undo:
				push hl
				ld c,sfx.move_side
				call sfx.setC.out
				pop hl
				ret

;----------------------------------------------
@update_rotate:
; Update rotation if RotateAC button pressed
	@test_rotate_clockwise:
				ld a,(keys.processed)
				bit RotateAC,a					; If RotateAC pressed, rotate anti-clockwise
				jp z,@+test_rotate_clockwise

		@rotate_block:
				ld a,(tet.curr.type)

			@rot_i:								; ! Having problems with i-beam moving to extreme left, separate code will do
				cp tet.i
				jp nz,@+rot_other
				ld c,a
				ld a,(tet.curr.rot)
				dec a
				and %00000001
				or %00000010
				ld (tet.curr.rot),a
				call test_tet_fitCA
				jp z,@+skip_undo
				jp @+undo_rotate

			@rot_other:
				ld c,a
				ld a,(tet.curr.rot)
				dec a
				and %00000011
				ld (tet.curr.rot),a
				call test_tet_fitCA
				jp z,@+skip_undo
		@undo_rotate:
				inc a
				and %00000011
				ld (tet.curr.rot),a
				jp @+test_rotate_clockwise
		@skip_undo:
				push hl
				ld c,sfx.rotate
				call sfx.setC.out
				pop hl

	@test_rotate_clockwise:
				ld a,(keys.processed)
				bit RotateC,a
				ret z

		@rotate_block:
				ld a,(tet.curr.type)

			@rot_i:
				cp tet.i
				jp nz,@+rot_other
				ld c,a
				ld a,(tet.curr.rot)
				inc a
				and %00000001
				or %00000010
				ld (tet.curr.rot),a
				call test_tet_fitCA
				jp z,@+skip_undo
				jp @+undo_rotate

			@rot_other:
				ld c,a
				ld a,(tet.curr.rot)
				inc a
				and %00000011
				ld (tet.curr.rot),a
				call test_tet_fitCA
				jp z,@+skip_undo
		@undo_rotate:
				dec a
				and %00000011
				ld (tet.curr.rot),a
				ret
		@skip_undo:
				push hl
				ld c,sfx.rotate
				call sfx.setC.out
				pop hl
				ret

;----------------------------------------------
reprint_tetD:
; Clear previous tet graphic and print in new place
	@clear_old_tet:
				ld iy,(tet.prev2.pos)			; Use positions 2 frames ago to clear, as double buffered screen
				ld a,(tet.prev2.rot)
				ld b,a
				ld a,(tet.curr.type)
				ld c,2
				ld e,0
				call gfx.print_tetAIYBCDE
	@print_new_tet:
				ld iy,(tet.curr.pos)
				ld a,(tet.curr.rot)
				ld b,a
				ld a,(tet.curr.type)
				ld c,0
				ld e,0
				call gfx.print_tetAIYBCDE
				ret

;----------------------------------------------
test_tet_fitCA:
; Test a tetronimo C, to current game grid coord, with rotation A.  Return Z if successful.
				ld (@+rest_a+1),a
				push bc
				push de
				push hl

				call get_tetC					; Get IX-> tet data
				call find_rot_offsetsA			; Get HL-> rotation offsets
				call get_well_pos				; Get DE-> logical map position of current tet position
				call find_block_offsetCA		; Get BC-> offset to centre tet based on rotation
				ex de,hl
				add hl,bc						; Now HL-> logical map position, centred, DE-> rotation offsets

				ld c,4							; Set two loop counters
@y_loop:
				ld b,4
@x_loop:
	@get_os:									; Find offset to process rotation
				ld a,(de)
				inc de
				ld (@+shape_os+2),a				; put into offset of IX+0

	@shape_os:	ld a,(ix+0)						; shape offset
				cp " "
				jp z,@+next_block				; If shape blank here, no problems, move to next block to check
				ld a,(hl)
				cp -1							; Anything except background is a collision
				jp nz,@+end
	@next_block:
				inc hl
				djnz @-x_loop
	@line_down:
				push bc
				ld bc,8
				add hl,bc
				pop bc
				dec c
				jp nz,@-y_loop
@end:
				pop hl
				pop de
				pop bc
	@rest_a:	ld a,0
				ret

;----------------------------------------------
gs.lock_tet:
; Lock current tet into game grid and check for completed lines
				push af

	@counter:	ld a,3
				dec a
				jp z,@+reset
				call age_tet
				call reprint_tetD
	@reset:
				ld a,3
				ld (@-counter+1),a

@store_tet:										; Store end position for the tet in the game grid
				ld a,(tet.curr.type)
				ld c,a
				ld a,(tet.curr.rot)
				call store_tetCA

@play_sound:
				push bc
				push hl
				ld c,sfx.lock_tet
				call sfx.setC.out
				pop hl
				pop bc

@set_game_state:
				ld a,gs.flash_lock
				ld (game_state),a

				pop af
				ret

;----------------------------------------------
store_tetCA:
; Store tetronimo C, to current game grid coord, with rotation A.
				call get_tet_colsCA				; Get IY-> tet block colours in list
				call get_tetC					; Get IX-> tet data
				call find_rot_offsetsA			; Get HL-> rotation offsets
				call get_well_pos				; Get DE-> logical map position of current tet position
				call find_block_offsetCA		; Get BC-> offset to centre tet based on rotation
				ex de,hl						; Update position of DE
				add hl,bc

				ld bc,&0404						; Set two loop counters for width and height
@y_loop:
				push bc
@x_loop:
	@get_os:									; Find offset to process rotation
				ld a,(de)
				inc de
				ld (@+shape_os+2),a				; put into offset of IX+0

	@shape_os:	ld a,(ix+0)						; shape offset
				cp " "
				jp z,@+next_block				; If blank, move to next position
				ld a,(iy)
				inc iy
				ld (hl),a 						; Store to map position

	@next_block:
				inc hl
				djnz @-x_loop
	@next_line:									; Move to next line in well data
				ld bc,8
				add hl,bc

				pop bc							; Repeat for each row of tet
				dec c
				jp nz,@-y_loop

@test_height:
				call well.find_height
				ret

;----------------------------------------------
get_tet_colsCA:
; IY = tetronimo colours list of shape C
				push af
				push bc

@test_tet_i_rotated:							; Hacky test for tet.i rotated to horizontal
				push af
				ld a,c
				cp tet.i
				jp nz,@+skip
				pop af
				bit 0,a
				jp nz,@+next
				inc c
				jp @+next
	@skip:
				pop af
	@next:
				for 2,rl c
				ld b,0
				ld iy,tet.colours
				add iy,bc

				pop bc
				pop af
				ret

get_tetC:
; IX = tetronimo data of shape C
				push bc
				for 4,rl c
				ld b,0
				ld ix,tet_data
				add ix,bc
				pop bc
				ret

find_rot_offsetsA:
; Find list of offsets in data for this rotation
				push af
				push bc
				for 4,add a
				ld c,a
				ld b,0
				ld hl,rotation_list
				add hl,bc
				pop bc
				pop af
				ret

get_well_pos:
; Return top-left offset in well data of current tet position in DE
				push af
				push hl
	@y_mult_12:
				ld a,(tet.curr.pos.y)
				ld l,a
				ld e,a
				ld h,0
				ld d,h
				add hl,hl
				add hl,de
				add hl,hl
				add hl,hl
	@add_x:
				ld a,(tet.curr.pos.x)
				ld e,a
				add hl,de
	@add_data_offset:
				ld de,well
				add hl,de
				ex de,hl
				pop hl
				pop af
				ret

find_block_offsetCA:
; REturn BC = centring offset from rotation A of tet C
				push af
				push hl
	@mult_4:
				ld l,c
				ld h,0
				for 3,add hl,hl
				add a
				ld c,a
				ld b,0
				add hl,bc
				ld bc,tet.rot.offsets.logical
				add hl,bc
				ld c,(hl)
				inc hl
				ld b,(hl)
				pop hl
				pop af
				ret

;----------------------------------------------
well.find_height:
; Store Y coord of topmost piece in well.  0 is on the floor
				ld hl,well+1
				ld c,well.depth-1
				ld a,-1
	@loop:
				ld b,well.width-2
		@loop2:
				cp (hl)
				jr nz,@+end
				inc hl
				djnz @-loop2

				inc hl
				inc hl
				dec c
				jr nz,@-loop
	@end:
				ld a,c
				ld (curr.stack.height),a
				ret

;----------------------------------------------
gs.flash_lock_tet:
; Briefly flash current tet to lock for next few frames
				push af
				call age_tet

	@timer:		ld a,4
				sub 1
				ld (@-timer+1),a
				jp c,@+reset
	@flash:										; If first two frames, print in white, for locking flash
				ld d,0
				cp 2
				jp c,@+cols
		@white:
				inc d
		@cols:
				call reprint_tetD

				pop af
				ret

@reset:											; If done, reset flashing timer
				ld a,4
				ld (@-timer+1),a

@check_lines:									; Count amount of full lines
				ld ix,full_lines
@clear_lines:									; Prep lines to flash as all blank
				ld (ix+0),0
				ld (ix+1),0
				ld (ix+2),0
				ld (ix+3),0

				ld bc,&1500						; Set loops for all lines, set count of full lines to 0
@line_check:
				call @+check_lineB
				jp nz,@+skip
				ld (ix),b
				inc ix
				inc c
	@skip:
				djnz @-line_check

@choose_game_state:
				ld a,c
				or a
				jp nz,@+set_flashing
	@set_create:								; If no lines found, move straight to new tet generation
				ld a,gs.create
				ld (game_state),a
				pop af
				ret

@set_flashing:									; If at least one line to clear, start flashing lines

	@choose_sfx:								; Pick tetris or clear_lines sound effect
				ld c,sfx.clear_lines
				ld b,4
				ld hl,full_lines
				xor a
		@loop:
				cp (hl)
				inc hl
				jp z,@+update_lines
				djnz @-loop
				ld c,sfx.clear_tetris

		@update_lines:							; ! Crowbarred in there
				ld a,4
				sub b
				call hud.inc_linesA

				call sfx.setC.out
				pop af							; junk current state and run to next one

				ld a,gs.flashing
				ld (game_state),a
				ret

;----------------------------------------------
@check_lineB:
; Check line B of logical map, return Z if full
				push bc
	@find_map_pos:
		@mult_12:
				ld l,b
				ld e,b
				ld h,0
				ld d,h
				add hl,hl
				add hl,de
				add hl,hl
				add hl,hl
		@find_offset:
				ld de,well+1					; Add extra byte to offset to skip wall
				add hl,de
				ld b,10
				ld a,-1
	@loop:
				cp (hl)
				jp z,@+fail
				inc hl
				djnz @-loop
	@success:
				pop bc
				xor a
				ret
	@fail:
				pop bc
				ld a,1
				or a
				ret

;----------------------------------------------
gs.flash_lines:
; Print the full lines with white blanks or actual blocks
				push af
@update_timer:									; Update countdown for this game state
				ld hl,flash.timer
				dec (hl)
				jp nz,@+set_flash_type
	@end:										; If completed countdown, reset timer
				ld a,flash.time
				ld (flash.timer),a
				ld a,gs.clearing				; And set game state for moving down other blocks
				ld (game_state),a
				pop af
				ret

@set_flash_type:								; Set printing routine
				ld a,(hl)
				and %00000100
				ld hl,@+print_block
				ld b,Yes
				or a
				jp z,@+next
				ld hl,@+print_flash
				ld b,No
	@next:
				ld (@+call_type+1),hl
				ld (@+tetris_flash+1),a			; Used if a full tetris found to flash the border

				ld bc,full_lines				; Loop through full_lines list for lines to flash
				ld a,4							; Upto 4 can be cleared at once
@line_loop:
				push af
				ld a,(bc)
				inc bc
				or a							; If run out of lines, exit immediately
				jp nz,@+print
	@quit:
				pop af
				pop af
				ret

@print:
				push bc
				call @+find_map_posA			; Find logical map position of line in HL
				call @+clear_blocksHL			; Clear logical map in nice animation
				call @+find_screen_lineA		; Find position on screen of graphics to print

				ld a,10							; Check 10 blocks in each row
@print_loop:
				ex af,af'

	@test_block:								; Check if block in position (will be cleared over time)
				ld a,(hl)
				cp -1
	@call_type:	call 0							; Set to either @print_block or @print_flash
				inc hl

	@next_block:
				ld a,4
				add e
				ld e,a

				ex af,af'
				dec a
				jp nz,@-print_loop

				pop bc
				pop af
				dec a
				jp nz,@-line_loop

	@flash_border:								; If there's a full tetris (all 4 lines to be cleared) flash border too
	@tetris_flash: ld a,0
				out (BorderReg),a

				pop af
				ret


@print_block:									; Two print types either print white blocks or originally set type
				jp z,@+print_blank
				ld b,a
				ex de,hl
				call gfx.print_blockBHL
				ex de,hl
				ret
@print_flash:
				jp z,@+print_blank
				ld b,gfx.white
				ex de,hl
				call gfx.print_blockBHL
				ex de,hl
				ret
@print_blank:
; print background back again
				ex de,hl
				call gfx.clear_blockHL
				ex de,hl
				ret

;----------------------------------------------
@find_map_posA:
; Return HL = start of line A in logical map
				push de
	@mult12:
				ld l,a
				ld e,a
				ld h,0
				ld d,h
				add hl,hl
				add hl,de
				add hl,hl
				add hl,hl
	@find_offset:
				ld de,well+1
				add hl,de

				pop de
				ret

@find_screen_lineA:
; Return DE = start address of graphical data of line A
				push af

				sub 4
				add a
				add a
				add &0a
				ld d,a
				ld e,&28+4

				pop af
				ret

;----------------------------------------------
@clear_blocksHL:
; Clear some block in logical line at HL and animation frame B
				push af
				push de
				push hl

	@test_timer:								; Only start clearing just before end of flashes
				ld a,(flash.timer)
				cp 21
				jp nc,@+end

	@find_left:									; Clear left side from middle moving left
				srl a
				srl a
				dec a
				bit 7,a
				jp nz,@+end
				ld e,a
				ld d,0

				push af
				push hl
				add hl,de
				ld (hl),-1
				pop hl
				pop af
	@find_right:
				neg
				add 9
				ld e,a
				ld d,0
				add hl,de
				ld (hl),-1
	@end:
				pop hl
				pop de
				pop af
				ret


;----------------------------------------------
gs.clear_lines:
; Move the lines above the cleared lines down to fill gaps.
				push af

				ld hl,full_lines+3				; Start at top lines so they don't get moved by lower ones
				ld b,4
	@loop:
				ld a,(hl)
				dec hl
				or a
				call nz,@move_downA				; Only move if there's an entry for this line
				djnz @-loop

				call gfx.print_full_map
				call well.find_height			; Update top Y coord of well

	@play_sfx:									; Play thump when rest of blocks fall down
				ld c,sfx.move_down
				call sfx.setC.out

	@set_game_state:							; Move to new tet generation afterwards
				ld a,gs.create
				ld (game_state),a

				pop af
				ret

@move_downA:
; Move game field down one block into line A.  Also update buffered screen
				push bc
				push hl
	@update_map:								; Move game field down one block into line A.
				call @-find_map_posA			; HL = logical map pos of empty line
	@find_start:								; Find end of one line up from empty line
				ld e,l
				ld d,h
				dec de
				dec de
				ld bc,10						; Find end of empty line (including wall)
				add hl,bc
				ex de,hl

	@loop:										; copy line down, A counts amount of loops to do
				for 12,ldd
				dec a
				jp nz,@-loop

	@empty_top_line:
				ld hl,well+1
				ld de,well+2
				ld bc,9
				ld (hl),-1
				ldir

				pop hl
				pop bc
				ret

;----------------------------------------------
gs.print_go_msg:
; Game has ended, print game over messages and wait for keypress
				push af

@test_print:									; Update message counter, print if still new frames
	go_msg_dirty: ld a,0
				dec a
				or a
				jp z,@+test_timer
	@print:
				ld (go_msg_dirty+1),a
				call hud.print_game_over
@test_timer:
	go_timer:	ld hl,go_length
				dec hl
				ld (go_timer+1),hl
	@check_fade_out:
				ld a,h
				cp 1
				jr nz,@+test_end
				ld a,l
				or a
				jr nz,@+test_end
	@music_fade:
				ld a,Yes
				ld (music.fade.on),a
				jr @+test_keypress
	@test_end:
				ld a,h
				or l
				or a
				jr z,@+set_end

@test_keypress:
				ld a,(keys.processed)
				or a
				jp nz,@+set_end
				pop af
				ret
@set_end:
				ld a,gs.end
				ld (game_state),a
				call music.off
				pop af
				ret

;==============================================
auto.end:
auto.len:		equ auto.end-auto.start

print "-----------------------------------------------------------------------------------"
print "auto.end", auto.end, "auto.len", auto.len
print "-----------------------------------------------------------------------------------"