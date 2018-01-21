; COMPILATTION EQUATES

;----------------------------------------------
a:					equ 7
b:					equ 0
c:					equ 1
d:					equ 2
e:					equ 3
h:					equ 4
l:					equ 5

add_a:				equ &80+a
add_b:				equ &80+b
add_c:				equ &80+c
add_d:				equ &80+d
add_e:				equ &80+e
add_h:				equ &80+h
add_l:				equ &80+l

add_hl.bc:			equ &09
add_hl.sp:			equ &39

and_a:				equ &a0+a
and_b:				equ &a0+b
and_c:				equ &a0+c
and_d:				equ &a0+d
and_e:				equ &a0+e
and_h:				equ &a0+h
and_l:				equ &a0+l
and_n:				equ &e6

call_nn:			equ &cd
call_nz.nn:			equ &c4
call_nc.nn:			equ &d4

dec_sp:				equ &3b

exx_:				equ &d9

inc_a:				equ &ec
inc_b:				equ &04
inc_bc:				equ &03
inc_c:				equ &0c
inc_d:				equ &14
inc_de:				equ &13
inc_e:				equ &1c
inc_h:				equ &24
inc_hl:				equ &23
inc_.hl.:			equ &34
inc_ix:				equ &23dd					; 2-byte opcodes stored in lsb,msb order
inc_.ix.:			equ &34dd					; Follow with +n
inc_iy:				equ &23fd
inc_.iy.:			equ &fd34					; Follow with +n
inc_l:				equ &2c
inc_sp:				equ &33

jp_nn:				equ &c3						; Follow with address
jp_hl:				equ &e9
jp_iy1:				equ &fd
jp_iy2:				equ &e9

ld_a.n:				equ &3e

ld_a..bc.:			equ &0a
ld_a..de.:			equ &1a
ld_a..hl.:			equ &7e
ld_a..nn.:			equ &3a

ld_bc.nn:			equ &01
ld_de.nn:			equ &11
ld_hl.nn:			equ &21

ld_d.n:				equ &16

ld_d.a:				equ &50+a
ld_d.b:				equ &50+b
ld_d.c:				equ &50+c
ld_d.d:				equ &50+d
ld_d.e:				equ &50+e
ld_d.h:				equ &50+h
ld_d.l:				equ &50+l

ld_h.a:				equ &60+a
ld_h.b:				equ &60+b
ld_h.c:				equ &60+c
ld_h.d:				equ &60+d
ld_h.e:				equ &60+e
ld_h.h:				equ &60+h
ld_h.l:				equ &60+l

ld_l.a:				equ &68+a
ld_l.b:				equ &68+b
ld_l.c:				equ &68+c
ld_l.d:				equ &68+d
ld_l.e:				equ &68+e
ld_l.h:				equ &68+h
ld_l.l:				equ &68+l

ld_bc..nn.1:		equ &ed
ld_bc..nn.2:		equ &4b
ld_hl..nn.:			equ &2a
ld_.nn..hl:			equ &22

ld_.bc..a:			equ &02
ld_.de..a:			equ &12
ld_.hl..a:			equ &70+a
ld_.hl..b:			equ &70+b
ld_.hl..c:			equ &70+c
ld_.hl..d:			equ &70+d
ld_.hl..e:			equ &70+e
ld_.hl..h:			equ &70+h
ld_.hl..l:			equ &70+l
ld_.hl..n:			equ &36

ld_sp.hl:			equ &f9
ld_sp.ix:			equ &f9dd
ld_sp.iy:			equ &f9fd

neg_1:				equ &ed
neg_2:				equ &44
nop_:				equ &00

or_n:				equ &f6

out_.n..a:			equ &d3						; Follow with register

push_bc:			equ &c5
push_de:			equ &d5
push_hl:			equ &e5

ret_:				equ &c9

sub_n:				equ &d6
