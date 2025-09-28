.def    temp        = r16
.def    state_reg   = r17
.def    timer_count = r18
.def    dezena      = r19
.def    unidade     = r20
.def    multiplex   = r21

.equ    STATE_S1    = 0
.equ    STATE_S2    = 1
.equ    STATE_S3    = 2
.equ    STATE_S4    = 3
.equ    STATE_S5    = 4
.equ    STATE_S6    = 5
.equ    STATE_S7    = 6
.equ    STATE_S8    = 7
.equ    STATE_S9    = 8
.equ    STATE_S10   = 9
.equ    STATE_S11   = 10
.equ    STATE_S12   = 11

.equ    TIME_S1     = 20
.equ    TIME_S2     = 5
.equ    TIME_S3     = 40
.equ    TIME_S4     = 5
.equ    TIME_S5     = 15
.equ    TIME_S6     = 5
.equ    TIME_S7     = 25
.equ    TIME_S8     = 5
.equ    TIME_S9     = 0
.equ    TIME_S10    = 0
.equ    TIME_S11    = 0
.equ    TIME_S12    = 20

.equ    TIMER_1SEC  = 15624

.equ    PORTD_S1    = 0b10010000
.equ    PORTD_S2    = 0b01010000
.equ    PORTD_S3    = 0b00110000
.equ    PORTD_S4    = 0b00101000
.equ    PORTD_S5    = 0b00100000
.equ    PORTD_S6    = 0b00100000
.equ    PORTD_S7    = 0b00100000
.equ    PORTD_S8    = 0b00100000
.equ    PORTD_S9    = 0b00100000
.equ    PORTD_S10   = 0b00100000
.equ    PORTD_S11   = 0b00100000
.equ    PORTD_S12   = 0b00110000

.equ    PORTB_S1    = 0b00001001
.equ    PORTB_S2    = 0b00001001
.equ    PORTB_S3    = 0b00001100
.equ    PORTB_S4    = 0b00001100
.equ    PORTB_S5    = 0b00001100
.equ    PORTB_S6    = 0b00001010
.equ    PORTB_S7    = 0b00110000
.equ    PORTB_S8    = 0b00010001
.equ    PORTB_S9    = 0b00001001
.equ    PORTB_S10   = 0b00001001
.equ    PORTB_S11   = 0b00001001
.equ    PORTB_S12   = 0b00001001

.cseg
.org 0x0000
    rjmp    reset_handler
.org OC1Aaddr
    rjmp    timer1_compa_isr
.org OC0Aaddr
    rjmp    timer0_compa_isr

reset_handler:
    ldi     temp, LOW(RAMEND)
    out     SPL, temp
    ldi     temp, HIGH(RAMEND)
    out     SPH, temp

    rcall   setup_ports
    rcall   setup_timer1
    rcall   setup_timer0

    ldi     state_reg, STATE_S1
    ldi     timer_count, TIME_S1
    ldi     multiplex, 0
    rcall   apply_state

    sei

main_loop:
    nop
    rjmp    main_loop

setup_ports:
    ldi     temp, 0b11111100
    out     DDRD, temp
    ldi     temp, 0
    out     PORTD, temp

    ldi     temp, 0b00111111
    out     DDRB, temp
    ldi     temp, 0
    out     PORTB, temp

    ldi     temp, 0b00111111
    out     DDRC, temp
    ldi     temp, 0
    out     PORTC, temp
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

setup_timer0:
    ldi     temp, 0b00000010
    out     TCCR0A, temp

    ldi     temp, 0b00000011
    out     TCCR0B, temp

    ldi     temp, 124
    out     OCR0A, temp

    ldi     temp, (1<<OCIE0A)
    sts     TIMSK0, temp
    ret

apply_state:
    cpi     state_reg, STATE_S1
    breq    apply_s1
    cpi     state_reg, STATE_S2
    breq    apply_s2
    cpi     state_reg, STATE_S3
    breq    apply_s3
    cpi     state_reg, STATE_S4
    breq    apply_s4
    cpi     state_reg, STATE_S5
    breq    apply_s5
    cpi     state_reg, STATE_S6
    breq    apply_s6
    cpi     state_reg, STATE_S7
    breq    apply_s7
    cpi     state_reg, STATE_S8
    breq    apply_s8
    cpi     state_reg, STATE_S9
    breq    apply_s9
    cpi     state_reg, STATE_S10
    breq    apply_s10
    cpi     state_reg, STATE_S11
    breq    apply_s11
    cpi     state_reg, STATE_S12
    breq    apply_s12
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

apply_s4:
    ldi     temp, PORTD_S4
    out     PORTD, temp
    ldi     temp, PORTB_S4
    out     PORTB, temp
    ret

apply_s5:
    ldi     temp, PORTD_S5
    out     PORTD, temp
    ldi     temp, PORTB_S5
    out     PORTB, temp
    ret

apply_s6:
    ldi     temp, PORTD_S6
    out     PORTD, temp
    ldi     temp, PORTB_S6
    out     PORTB, temp
    ret

apply_s7:
    ldi     temp, PORTD_S7
    out     PORTD, temp
    ldi     temp, PORTB_S7
    out     PORTB, temp
    ret

apply_s8:
    ldi     temp, PORTD_S8
    out     PORTD, temp
    ldi     temp, PORTB_S8
    out     PORTB, temp
    ret

apply_s9:
    ldi     temp, PORTD_S9
    out     PORTD, temp
    ldi     temp, PORTB_S9
    out     PORTB, temp
    ret

apply_s10:
    ldi     temp, PORTD_S10
    out     PORTD, temp
    ldi     temp, PORTB_S10
    out     PORTB, temp
    ret

apply_s11:
    ldi     temp, PORTD_S11
    out     PORTD, temp
    ldi     temp, PORTB_S11
    out     PORTB, temp
    ret

apply_s12:
    ldi     temp, PORTD_S12
    out     PORTD, temp
    ldi     temp, PORTB_S12
    out     PORTB, temp
    ret

; ---------- DISPLAY ----------
calculate_digits:
    push    r22
    mov     r22, timer_count
    clr     dezena
    ldi     temp, 10
calc_loop:
    cp      r22, temp
    brlo    calc_done
    sub     r22, temp
    inc     dezena
    rjmp    calc_loop
calc_done:
    mov     unidade, r22
    pop     r22
    ret

display_cd4511:
    cpi     state_reg, STATE_S1
    breq    show_display
    cpi     state_reg, STATE_S2
    breq    show_display
    cpi     state_reg, STATE_S3
    breq    show_display
    
    ldi     temp, 0b00110000
    out     PORTC, temp
    ret

show_display:
    rcall   calculate_digits
    inc     multiplex
    andi    multiplex, 0x01
    brne    show_unidade_display
show_dezena_display:
    ldi     temp, 0b00010000
    mov     r22, dezena
    andi    r22, 0x0F
    or      temp, r22
    out     PORTC, temp
    ret
show_unidade_display:
    ldi     temp, 0b00100000
    mov     r22, unidade
    andi    r22, 0x0F
    or      temp, r22
    out     PORTC, temp
    ret

; ---------- TIMER0 ISR (DISPLAY) ----------
timer0_compa_isr:
    push    temp
    push    r22
    in      temp, SREG
    push    temp

    rcall   display_cd4511

    pop     temp
    out     SREG, temp
    pop     r22
    pop     temp
    reti

; ---------- TIMER1 ISR (SEMÁFORO) ----------
timer1_compa_isr:
    push    temp
    in      temp, SREG
    push    temp

    tst     timer_count        ; se = 0 ? transição imediata
    breq    do_transition

    dec     timer_count
    brne    timer_exit         ; ainda não acabou o tempo ? sai

do_transition:
    cpi     state_reg, STATE_S1
    breq    to_s2
    cpi     state_reg, STATE_S2
    breq    to_s3
    cpi     state_reg, STATE_S3
    breq    to_s4
    cpi     state_reg, STATE_S4
    breq    to_s5
    cpi     state_reg, STATE_S5
    breq    to_s6
    cpi     state_reg, STATE_S6
    breq    to_s7
    cpi     state_reg, STATE_S7
    breq    to_s8
    cpi     state_reg, STATE_S8
    breq    to_s9
    cpi     state_reg, STATE_S9
    breq    to_s10
    cpi     state_reg, STATE_S10
    breq    to_s11
    cpi     state_reg, STATE_S11
    breq    to_s12
    rjmp    to_s1

timer_exit:
    pop     temp
    out     SREG, temp
    pop     temp
    reti

to_s1:
    ldi     state_reg, STATE_S1
    ldi     timer_count, TIME_S1
    rcall   apply_state
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

to_s4:
    ldi     state_reg, STATE_S4
    ldi     timer_count, TIME_S4
    rcall   apply_state
    rjmp    timer_exit

to_s5:
    ldi     state_reg, STATE_S5
    ldi     timer_count, TIME_S5
    rcall   apply_state
    rjmp    timer_exit

to_s6:
    ldi     state_reg, STATE_S6
    ldi     timer_count, TIME_S6
    rcall   apply_state
    rjmp    timer_exit

to_s7:
    ldi     state_reg, STATE_S7
    ldi     timer_count, TIME_S7
    rcall   apply_state
    rjmp    timer_exit

to_s8:
    ldi     state_reg, STATE_S8
    ldi     timer_count, TIME_S8
    rcall   apply_state
    rjmp    timer_exit

to_s9:
    ldi     state_reg, STATE_S9
    ldi     timer_count, TIME_S9
    rcall   apply_state

to_s10:
    ldi     state_reg, STATE_S10
    ldi     timer_count, TIME_S10
    rcall   apply_state
    rjmp    timer_exit

to_s11:
    ldi     state_reg, STATE_S11
    ldi     timer_count, TIME_S11
    rcall   apply_state
    rjmp    timer_exit

to_s12:
    ldi     state_reg, STATE_S12
    ldi     timer_count, TIME_S12
    rcall   apply_state
    rjmp    timer_exit