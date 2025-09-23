;**************************************************************
;* Sistema de Semáforos - ATmega328P
;* ESTRUTURA BASE - Definições e configurações iniciais
;**************************************************************

.include "m328pdef.inc"

;*** DEFINIÇÕES DOS REGISTRADORES ***
.def	temp 		= 	R16		; Registrador temporário
.def	state_reg 	= 	R17		; Estado atual do sistema
.def	timer_count = 	R18		; Contador de tempo

;*** MAPEAMENTO DOS PINOS - SEMÁFOROS ***
; Semáforo A (Av. Álvaro - Pinos 2,3,4)
.equ	A_RED		= 	2		; PD2 - LED Vermelho A
.equ	A_YELLOW	= 	3		; PD3 - LED Amarelo A
.equ	A_GREEN		= 	4		; PD4 - LED Verde A

; Semáforo B (Av. Álvaro - Pinos 5,6,7)
.equ	B_RED		= 	5		; PD5 - LED Vermelho B
.equ	B_YELLOW	= 	6		; PD6 - LED Amarelo B
.equ	B_GREEN		= 	7		; PD7 - LED Verde B

; Semáforo C (R. Sandoval - Pinos 8,9,10)
.equ	C_RED		= 	0		; PB0 - LED Vermelho C
.equ	C_YELLOW	= 	1		; PB1 - LED Amarelo C
.equ	C_GREEN		= 	2		; PB2 - LED Verde C

; Semáforo D (R. Sandoval - Pinos 11,12,13)
.equ	D_RED		= 	3		; PB3 - LED Vermelho D
.equ	D_YELLOW	= 	4		; PB4 - LED Amarelo D
.equ	D_GREEN		= 	5		; PB5 - LED Verde D

;*** DISPLAY 7 SEGMENTOS ***
; Seleção dos dígitos
.equ	UNIT_DISPLAY	= 	6		; PB6 - Habilita unidade
.equ	DEC_DISPLAY		= 	7		; PB7 - Habilita dezena

; Segmentos (PC0-PC6)
.equ	SEG_A		= 	0		; PC0 - Segmento a
.equ	SEG_B		= 	1		; PC1 - Segmento b
.equ	SEG_C		= 	2		; PC2 - Segmento c
.equ	SEG_D		= 	3		; PC3 - Segmento d
.equ	SEG_E		= 	4		; PC4 - Segmento e
.equ	SEG_F		= 	5		; PC5 - Segmento f
.equ	SEG_G		= 	6		; PC6 - Segmento g

;*** DEFINIÇÕES DOS ESTADOS ***
.equ	STATE_S1	= 	1		; A=Verde, B=Verde, C=Vermelho, D=Vermelho
.equ	STATE_S2	= 	2		; A=Verde, B=Amarelo, C=Vermelho, D=Vermelho
.equ	STATE_S3	= 	3		; A=Verde, B=Vermelho, C=Verde, D=Vermelho

;*** TEMPOS DOS ESTADOS (em segundos) ***
.equ	TIME_S1		= 	20		; 20 segundos
.equ	TIME_S2		= 	5		; 5 segundos
.equ	TIME_S3		= 	40		; 40 segundos

;*** CONFIGURAÇÕES DO TIMER ***
.equ	TIMER_PRESCALER = 1024
.equ	TIMER_1SEC		= 15624	; Para 1 segundo com prescaler 1024

;*** INÍCIO DO PROGRAMA ***
.cseg
.org 0x0000
	rjmp RESET

;*** CONFIGURAÇÃO INICIAL ***
RESET:
	; Configurar stack pointer
	ldi temp, LOW(RAMEND)
	out SPL, temp
	ldi temp, HIGH(RAMEND)
	out SPH, temp

	; Configurar portas de I/O
	rcall setup_ports

	; Configurar timer
	rcall setup_timer

	; Estado inicial
	ldi state_reg, STATE_S1
	ldi timer_count, TIME_S1

	; Aplicar estado inicial
	rcall apply_state

	; Habilitar interrupções
	sei

; Loop principal
main_loop:
	nop
	rjmp main_loop

;**************************************************************
;* CONFIGURAÇÃO DAS PORTAS
;**************************************************************
setup_ports:
	; PORTD (PD2-PD7) como saída - Semáforos A e B
	ldi temp, 0b11111100
	out DDRD, temp

	; PORTB (PB0-PB7) como saída - Semáforos C,D + Display
	ldi temp, 0b11111111
	out DDRB, temp

	; PORTC (PC0-PC6) como saída - Segmentos do display
	ldi temp, 0b01111111
	out DDRC, temp

	; Inicializar todas as saídas em nível baixo
	ldi temp, 0b00000000
	out PORTD, temp
	out PORTB, temp
	out PORTC, temp

	ret

;**************************************************************
;* CONFIGURAÇÃO DO TIMER1
;**************************************************************
setup_timer:
	; Timer1 em modo CTC (Clear Timer on Compare)
	ldi temp, 0b00000000
	sts TCCR1A, temp

	; Prescaler 1024, modo CTC
	ldi temp, 0b00001101
	sts TCCR1B, temp

	; Valor de comparação para 1 segundo
	ldi temp, HIGH(TIMER_1SEC)
	sts OCR1AH, temp
	ldi temp, LOW(TIMER_1SEC)
	sts OCR1AL, temp

	; Habilitar interrupção por comparação
	ldi temp, (1 << OCIE1A)
	sts TIMSK1, temp

	ret

;**************************************************************
;* APLICAR ESTADO ATUAL
;**************************************************************
apply_state:
	; Primeiro, apagar todos os LEDs
	rcall clear_all_leds

	; Aplicar o estado conforme state_reg
	cpi state_reg, STATE_S1
	breq apply_s1
	cpi state_reg, STATE_S2
	breq apply_s2
	cpi state_reg, STATE_S3
	breq apply_s3

	ret

apply_s1:
	; S1: A=Verde, B=Verde, C=Vermelho, D=Vermelho
	sbi PORTD, A_GREEN		; A Verde
	sbi PORTD, B_GREEN		; B Verde
	sbi PORTB, C_RED		; C Vermelho
	sbi PORTB, D_RED		; D Vermelho
	ret

apply_s2:
	; S2: A=Verde, B=Amarelo, C=Vermelho, D=Vermelho
	sbi PORTD, A_GREEN		; A Verde
	sbi PORTD, B_YELLOW		; B Amarelo
	sbi PORTB, C_RED		; C Vermelho
	sbi PORTB, D_RED		; D Vermelho
	ret

apply_s3:
	; S3: A=Verde, B=Vermelho, C=Verde, D=Vermelho
	sbi PORTD, A_GREEN		; A Verde
	sbi PORTD, B_RED		; B Vermelho
	sbi PORTB, C_GREEN		; C Verde
	sbi PORTB, D_RED		; D Vermelho
	ret

;**************************************************************
;* APAGAR TODOS OS LEDs
;**************************************************************
clear_all_leds:
	; Apagar LEDs dos semáforos A e B (PORTD)
	cbi PORTD, A_RED
	cbi PORTD, A_YELLOW
	cbi PORTD, A_GREEN
	cbi PORTD, B_RED
	cbi PORTD, B_YELLOW
	cbi PORTD, B_GREEN

	; Apagar LEDs dos semáforos C e D (PORTB)
	cbi PORTB, C_RED
	cbi PORTB, C_YELLOW
	cbi PORTB, C_GREEN
	cbi PORTB, D_RED
	cbi PORTB, D_YELLOW
	cbi PORTB, D_GREEN

	ret

;**************************************************************
;* PLACEHOLDER para funcionalidades futuras
;**************************************************************

; TODO: Implementar interrupção do Timer1
; TODO: Implementar máquina de estados completa
; TODO: Implementar display de 7 segmentos
; TODO: Implementar comunicação UART
