;-------------------------------------------------------------------------------
;	Erik Thompson
;	15 October 2014
;	MSP430G2553
;	Basic: Draw an 8x8 pixel box. A: Move the box with button inputs
;-------------------------------------------------------------------------------
	.cdecls C,LIST,"msp430.h"		; BOILERPLATE	Include device header file

LCD1202_SCLK_PIN:				.equ	20h		; P1.5
LCD1202_MOSI_PIN: 				.equ	80h		; P1.7
LCD1202_CS_PIN:					.equ	01h		; P1.0
LCD1202_BACKLIGHT_PIN:			.equ	10h
LCD1202_RESET_PIN:				.equ	01h
NOKIA_CMD:						.equ	00h
NOKIA_DATA:						.equ	01h

STE2007_RESET:					.equ	0xE2
STE2007_DISPLAYALLPOINTSOFF:	.equ	0xA4
STE2007_POWERCONTROL:			.equ	0x28
STE2007_POWERCTRL_ALL_ON:		.equ	0x07
STE2007_DISPLAYNORMAL:			.equ	0xA6
STE2007_DISPLAYON:				.equ	0xAF

; center positions of the LCD
X_POS:	.equ	0x2c
Y_POS:	.equ	0x04

; the bits of P2IN corresponding to the switches
UP_B:		.equ	0x20
DOWN_B:		.equ	0x10
LEFT_B:		.equ	0x04
RIGHT_B:	.equ	0x02

 	.text								; BOILERPLATE	Assemble into program memory
	.retain								; BOILERPLATE	Override ELF conditional linking and retain current section
	.retainrefs							; BOILERPLATE	Retain any sections that have references to current section
	.global main						; BOILERPLATE

;-------------------------------------------------------------------------------
;           						main
;	r8		stores the box width (used as a counter)
;	r9		stores the bit used (corresponds to the switches)
;	r10		row value of cursor
;	r11		value of @r12
;
;	When calling writeNokiaByte:
;	r12		1-bit	Parameter to writeNokiaByte specifying command or data
;	r13		8-bit	data or command
;
;	when calling setAddress:
;	r12		row address
;	r13		column address
;-------------------------------------------------------------------------------
main:
	mov.w   #__STACK_END,SP				; Initialize stackpointer
	mov.w   #WDTPW|WDTHOLD, &WDTCTL  	; Stop watchdog timer
	dint								; disable interrupts

	call	#init						; initialize the MSP430
	call	#initNokia					; initialize the Nokia 1206
	call	#clearDisplay				; clear the display and get ready....

	mov		#Y_POS, r10					; centers the Y position
	mov		#X_POS, r11					; centers the X position

	call	#drawBox					; draw initial box

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

;-------------------------------------------------------------------------------
;	click
;	One of the four directional buttons has been pressed
;-------------------------------------------------------------------------------
click:
	bit.b	r9, &P2IN			; If button still pressed,
	jz		click				; wait for release

released:
	mov 	#0x08, r8			; Sets width of box to be drawn (counter to be decremented)
	mov		r10, r12			; copy over the rows and columns to r12 and r13
	mov		r11, r13
	call	#clearDisplay
	call	#setAddress
	call	#drawBox
	jmp		checkUP				; jump back to checking for input

;-------------------------------------------------------------------------------
;	Name:		drawBox
;	Inputs:		r12 (row), r13 (column)
;	Outputs:	none
;	Purpose:	Draws an 8x8 pixel box
;
;	Registers:	r12 - row address
;				r13 - column address
;-------------------------------------------------------------------------------
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

;-------------------------------------------------------------------------------
;	Name:		initNokia		68(rows)x92(columns)
;	Inputs:		none
;	Outputs:	none
;	Purpose:	Reset and initialize the Nokia Display
;
;	Registers:	r12 mainly used as the command specification for writeNokiaByte
;				r13 mainly used as the 8-bit command for writeNokiaByte
;-------------------------------------------------------------------------------
initNokia:
	push	r12
	push	r13

	bis.b	#LCD1202_CS_PIN, &P1OUT

	; This loop creates a nice delay for the reset low pulse
	bic.b	#LCD1202_RESET_PIN, &P2OUT
	mov		#0FFFFh, r12
delayNokiaResetLow:
	dec		r12
	jne		delayNokiaResetLow

	; This loop creates a nice delay for the reset high pulse
	bis.b	#LCD1202_RESET_PIN, &P2OUT
	mov		#0FFFFh, r12
delayNokiaResetHigh:
	dec		r12
	jne		delayNokiaResetHigh
	bic.b	#LCD1202_CS_PIN, &P1OUT

	; First write seems to come out a bit garbled - not sure cause
	; but it can't hurt to write a reset command twice
	mov		#NOKIA_CMD, r12
	mov		#STE2007_RESET, r13
	call	#writeNokiaByte

	mov		#NOKIA_CMD, r12
	mov		#STE2007_RESET, r13
	call	#writeNokiaByte

	mov		#NOKIA_CMD, r12
	mov		#STE2007_DISPLAYALLPOINTSOFF, r13
	call	#writeNokiaByte

	mov		#NOKIA_CMD, r12
	mov		#STE2007_POWERCONTROL | STE2007_POWERCTRL_ALL_ON, r13
	call	#writeNokiaByte

	mov		#NOKIA_CMD, r12
	mov		#STE2007_DISPLAYNORMAL, r13
	call	#writeNokiaByte

	mov		#NOKIA_CMD, r12
	mov		#STE2007_DISPLAYON, r13
	call	#writeNokiaByte

	pop		r13
	pop		r12

	ret

;-------------------------------------------------------------------------------
;	Name:		init
;	Inputs:		none
;	Outputs:	none
;	Purpose:	Setup the MSP430 to operate the Nokia 1202 Display
;-------------------------------------------------------------------------------
init:
	mov.b	#CALBC1_8MHZ, &BCSCTL1				; Setup fast clock
	mov.b	#CALDCO_8MHZ, &DCOCTL

	bis.w	#TASSEL_1 | MC_2, &TACTL
	bic.w	#TAIFG, &TACTL

	mov.b	#LCD1202_CS_PIN|LCD1202_BACKLIGHT_PIN|LCD1202_SCLK_PIN|LCD1202_MOSI_PIN, &P1OUT
	mov.b	#LCD1202_CS_PIN|LCD1202_BACKLIGHT_PIN|LCD1202_SCLK_PIN|LCD1202_MOSI_PIN, &P1DIR
	mov.b	#LCD1202_RESET_PIN, &P2OUT
	mov.b	#LCD1202_RESET_PIN, &P2DIR
	bis.b	#LCD1202_SCLK_PIN|LCD1202_MOSI_PIN, &P1SEL			; Select Secondary peripheral module function
	bis.b	#LCD1202_SCLK_PIN|LCD1202_MOSI_PIN, &P1SEL2			; by setting P1SEL and P1SEL2 = 1

	bis.b	#UCCKPH|UCMSB|UCMST|UCSYNC, &UCB0CTL0				; 3-pin, 8-bit SPI master
	bis.b	#UCSSEL_2, &UCB0CTL1								; SMCLK
	mov.b	#0x01, &UCB0BR0 									; 1:1
	mov.b	#0x00, &UCB0BR1
	bic.b	#UCSWRST, &UCB0CTL1

	; Buttons on the Nokia 1202
	;	S1		P2.1		Right
	;	S2		P2.2		Left
	;	S3		P2.3		Aux
	;	S4		P2.4		Bottom
	;	S5		P2.5		Up
	;
	;	7 6 5 4 3 2 1 0
	;	0 0 1 1 1 1 1 0		0x3E
	bis.b	#0x3E, &P2REN					; Pullup/Pulldown Resistor Enabled on P2.1 - P2.5
	bis.b	#0x3E, &P2OUT					; Assert output to pull-ups pin P2.1 - P2.5
	bic.b	#0x3E, &P2DIR

	ret

;-------------------------------------------------------------------------------
;	Name:		writeNokiaByte
;	Inputs:		r12 selects between (1) Data or (0) Command string
;				r13 the data or command byte
;	Outputs:	none
;	Purpose:	Write a command or data byte to the display using 9-bit format
;-------------------------------------------------------------------------------
writeNokiaByte:

	push	r12
	push	r13

	bic.b	#LCD1202_CS_PIN, &P1OUT							; LCD1202_SELECT
	bic.b	#LCD1202_SCLK_PIN | LCD1202_MOSI_PIN, &P1SEL	; Enable I/O function by clearing
	bic.b	#LCD1202_SCLK_PIN | LCD1202_MOSI_PIN, &P1SEL2	; LCD1202_DISABLE_HARDWARE_SPI;

	bit.b	#01h, r12
	jeq		cmd

	bis.b	#LCD1202_MOSI_PIN, &P1OUT						; LCD1202_MOSI_LO
	jmp		clock

cmd:
	bic.b	#LCD1202_MOSI_PIN, &P1OUT						; LCD1202_MOSI_HIGH

clock:
	bis.b	#LCD1202_SCLK_PIN, &P1OUT						; LCD1202_CLOCK		positive edge
	nop
	bic.b	#LCD1202_SCLK_PIN, &P1OUT						;					negative edge

	bis.b	#LCD1202_SCLK_PIN | LCD1202_MOSI_PIN, &P1SEL	; LCD1202_ENABLE_HARDWARE_SPI;
	bis.b	#LCD1202_SCLK_PIN | LCD1202_MOSI_PIN, &P1SEL2	;

	mov.b	r13, UCB0TXBUF

pollSPI:
	bit.b	#UCBUSY, &UCB0STAT
	jz		pollSPI											; while (UCB0STAT & UCBUSY);

	bis.b	#LCD1202_CS_PIN, &P1OUT							; LCD1202_DESELECT

	pop		r13
	pop		r12

	ret

;-------------------------------------------------------------------------------
;	Name:		clearDisplay
;	Inputs:		none
;	Outputs:	none
;	Purpose:	Writes 0x360 blank 8-bit columns to the Nokia display
;-------------------------------------------------------------------------------
clearDisplay:
	push	r11
	push	r12
	push	r13

	mov.w	#0x00, r12			; set display address to 0,0
	mov.w	#0x00, r13

	call	#setAddress

	mov.w	#0x01, r12			; write a "clear" set of pixels
	mov.w	#0x00, r13			; to every byt on the display

	mov.w	#0x360, r11			; loop counter
clearLoop:
	call	#writeNokiaByte
	dec.w	r11
	jnz		clearLoop


	call	#setAddress

	pop		r13
	pop		r12
	pop		r11

	ret

;-------------------------------------------------------------------------------
;	Name:		setAddress
;	Inputs:		r12		row
;				r13		col
;	Outputs:	none
;	Purpose:	Sets the cursor address on the 9 row x 96 column display
;-------------------------------------------------------------------------------
setAddress:
	push	r12
	push	r13

	; Since there are only 9 rows on the 1202, we can select the row in 4-bits
	mov.w	r12, r13			; Write a command, setup call to
	mov.w	#NOKIA_CMD, r12
	and.w	#0x0F, r13			; mask out any weird upper nibble bits and
	bis.w	#0xB0, r13			; mask in "B0" as the prefix for a page address....sets the row (goes down)
	call	#writeNokiaByte

	; Since there are only 96 columns on the 1202, we need 2 sets of 4-bits
	mov.w	#NOKIA_CMD, r12
	pop		r13					; make a copy of the column address in r13 from the stack
	push	r13
	rra.w	r13					; shift right 4 bits
	rra.w	r13
	rra.w	r13
	rra.w	r13
	and.w	#0x0F, r13			; mask out upper nibble
	bis.w	#0x10, r13			; 10 is the prefix for a upper column address
	call	#writeNokiaByte
	mov.w	#0x00, r2			; Write a command, setup call to
	pop		r13					; make a copy of the top of the stack
	push	r13
	and.w	#0x0F, r13
	call	#writeNokiaByte
	pop		r13
	pop		r12
	ret

;-------------------------------------------------------------------------------
;           System Initialization
;-------------------------------------------------------------------------------
	.global __STACK_END					; BOILERPLATE
	.sect 	.stack						; BOILERPLATE
	.sect   ".reset"                	; BOILERPLATE		MSP430 RESET Vector
	.short  main						; BOILERPLATE
