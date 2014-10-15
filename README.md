ECE382_LCD
==========

Moving an 8x8 block

#Prelab

#Lab

##Physical Set-up

![alt test](http://i47.photobucket.com/albums/f189/erik_thompson2/20141014_211722_zpspdkpyl41.jpg)

###Device Communication


| Line | R12 | R13 | Purpose |
|:-:|:-:|:-:|:-:|
| 66  | NOKIA_DATA | 0xE7 | 8 pixel high pattern |
| 276 | #NOKIA_CMD | 0xB5 | Sets cursor on the correct row |
| 288 | #NOKIA_CMD | 0x10 | Sets upper 3 column address bits |
| 294 | #NOKIA_CMD | mask upper bits | Sets the lower 4 column address bits |

#### SW3 Waveform Analysis

| Line | Command/Data | 8-bit Packet |
|:-:|:-:|:-:|
| 66 | data | E7 (1110 0111) |
| 276 | command | B1 (1011 0101) |
| 288 | command | 10 (0001 0000) |
| 294 | command | 05 (0000 0101)

####Waveforms

Entire Waveform

![alt test](http://s47.photobucket.com/user/erik_thompson2/media/20141014_210525_zpsi1ewytal.jpg.html)

Line 66

![alt test](http://i47.photobucket.com/albums/f189/erik_thompson2/20141014_210602_zpszcwn4oq8.jpg)

Line 276

![alt test](http://i47.photobucket.com/albums/f189/erik_thompson2/20141014_210640_zpsj59zlqlx.jpg)

Line 288

![alt test](http://i47.photobucket.com/albums/f189/erik_thompson2/20141014_210724_zpsd4crschg.jpg)

Line 294

![alt test](http://i47.photobucket.com/albums/f189/erik_thompson2/20141014_210805_zpsumbl2ew6.jpg)

Reset  

This test showed the reset to last for approximately 19.375 ms
![alt test](http://i47.photobucket.com/albums/f189/erik_thompson2/20141014_211627_zpsrc1lnjpd.jpg)

##Writing Modes

![alt test](http://i47.photobucket.com/albums/f189/erik_thompson2/bitblock_zpsb7a76ffa.png)

##Functionality
###Required Functionality

To make this code work, I simply looped the given code that drew a line 8 times over.


```
drawBox:
	push	r12
	push	r13
	mov		r10, r12			; copies the Y position into r12
	mov		r11, r13			; copies the X position into r13
	call	#setAddress			; set the address of the box position
	mov 	#0x08, r8			; set the width of the box

draw:
	mov		#NOKIA_DATA, r12
	mov		#0xFF, r13			; draw an 8 pixel vertical bar
	call	#writeNokiaByte		; draws the pixels
	dec		r8					; decrement the counter
	jnz		draw			 ;keep drawing until we finish all 8 bars
	pop		r13
	pop		r12

	ret
```

###A Functionality

Defining the bits for the button presses
```
; the bits of P2IN corresponding to the switches
UP_B:		.equ	0x20
DOWN_B:		.equ	0x10
LEFT_B:		.equ	0x04
RIGHT_B:	.equ	0x02
```

Controls the movement of the box with the button presses
```
;-------------------------------------------------------------------------------
checkUP:
	bit.b	#UP_B, &P2IN		; Check if the up button was pressed
	jnz		checkDOWN			; if not pressed, check down button
	mov		#UP_B, r9			; if pressed, store bit5 of P2IN in r9
	sub		#1, r10				; move the box up
	jmp		click

;-------------------------------------------------------------------------------
checkDOWN:
	bit.b	#DOWN_B, &P2IN		; Check if down button was pressed
	jnz		checkLEFT			; if not pressed, check left button
	mov		#DOWN_B, r9			; if yes, store bit4 of P2IN in r9
	add		#1, r10				; move the box down
	jmp		click

;-------------------------------------------------------------------------------
checkLEFT:
	bit.b	#LEFT_B, &P2IN		; check if the left button is pressed
	jnz		checkRIGHT			; if not pressed, check right button
	mov		#LEFT_B, r9			; if yes, store bit 2 of P2IN in r9
	sub		#8, r11				; move the box to the left
	jmp		click

;-------------------------------------------------------------------------------
checkRIGHT:
	bit.b	#RIGHT_B, &P2IN		; check if the right button is pressed
	jnz		checkUP				; if not pressed, check the up button again
	mov		#RIGHT_B, r9		; if yes, store bit 1 of P2IN in r9
	add		#8, r11				; move the box to the right
	jmp		click
```

#Debugging
I had issues with how much to decrement and increment the column and row registers, as decrement by one works for the columns but not for the rows.

#Documentation

##Prelab
I worked with the following:  

C2C Bodin
C2C Jonas
C2C Terragnoli
C2C Park
C2C Lewandowsky
C2C Ruprecht
C2C Kiernan
C2C Borusas
C2C Her
C2C Bapty
C2C Cabusora
C2C Bolinger
C2C Wooden

##Lab
None
