.include "m328pdef.inc"

.def	temp 		= 	R16
.def	state_reg 	= 	R17
.def	timer_count = 	R18

; Semáforo A (Av. Álvaro)
.equ	A_RED		= 	2		; PD2
.equ	A_YELLOW	= 	3		; PD3
.equ	A_GREEN		= 	4		; PD4

; Semáforo B (Av. Álvaro)
.equ	B_RED		= 	5		; PD5
.equ	B_YELLOW	= 	6		; PD6
.equ	B_GREEN		= 	7		; PD7

; Semáforo C (R. Sandoval)
.equ	C_RED		= 	0		; PB0
.equ	C_YELLOW	= 	1		; PB1
.equ	C_GREEN		= 	2		; PB2

; Semáforo D (R. Sandoval)
.equ	D_RED		= 	3		; PB3
.equ	D_YELLOW	= 	4		; PB4
.equ	D_GREEN		= 	5		; PB5

.equ	UNIT_DISPLAY	= 	6		; PB6
.equ	DEC_DISPLAY		= 	7		; PB7

.equ	SEG_A		= 	0		; PC0
.equ	SEG_B		= 	1		; PC1
.equ	SEG_C		= 	2		; PC2
.equ	SEG_D		= 	3		; PC3
.equ	SEG_E		= 	4		; PC4
.equ	SEG_F		= 	5		; PC5
.equ	SEG_G		= 	6		; PC6

.equ	STATE_S1	= 	1
.equ	STATE_S2	= 	2
.equ	STATE_S3	= 	3

.equ	TIME_S1		= 	20
.equ	TIME_S2		= 	5
.equ	TIME_S3		= 	40

.equ	TIMER_PRESCALER = 1024
.equ	TIMER_1SEC		= 15624

.cseg
.org 0x0000
	rjmp RESET

RESET:
	ldi temp, LOW(RAMEND)
	out SPL, temp
	ldi temp, HIGH(RAMEND)
	out SPH, temp

	rcall setup_ports
	rcall setup_timer

	ldi state_reg, STATE_S1
	ldi timer_count, TIME_S1

	rcall apply_state

	sei

main_loop:
	nop
	rjmp main_loop

setup_ports:
	ldi temp, 0b11111100
	out DDRD, temp

	ldi temp, 0b11111111
	out DDRB, temp

	ldi temp, 0b01111111
	out DDRC, temp

	ldi temp, 0b00000000
	out PORTD, temp
	out PORTB, temp
	out PORTC, temp

	ret

setup_timer:
	ldi temp, 0b00000000
	sts TCCR1A, temp

	ldi temp, 0b00001101
	sts TCCR1B, temp

	ldi temp, HIGH(TIMER_1SEC)
	sts OCR1AH, temp
	ldi temp, LOW(TIMER_1SEC)
	sts OCR1AL, temp

	ldi temp, (1 << OCIE1A)
	sts TIMSK1, temp

	ret

apply_state:
	rcall clear_all_leds

	cpi state_reg, STATE_S1
	breq apply_s1
	cpi state_reg, STATE_S2
	breq apply_s2
	cpi state_reg, STATE_S3
	breq apply_s3

	ret

apply_s1:
	sbi PORTD, A_GREEN
	sbi PORTD, B_GREEN
	sbi PORTB, C_RED
	sbi PORTB, D_RED
	ret

apply_s2:
	sbi PORTD, A_GREEN
	sbi PORTD, B_YELLOW
	sbi PORTB, C_RED
	sbi PORTB, D_RED
	ret

apply_s3:
	sbi PORTD, A_GREEN
	sbi PORTD, B_RED
	sbi PORTB, C_GREEN
	sbi PORTB, D_RED
	ret

clear_all_leds:
	cbi PORTD, A_RED
	cbi PORTD, A_YELLOW
	cbi PORTD, A_GREEN
	cbi PORTD, B_RED
	cbi PORTD, B_YELLOW
	cbi PORTD, B_GREEN

	cbi PORTB, C_RED
	cbi PORTB, C_YELLOW
	cbi PORTB, C_GREEN
	cbi PORTB, D_RED
	cbi PORTB, D_YELLOW
	cbi PORTB, D_GREEN

	ret
