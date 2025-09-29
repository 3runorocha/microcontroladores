.def    temp        = r16
.def    state_reg   = r17
.def    timer_count = r18
.def    dezena      = r19
.def    unidade     = r20
.def    multiplex   = r21
.def    total_time_a = r24

.equ    STATE_S1    = 0
.equ    STATE_S2    = 1
.equ    STATE_S3    = 2
.equ    STATE_S4    = 3
.equ    STATE_S5    = 4
.equ    STATE_S6    = 5
.equ    STATE_S7    = 6

.equ    TIME_S1     = 20
.equ    TIME_S2     = 5
.equ    TIME_S3     = 60
.equ    TIME_S4     = 5
.equ    TIME_S5     = 25
.equ    TIME_S6     = 5
.equ    TIME_S7     = 20

.equ    TIMER_1SEC  = 15624

.equ    PORTD_S1    = 0b10010000 // A VERDE(20), B VERDE(20 TROCA), C VERMELHO(70), D VERMELHO(20) - DURAÇÃO 20s
.equ    PORTD_S2    = 0b01010000 // A VERDE(25), B AMARELO(5 TROCA), C VERMELHO(75 TROCA), D VERMELHO(25)- DURAÇÃO 5s
.equ    PORTD_S3    = 0b00110000 // A VERDE(85 TROCA), B VERMELHO(60), C VERDE(60 TROCA), D VERMELHO(85)- DURAÇÃO 60s
.equ    PORTD_S4    = 0b00101000 // A AMARELO(5 TROCA), B VERMELHO(65), C AMARELO(5 TROCA), D VERMELHO(90) - DURAÇÃO 5s
.equ    PORTD_S5    = 0b00100100
.equ    PORTD_S6    = 0b00100100
.equ    PORTD_S7    = 0b00100100

.equ    PORTB_S1    = 0b00001001 // A VERDE(20), B VERDE(20 TROCA), C VERMELHO(70), D VERMELHO(20)
.equ    PORTB_S2    = 0b00001001 // A VERDE(25), B AMARELO(5 TROCA), C VERMELHO(75 TROCA), D VERMELHO(25)
.equ    PORTB_S3    = 0b00001100 // A VERDE(85 TROCA), B VERMELHO(60), C VERDE(60 TROCA), D VERMELHO(85)
.equ    PORTB_S4    = 0b00001010 // A AMARELO(5 TROCA), B VERMELHO(65), C AMARELO(5 TROCA), D VERMELHO(90)
.equ    PORTB_S5    = 0b00100001
.equ    PORTB_S6    = 0b00010001
.equ    PORTB_S7    = 0b00001001

;*** USART parameters ***
#define CLOCK      16.0e6    ; Clock speed 16MHz
.equ    baud       = 9600    ; Baudrate
.equ    bps        = (int(CLOCK)/16/baud) - 1 ; Baud prescale

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
    rcall   setup_uart

    ldi     state_reg, STATE_S1
    ldi     timer_count, TIME_S1
    ldi     multiplex, 0

    ; Enviar mensagem inicial
    ldi     ZL, LOW(2*init_msg)
    ldi     ZH, HIGH(2*init_msg)
    rcall   puts

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

;*** Setup UART ***
setup_uart:
    ldi     temp, LOW(bps)      ; Load baud prescale low
    sts     UBRR0L, temp
    ldi     temp, HIGH(bps)     ; Load baud prescale high
    sts     UBRR0H, temp

    ldi     temp, (1<<RXEN0) | (1<<TXEN0)  ; Enable transmitter and receiver
    sts     UCSR0B, temp
    ret

;*** Serial communication subroutine ***
puts:
    push    temp
    push    r25

puts_loop:
    lpm     temp, Z+            ; Load character from program memory
    cpi     temp, 0x00          ; Check if null terminator
    breq    puts_end            ; Branch to end if null

puts_wait:
    lds     r25, UCSR0A         ; Load UCSR0A status
    sbrs    r25, UDRE0          ; Wait for empty transmit buffer
    rjmp    puts_wait           ; Loop until ready

    sts     UDR0, temp          ; Send character
    rjmp    puts_loop           ; Continue loop

puts_end:
    pop     r25
    pop     temp
    ret

apply_state:
    push    ZL
    push    ZH

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
    rjmp    apply_state_end

apply_s1:
    ldi     temp, PORTD_S1
    out     PORTD, temp
    ldi     temp, PORTB_S1
    out     PORTB, temp
    ldi     ZL, LOW(2*msg_s1)
    ldi     ZH, HIGH(2*msg_s1)
    rcall   puts
    rjmp    apply_state_end

apply_s2:
    ldi     temp, PORTD_S2
    out     PORTD, temp
    ldi     temp, PORTB_S2
    out     PORTB, temp
    ldi     ZL, LOW(2*msg_s2)
    ldi     ZH, HIGH(2*msg_s2)
    rcall   puts
    rjmp    apply_state_end

apply_s3:
    ldi     temp, PORTD_S3
    out     PORTD, temp
    ldi     temp, PORTB_S3
    out     PORTB, temp
    ldi     ZL, LOW(2*msg_s3)
    ldi     ZH, HIGH(2*msg_s3)
    rcall   puts
    rjmp    apply_state_end

apply_s4:
    ldi     temp, PORTD_S4
    out     PORTD, temp
    ldi     temp, PORTB_S4
    out     PORTB, temp
    ldi     ZL, LOW(2*msg_s4)
    ldi     ZH, HIGH(2*msg_s4)
    rcall   puts
    rjmp    apply_state_end

apply_s5:
    ldi     temp, PORTD_S5
    out     PORTD, temp
    ldi     temp, PORTB_S5
    out     PORTB, temp
    ldi     ZL, LOW(2*msg_s5)
    ldi     ZH, HIGH(2*msg_s5)
    rcall   puts
    rjmp    apply_state_end

apply_s6:
    ldi     temp, PORTD_S6
    out     PORTD, temp
    ldi     temp, PORTB_S6
    out     PORTB, temp
    ldi     ZL, LOW(2*msg_s6)
    ldi     ZH, HIGH(2*msg_s6)
    rcall   puts
    rjmp    apply_state_end

apply_s7:
    ldi     temp, PORTD_S7
    out     PORTD, temp
    ldi     temp, PORTB_S7
    out     PORTB, temp
    ldi     ZL, LOW(2*msg_s7)
    ldi     ZH, HIGH(2*msg_s7)
    rcall   puts

apply_state_end:
    pop     ZH
    pop     ZL
    ret

; ---------- DISPLAY ----------
calculate_total_time_a:
    push    r22
    push    r23
    clr     r22

    mov     r22, timer_count   ; começa com tempo restante do estado atual

    cpi     state_reg, STATE_S1
    breq    add_from_s1
    cpi     state_reg, STATE_S2
    breq    add_from_s2
    cpi     state_reg, STATE_S3
    breq    add_from_s3
    cpi     state_reg, STATE_S4
    breq    add_from_s4
    cpi     state_reg, STATE_S5
    breq    add_from_s5
    cpi     state_reg, STATE_S6
    breq    add_from_s6
    cpi     state_reg, STATE_S7
    breq    add_from_s7
    rjmp    calc_total_done

add_from_s1:
    ldi     r23, TIME_S2
    add     r22, r23
    ldi     r23, TIME_S3
    add     r22, r23
    ldi     r23, TIME_S4
    add     r22, r23
    rjmp    calc_total_done

add_from_s2:
    ldi     r23, TIME_S3
    add     r22, r23
    ldi     r23, TIME_S4
    add     r22, r23
    rjmp    calc_total_done

add_from_s3:
    ldi     r23, TIME_S4
    add     r22, r23
    rjmp    calc_total_done

add_from_s4:
    rjmp    calc_total_done

add_from_s5:
    ldi     r23, TIME_S6
    add     r22, r23
    ldi     r23, TIME_S7
    add     r22, r23
    ldi     r23, TIME_S1
    add     r22, r23
    rjmp    calc_total_done

add_from_s6:
    ldi     r23, TIME_S7
    add     r22, r23
    ldi     r23, TIME_S1
    add     r22, r23
    rjmp    calc_total_done

add_from_s7:
    ldi     r23, TIME_S1
    add     r22, r23
    rjmp    calc_total_done

calc_total_done:
    mov     total_time_a, r22   ; guarda no registrador dedicado
    pop     r23
    pop     r22
    ret

calculate_digits:
    push    r22
    rcall   calculate_total_time_a

    mov     r22, total_time_a   ; usa total_time_a e não timer_count
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
    cpi     state_reg, STATE_S4
    breq    show_display
    cpi     state_reg, STATE_S5
    breq    show_display
    cpi     state_reg, STATE_S6
    breq    show_display
    cpi     state_reg, STATE_S7
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

    dec     timer_count
    brne    timer_exit

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
    breq    to_s1

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

;*** Mensagens na memória de programa ***
init_msg:   .db "SemaforoAVR", 0x0A, 0x0D, 0x00
msg_s1:     .db "[Estado S1] Tempo: 20s", 0x0A, 0x0D, 0x00
msg_s2:     .db "[Estado S2] Tempo: 05s", 0x0A, 0x0D, 0x00
msg_s3:     .db "[Estado S3] Tempo: 60s", 0x0A, 0x0D, 0x00
msg_s4:     .db "[Estado S4] Tempo: 05s", 0x0A, 0x0D, 0x00
msg_s5:     .db "[Estado S5] Tempo: 25s", 0x0A, 0x0D, 0x00
msg_s6:     .db "[Estado S6] Tempo: 05s", 0x0A, 0x0D, 0x00
msg_s7:     .db "[Estado S7] Tempo: 20s", 0x0A, 0x0D, 0x00
