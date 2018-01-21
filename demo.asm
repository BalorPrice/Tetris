; ROLLING DEMO

; This works by playing a game with certain elements in a different mode:

; * A different tune selection is chosen
; * The tet maker always collects next tet from the list
; * The inputs aren't taken from the keyboard, but from a list of movements and delays
; * When the end token for the demo is reached, it performs a fade-out and exits the game

;----------------------------------------------
demo.tet_list:									; List of blocks delivered in demo mode
				db tet.i,tet.z,tet.j,tet.l,tet.z,tet.t,tet.o,tet.s,tet.t,tet.i,tet.t,tet.z,-1

@left:			equ %00010000
@right:			equ %00001000
@down:			equ %00000100
@rotateC:		equ %10000000
@rotateAC:		equ %00000001
@no_input:		equ 0

demo.move_list:
; List of moves and delays after move made
; # frames input, input type.  Termination happens after x frames have elapsed
; Note to self:  This is an awful way to make a 'natural' looking demo, better to record a real player in future.

				db 13,@no_input					; Initial delay to start

				db 30,@no_input					; tet.i
				db 0,@left
				db 9,@no_input
				db 0,@left
				db 12,@no_input
				db 0,@left
				db 30,@no_input
				db 32,@down

				db 38,@no_input					; tet.z
				db 40,@down

				db 27,@no_input					; tet.j
				db 2,@rotateAC
				db 14,@no_input
				db 2,@rotateAC
				db 18,@no_input
				db 0,@left
				db 12,@no_input
				db 0,@left
				db 14,@no_input
				db 0,@left
				db 20,@no_input
				db 28,@down

				db 40,@no_input					; tet.l
				db 0,@right
				db 14,@no_input
				db 0,@right
				db 16,@no_input
				db 2,@rotateAC
				db 20,@no_input
				db 2,@rotateAC
				db 14,@no_input
				db 18,@down
				db 20,@no_input
				db 10,@down

				db 30,@no_input					; tet.z
				db 1,@right
				db 14,@no_input
				db 1,@left
				db 17,@no_input
				db 1,@left
				db 14,@no_input
				db 1,@left
				db 15,@no_input
				db 1,@left
				db 15,@no_input
				db 1,@left
				db 14,@no_input
				db 25,@down

				db 35,@no_input					; tet.t
				db 2,@rotateC
				db 12,@no_input
				db 2,@rotateC
				db 26,@no_input
				db 12,@down
				db 1,@right
				db 15,@no_input
				db 12,@down

				db 44,@no_input					; tet.o
				db 0,@right
				db 12,@no_input
				db 0,@right
				db 16,@no_input
				db 0,@right
				db 22,@no_input
				db 30,@down

				db 36,@no_input					; tet.s
				db 0,@right
				db 18,@no_input
				db 26,@down

				db 24,@no_input					; tet.t
				db 0,@left
				db 24,@no_input
				db 26,@down

				db 36,@no_input					; tet.i
				db 1,@right
				db 12,@no_input
				db 0,@rotateAC
				db 20,@no_input
				db 1,@right
				db 12,@no_input
				db 1,@right
				db 50,@no_input
				db 20,@down

				db 80,@no_input					; tet.t
				db 2,@rotateAC
				db 14,@no_input
				db 2,@rotateAC
				db 18,@no_input
				db 1,@left
				db 30,@no_input
				db 1,@left
				db 18,@no_input
				db 1,@left
				db 14,@no_input
				db 18,@down

				db 10,@no_input					; tet.z
				db 255,@no_input
				db 255,@no_input


demo.time:		equ 50*30						; Amount of frames demo plays for

;----------------------------------------------
demo.reset_tet:
; Reset position of tet feed in demo mode
				ld hl,demo.tet_list
				ld (@+tet_pos+1),hl
				ret

demo.get_tet:
; Return A with next tet from recorded list.
@tet_pos:		ld hl,0
				ld a,(hl)
				inc hl
				ld (@-tet_pos+1),hl
	@test_fade_out:								; Fade out music if next tet is blank
				ex af,af'
				ld a,(hl)
				cp -1
				jr nz,@+skip
		@start_fade:
				ld a,Yes
				ld (music.fade.on),a
		@skip:
				ex af,af'
				ret

;----------------------------------------------
demo.reset_input:
; Reset feed of key input in demo mode
				ld hl,demo.move_list
				ld (@+move_pos+1),hl
				xor a
				ld (@+input_timer+1),a

				ret

demo.get_input:
; Return A with processed key input for next frame
@update_timer:
	@input_timer: ld a,0
				or a
				jr z,@+new_move
				dec a
				ld (@-input_timer+1),a

				xor a
				ret
@new_move:
	@age_moves:
				ld a,(keys.curr)
				ld (keys.prev),a
	@move_pos:	ld hl,0
				ld a,(hl)
				ld (@-input_timer+1),a
				inc hl
				ld a,(hl)
				inc hl
				ld (@-move_pos+1),hl

				ld (keys.curr),a
				call keys.process
				ret

;----------------------------------------------
demo.reset_timer:
				ld hl,demo.time
				ld (@+timer+1),hl
				ret

demo.update_timer:
; Update overall segment timer, return Z if timer run out
				ld a,(demo.mode.on)
				cp On
				ret nz
@test_input:									; Check for any keypresses
				call keys.collect
				or a
				jr z,@+update_timer
	@quit:										; On any keypress, quit back to main attract mode
				pop hl
				call music.off
				call attract.demo_off
				call house.clear_screens
				jp main.attract_mode

@update_timer:
	@timer:		ld hl,demo.time
				dec hl
				ld (@-timer+1),hl
				ld a,h
				or l
				or a
				ret
