# Tetris
A version of the classic game Tetris, for the Sam Coupé

Also named Cooking Circle Tetris or CC-Tetris to disambiguate from the de facto standard by David Gommeren.  It's written in Z80 assembler for a standard, unimproved 256K Sam Coupé computer.  This code was written pretty quickly and shouldn't be used as examples of good coding style.  I'm not kidding.  



CREDITS

In addition to my code, the source includes:

* Protracker player routines and Sam Coupe Diskimage manager by Andrew Collier
* Keyboard reading and redefine routines adapted from an original by Steve Taylor
* Various maths routines written/collated by Milos Bazelides
* St Basil Cathedral graphic converted from the Tengen NES original cartridge art 
* Music and tetronimo graphics converted by hand from the Tetris DX and Gameboy Tetris versions
* SAMDOS2 binary, needed for loading of object file from the compiled diskimage.



COMPILING AND PLAYING

This version is compiled with PYZ80, a freely-available Z80 cross-assembler found at http://www.intensity.org.uk/samcoupe/pyz80.html.  After installing PYZ80 you can compile the diskimage by running make_home.bat.  You'll need to amend the filepaths in this file for your system.

It can be run in SimCoupe or ASCD, both up-to-date popular emulators for the original machine, from https://wwww.simcoupe.org/ and http://www.keprt.cz/sam/

This can be used on a real Sam by converting the diskimage to a floppy disk with SAMDisk by Simon Owen, available from http://simonowen.com/samdisk/



GETTING STARTED 

The game is split into several modules.  Reading the source is best started in the auto.asm module, which includes overall game structure and includes other modules.  .raw files are Mode 4 data files that have been created in a Sam emulator and exported to the PC environment.  Other graphics have been exported into .asm files as longform data strings (DB statements).
