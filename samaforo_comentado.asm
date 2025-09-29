; registradores de uso geral
.def    temp        = r16       ; temporario para operacoes gerais
.def    state_reg   = r17       ; armazena estado atual do semaforo
.def    timer_count = r18       ; contador regressivo de tempo
.def    dezena      = r19       ; digito das dezenas do display
.def    unidade     = r20       ; digito das unidades do display
.def    multiplex   = r21       ; controla alternancia entre displays
.def    total_time_a = r24      ; tempo total calculado da via a

; definicao dos estados do semaforo
.equ    STATE_S1    = 0         ; via a verde, via b vermelho
.equ    STATE_S2    = 1         ; via a amarelo, via b vermelho
.equ    STATE_S3    = 2         ; via a vermelho, via b verde
.equ    STATE_S4    = 3         ; via a vermelho, via b amarelo
.equ    STATE_S5    = 4         ; via a verde pedestre, via b vermelho
.equ    STATE_S6    = 5         ; via a amarelo pedestre, via b vermelho
.equ    STATE_S7    = 6         ; via a vermelho pedestre, via b vermelho

; duracao de cada estado em segundos
.equ    TIME_S1     = 20
.equ    TIME_S2     = 5
.equ    TIME_S3     = 60
.equ    TIME_S4     = 5
.equ    TIME_S5     = 25
.equ    TIME_S6     = 5
.equ    TIME_S7     = 20

; valor para gerar interrupcao a cada 1 segundo com prescaler 1024
.equ    TIMER_1SEC  = 15624

; configuracao dos pinos portd para cada estado
.equ    PORTD_S1    = 0b10010000
.equ    PORTD_S2    = 0b01010000
.equ    PORTD_S3    = 0b00110000
.equ    PORTD_S4    = 0b00101000
.equ    PORTD_S5    = 0b00100100
.equ    PORTD_S6    = 0b00100100
.equ    PORTD_S7    = 0b00100100

; configuracao dos pinos portb para cada estado
.equ    PORTB_S1    = 0b00001001
.equ    PORTB_S2    = 0b00001001
.equ    PORTB_S3    = 0b00001100
.equ    PORTB_S4    = 0b00001010
.equ    PORTB_S5    = 0b00100001
.equ    PORTB_S6    = 0b00010001
.equ    PORTB_S7    = 0b00001001

; configuracao da comunicacao serial
#define CLOCK      16.0e6       ; frequencia do clock 16mhz
.equ    baud       = 9600       ; taxa de transmissao
.equ    bps        = (int(CLOCK)/16/baud) - 1

.cseg
.org 0x0000
    rjmp    reset_handler          ; vetor de reset
.org OC1Aaddr
    rjmp    timer1_compa_isr       ; interrupcao timer1 (1 segundo)
.org OC0Aaddr
    rjmp    timer0_compa_isr       ; interrupcao timer0 (multiplexacao display)

; rotina de inicializacao do sistema
reset_handler:
    ldi     temp, LOW(RAMEND)
    out     SPL, temp
    ldi     temp, HIGH(RAMEND)
    out     SPH, temp              ; inicializa pilha

    rcall   setup_ports            ; configura portas io
    rcall   setup_timer1           ; configura timer de 1 segundo
    rcall   setup_timer0           ; configura timer de multiplexacao
    rcall   setup_uart             ; configura comunicacao serial

    ldi     state_reg, STATE_S1    ; inicia no estado s1
    ldi     timer_count, TIME_S1   ; carrega tempo do estado s1
    ldi     multiplex, 0           ; inicia multiplexacao

    ldi     ZL, LOW(2*init_msg)
    ldi     ZH, HIGH(2*init_msg)
    rcall   puts                   ; envia mensagem inicial

    rcall   apply_state            ; aplica configuracao inicial

    sei                            ; habilita interrupcoes globais

; laco principal vazio, tudo ocorre por interrupcoes
main_loop:
    nop
    rjmp    main_loop

; configura direcao e estado inicial das portas
setup_ports:
    ldi     temp, 0b11111100
    out     DDRD, temp             ; portd bits 2-7 como saida
    ldi     temp, 0
    out     PORTD, temp

    ldi     temp, 0b00111111
    out     DDRB, temp             ; portb bits 0-5 como saida
    ldi     temp, 0
    out     PORTB, temp

    ldi     temp, 0b00111111
    out     DDRC, temp             ; portc bits 0-5 como saida (display)
    ldi     temp, 0
    out     PORTC, temp
    ret

; configura timer1 para gerar interrupcao a cada 1 segundo
setup_timer1:
    ldi     temp, 0
    sts     TCCR1A, temp           ; modo ctc

    ldi     temp, 0b00001101
    sts     TCCR1B, temp           ; prescaler 1024, modo ctc

    ldi     temp, HIGH(TIMER_1SEC)
    sts     OCR1AH, temp
    ldi     temp, LOW(TIMER_1SEC)
    sts     OCR1AL, temp           ; valor de comparacao

    ldi     temp, (1<<OCIE1A)
    sts     TIMSK1, temp           ; habilita interrupcao por comparacao
    ret

; configura timer0 para multiplexacao dos displays
setup_timer0:
    ldi     temp, 0b00000010
    out     TCCR0A, temp           ; modo ctc

    ldi     temp, 0b00000011
    out     TCCR0B, temp           ; prescaler 64

    ldi     temp, 124
    out     OCR0A, temp            ; interrupcao rapida para multiplex

    ldi     temp, (1<<OCIE0A)
    sts     TIMSK0, temp           ; habilita interrupcao
    ret

; configura comunicacao serial uart
setup_uart:
    ldi     temp, LOW(bps)
    sts     UBRR0L, temp
    ldi     temp, HIGH(bps)
    sts     UBRR0H, temp           ; configura baud rate

    ldi     temp, (1<<RXEN0) | (1<<TXEN0)
    sts     UCSR0B, temp           ; habilita transmissao e recepcao
    ret

; envia string terminada em null pela serial
puts:
    push    temp
    push    r25

puts_loop:
    lpm     temp, Z+               ; le byte da memoria de programa
    cpi     temp, 0x00
    breq    puts_end               ; terminou string

puts_wait:
    lds     r25, UCSR0A
    sbrs    r25, UDRE0
    rjmp    puts_wait              ; aguarda buffer disponivel

    sts     UDR0, temp             ; envia byte
    rjmp    puts_loop

puts_end:
    pop     r25
    pop     temp
    ret

; aplica configuracao de hardware conforme estado atual
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

; configura portas e envia mensagem para estado s1
apply_s1:
    ldi     temp, PORTD_S1
    out     PORTD, temp
    ldi     temp, PORTB_S1
    out     PORTB, temp
    ldi     ZL, LOW(2*msg_s1)
    ldi     ZH, HIGH(2*msg_s1)
    rcall   puts
    rjmp    apply_state_end

; configura portas e envia mensagem para estado s2
apply_s2:
    ldi     temp, PORTD_S2
    out     PORTD, temp
    ldi     temp, PORTB_S2
    out     PORTB, temp
    ldi     ZL, LOW(2*msg_s2)
    ldi     ZH, HIGH(2*msg_s2)
    rcall   puts
    rjmp    apply_state_end

; configura portas e envia mensagem para estado s3
apply_s3:
    ldi     temp, PORTD_S3
    out     PORTD, temp
    ldi     temp, PORTB_S3
    out     PORTB, temp
    ldi     ZL, LOW(2*msg_s3)
    ldi     ZH, HIGH(2*msg_s3)
    rcall   puts
    rjmp    apply_state_end

; configura portas e envia mensagem para estado s4
apply_s4:
    ldi     temp, PORTD_S4
    out     PORTD, temp
    ldi     temp, PORTB_S4
    out     PORTB, temp
    ldi     ZL, LOW(2*msg_s4)
    ldi     ZH, HIGH(2*msg_s4)
    rcall   puts
    rjmp    apply_state_end

; configura portas e envia mensagem para estado s5
apply_s5:
    ldi     temp, PORTD_S5
    out     PORTD, temp
    ldi     temp, PORTB_S5
    out     PORTB, temp
    ldi     ZL, LOW(2*msg_s5)
    ldi     ZH, HIGH(2*msg_s5)
    rcall   puts
    rjmp    apply_state_end

; configura portas e envia mensagem para estado s6
apply_s6:
    ldi     temp, PORTD_S6
    out     PORTD, temp
    ldi     temp, PORTB_S6
    out     PORTB, temp
    ldi     ZL, LOW(2*msg_s6)
    ldi     ZH, HIGH(2*msg_s6)
    rcall   puts
    rjmp    apply_state_end

; configura portas e envia mensagem para estado s7
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

; calcula tempo total restante da via a somando estados futuros
calculate_total_time_a:
    push    r22
    push    r23
    clr     r22

    mov     r22, timer_count       ; inicia com tempo do estado atual

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

; soma tempos dos estados s2 e s3
add_from_s1:
    ldi     r23, TIME_S2
    add     r22, r23
    ldi     r23, TIME_S3
    add     r22, r23
    rjmp    calc_total_done

; soma tempo do estado s3
add_from_s2:
    ldi     r23, TIME_S3
    add     r22, r23
    rjmp    calc_total_done

; nao soma nada, apenas tempo atual
add_from_s3:
    rjmp    calc_total_done

; nao soma nada, apenas tempo atual
add_from_s4:
    rjmp    calc_total_done

; soma tempos dos estados s6 e s7
add_from_s5:
    ldi     r23, TIME_S6
    add     r22, r23
    ldi     r23, TIME_S7
    add     r22, r23
    rjmp    calc_total_done

; soma tempo do estado s7
add_from_s6:
    ldi     r23, TIME_S7
    add     r22, r23
    rjmp    calc_total_done

; nao soma nada, apenas tempo atual
add_from_s7:
    rjmp    calc_total_done

calc_total_done:
    mov     total_time_a, r22
    pop     r23
    pop     r22
    ret

; separa tempo total em dezena e unidade para display
calculate_digits:
    push    r22
    rcall   calculate_total_time_a

    mov     r22, total_time_a
    clr     dezena
    ldi     temp, 10
calc_loop:
    cp      r22, temp
    brlo    calc_done              ; menor que 10, terminou
    sub     r22, temp              ; subtrai 10
    inc     dezena                 ; incrementa dezena
    rjmp    calc_loop
calc_done:
    mov     unidade, r22           ; resto eh a unidade
    pop     r22
    ret

; atualiza display 7 segmentos com multiplexacao
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

    ; apaga display se nao estiver nos estados validos
    ldi     temp, 0b00110000
    out     PORTC, temp
    ret

show_display:
    rcall   calculate_digits
    inc     multiplex
    andi    multiplex, 0x01        ; alterna entre 0 e 1
    brne    show_unidade_display

; mostra digito da dezena
show_dezena_display:
    ldi     temp, 0b00010000       ; ativa display dezena
    mov     r22, dezena
    andi    r22, 0x0F
    or      temp, r22              ; combina com valor
    out     PORTC, temp
    ret

; mostra digito da unidade
show_unidade_display:
    ldi     temp, 0b00100000       ; ativa display unidade
    mov     r22, unidade
    andi    r22, 0x0F
    or      temp, r22              ; combina com valor
    out     PORTC, temp
    ret

; interrupcao do timer0 para multiplexacao do display
timer0_compa_isr:
    push    temp
    push    r22
    in      temp, SREG
    push    temp

    rcall   display_cd4511         ; atualiza display

    pop     temp
    out     SREG, temp
    pop     r22
    pop     temp
    reti

; interrupcao do timer1 executada a cada 1 segundo
timer1_compa_isr:
    push    temp
    in      temp, SREG
    push    temp

    dec     timer_count            ; decrementa contador
    brne    timer_exit             ; ainda nao zerou

    ; timer zerou, muda de estado
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

; transicao para estado s1
to_s1:
    ldi     state_reg, STATE_S1
    ldi     timer_count, TIME_S1
    rcall   apply_state
    rjmp    timer_exit

; transicao para estado s2
to_s2:
    ldi     state_reg, STATE_S2
    ldi     timer_count, TIME_S2
    rcall   apply_state
    rjmp    timer_exit

; transicao para estado s3
to_s3:
    ldi     state_reg, STATE_S3
    ldi     timer_count, TIME_S3
    rcall   apply_state
    rjmp    timer_exit

; transicao para estado s4
to_s4:
    ldi     state_reg, STATE_S4
    ldi     timer_count, TIME_S4
    rcall   apply_state
    rjmp    timer_exit

; transicao para estado s5
to_s5:
    ldi     state_reg, STATE_S5
    ldi     timer_count, TIME_S5
    rcall   apply_state
    rjmp    timer_exit

; transicao para estado s6
to_s6:
    ldi     state_reg, STATE_S6
    ldi     timer_count, TIME_S6
    rcall   apply_state
    rjmp    timer_exit

; transicao para estado s7
to_s7:
    ldi     state_reg, STATE_S7
    ldi     timer_count, TIME_S7
    rcall   apply_state
    rjmp    timer_exit

; mensagens armazenadas na memoria de programa
init_msg:   .db "SemaforoAVR", 0x0A, 0x0D, 0x00
msg_s1:     .db "Estado S1 - 20s", 0x0A, 0x0D, 0x00
msg_s2:     .db "Estado S2 - 05s", 0x0A, 0x0D, 0x00
msg_s3:     .db "Estado S3 - 60s", 0x0A, 0x0D, 0x00
msg_s4:     .db "Estado S4 - 05s", 0x0A, 0x0D, 0x00
msg_s5:     .db "Estado S5 - 25s", 0x0A, 0x0D, 0x00
msg_s6:     .db "Estado S6 - 05s", 0x0A, 0x0D, 0x00
msg_s7:     .db "Estado S7 - 20s", 0x0A, 0x0D, 0x00
