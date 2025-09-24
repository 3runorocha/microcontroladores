.def    temp        = r16
.def    state_reg   = r17
.def    timer_count = r18

.equ    STATE_S1    = 0
.equ    STATE_S2    = 1
.equ    STATE_S3    = 2

.equ    TIME_S1     = 20
.equ    TIME_S2     = 5
.equ    TIME_S3     = 40

.equ    TIMER_1SEC  = 15624

.equ    MASK_PORTD_INIT = 0b11111100
.equ    MASK_PORTB_INIT = 0b00111111

.equ    PORTD_S1    = 0b00110000
.equ    PORTD_S2    = 0b01010000
.equ    PORTD_S3    = 0b00100000

.equ    PORTB_S1    = 0b00001001
.equ    PORTB_S2    = 0b00001001
.equ    PORTB_S3    = 0b00001100

.cseg
.org 0x0000
    rjmp    reset_handler

.org OC1Aaddr
    rjmp    timer1_compa_isr

reset_handler:
    ldi     temp, LOW(RAMEND)
    out     SPL, temp
    ldi     temp, HIGH(RAMEND)
    out     SPH, temp
    
    rcall   setup_ports
    rcall   setup_timer1
    
    ldi     state_reg, STATE_S1
    ldi     timer_count, TIME_S1
    rcall   apply_state
    
    sei

main_loop:
    nop
    rjmp    main_loop

setup_ports:
    ldi     temp, MASK_PORTD_INIT
    out     DDRD, temp
    ldi     temp, 0
    out     PORTD, temp
    
    ldi     temp, MASK_PORTB_INIT
    out     DDRB, temp  
    ldi     temp, 0
    out     PORTB, temp
    
    ret

setup_timer1:
    ldi     temp, 0
    sts     TCCR1A, temp
    
    ldi     temp, 0b00001101
    sts     TCCR1B, temp
    
    ldi     temp, HIGH(TIMER_1SEC)
    sts     OCR1AH, temp
    ldi     temp, LOW(TIMER_1SEC)
    sts     OCR1AL, temp
    
    ldi     temp, (1<<OCIE1A)
    sts     TIMSK1, temp
    
    ret

apply_state:
    cpi     state_reg, STATE_S1
    breq    apply_s1
    cpi     state_reg, STATE_S2
    breq    apply_s2
    cpi     state_reg, STATE_S3
    breq    apply_s3
    ret

apply_s1:
    ldi     temp, PORTD_S1
    out     PORTD, temp
    ldi     temp, PORTB_S1
    out     PORTB, temp
    ret

apply_s2:
    ldi     temp, PORTD_S2
    out     PORTD, temp
    ldi     temp, PORTB_S2
    out     PORTB, temp
    ret

apply_s3:
    ldi     temp, PORTD_S3
    out     PORTD, temp
    ldi     temp, PORTB_S3
    out     PORTB, temp
    ret

timer1_compa_isr:
    push    temp
    in      temp, SREG
    push    temp
    
    dec     timer_count
    brne    timer_exit
    
    cpi     state_reg, STATE_S1
    breq    to_s2
    cpi     state_reg, STATE_S2
    breq    to_s3
    cpi     state_reg, STATE_S3
    breq    to_s1
    rjmp    timer_exit

to_s2:
    ldi     state_reg, STATE_S2
    ldi     timer_count, TIME_S2
    rcall   apply_state
    rjmp    timer_exit

to_s3:
    ldi     state_reg, STATE_S3
    ldi     timer_count, TIME_S3
    rcall   apply_state
    rjmp    timer_exit

to_s1:
    ldi     state_reg, STATE_S1
    ldi     timer_count, TIME_S1
    rcall   apply_state

timer_exit:
    pop     temp
    out     SREG, temp
    pop     temp
    reti
