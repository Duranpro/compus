#include <p18f4321.inc>

    CONFIG OSC = INTIO2
    CONFIG WDT = OFF
    CONFIG PBADEN = DIG
    CONFIG MCLRE = ON       
    


; ----------------------------
; DECLARACIÓN DE VARIABLES
; ----------------------------
TEMP         EQU 0x20  ; Variable para almacenar datos temporales
TEMP_DELAY   EQU 0x21  ; Variable para los retardos
NOTA_TEMP    EQU 0x22  ; Variable para almacenar la nota seleccionada
DISTANCIA    EQU 0x23  
TICS_COUNTER_L EQU 0x24

R0 EQU 0x56
R1 EQU 0x57
 
ORG 0x0000
GOTO MAIN
ORG 0x0008
GOTO HIGH_RSI
ORG 0x0018
RETFIE FAST
 
HIGH_RSI
    BCF INTCON, GIE, ACCESS    
    BCF INTCON, TMR0IE, ACCESS  
    
    BTFSS INTCON, TMR0IF, ACCESS    ;Mirem si la interrupcio es del timer0 sino la saltem
    RETFIE FAST
   
    BCF INTCON, TMR0IF
    MOVLW HIGH(.64736)	    
    MOVWF TMR0H,0
    MOVLW LOW(.64736)	   
    MOVWF TMR0L,0
    BSF LATA,4,0
    BTFSC PORTB, 3		; Si echo actiu, incrementa comptador
    CALL INCREMENT_COUNTER
    
    BTFSS PORTB, 3		; Si echo inactiu, reiniciar comptador
    CALL RESET_COUNTER		; POSAR RESET EN EL BTFSC PORTB, ECHO
    BCF INTCON, PEIE, ACCESS     ; Habilitar interrupciones periféricas
    BCF INTCON, TMR0IE, ACCESS   ; Habilitar interrupción del Timer0
    RETFIE FAST
    
; --------------------------------------------
; ENVÍA UN PULSO ULTRASÓNICO DE 10us
; --------------------------------------------
ENVIAR_PULSO_10US
   
    BSF LATB,2,0  ; Activar TRIGGER (RB2)
    NOP
    NOP
    NOP
    BCF LATB,2,0  ; Desactivar TRIGGER
    CALL ESPERA_50MS
    RETURN
; --------------------------------------------
; MIDE EL TIEMPO DEL PULSO ECHO
; --------------------------------------------
MEDIR_DISTANCIA
    GOTO RESET_COUNTER

ESPERAR_ECHO_ACTIVO
    BTFSS PORTB,3
    GOTO ESPERAR_ECHO_ACTIVO   ; Esperar hasta que ECHO = 1

ESPERAR_ECHO_BAJO
    BTFSC PORTB,3
    GOTO ESPERAR_ECHO_BAJO     ; Esperar mientras ECHO = 1

    MOVF TICS_COUNTER_L, W
    MOVWF DISTANCIA
    RETURN

; --------------------------------------------
; MAPEA DISTANCIA A UNA NOTA MUSICAL
; --------------------------------------------
CALCULAR_NOTA
   
    MOVLW .6
    CPFSGT TICS_COUNTER_L
    GOTO SET_DO

    MOVLW .12
    CPFSGT TICS_COUNTER_L
    GOTO SET_RE

    MOVLW .17
    CPFSGT TICS_COUNTER_L
    GOTO SET_MI

    MOVLW .23
    CPFSGT TICS_COUNTER_L
    GOTO SET_FA

    MOVLW .29
    CPFSGT TICS_COUNTER_L
    GOTO SET_SOL

    MOVLW .35
    CPFSGT TICS_COUNTER_L
    GOTO SET_LA

    GOTO SET_SI

SET_DO
    MOVLW b'00000001'
    MOVWF LATD
    MOVLW .0
    GOTO SET_NOTA
SET_RE
    MOVLW b'00000010'
    MOVWF LATD
    MOVLW .2
    GOTO SET_NOTA
SET_MI
    MOVLW b'00000011'
    MOVWF LATD
    MOVLW .4
    GOTO SET_NOTA
SET_FA
    MOVLW b'00000100'
    MOVWF LATD
    MOVLW .6
    GOTO SET_NOTA
SET_SOL
    MOVLW b'00000101'
    MOVWF LATD
    MOVLW .8
    GOTO SET_NOTA
SET_LA
    MOVLW b'00000110'
    MOVWF LATD
    MOVLW .10
    GOTO SET_NOTA
SET_SI
    MOVLW b'00000111'
    MOVWF LATD
    MOVLW .12

SET_NOTA
    MOVWF NOTA_TEMP
    RETURN

; --------------------------------------------
; GENERA ONDA CUADRADA EN RC5 (ALTAVOZ)
; --------------------------------------------
GENERAR_SONIDO_RC5
    MOVF NOTA_TEMP, W   ; Usamos la nota seleccionada
    MOVWF TEMP          ; Pasamos el valor a TEMP
LOOP_SONIDO
    BSF LATC,5,0  ; Activar RC5 (Señal alta)
    CALL RETARDO
    BCF LATC,5,0  ; Apagar RC5 (Señal baja)
    CALL RETARDO
    DECFSZ TEMP,1 ; Reducimos TEMP y repetimos hasta que se acabe
    GOTO LOOP_SONIDO
    RETURN

; --------------------------------------------
; RETARDO CONTROLADO POR TEMP PARA FRECUENCIA
; --------------------------------------------
ESPERA_50MS
    MOVLW   0x0A
    MOVWF   R0

OUTER_LOOP
    MOVLW   0xFA
    MOVWF   R1

INNER_LOOP
    NOP
    NOP
    DECFSZ  R1, F
    GOTO    INNER_LOOP

    DECFSZ  R0, F
    GOTO    OUTER_LOOP

    RETURN
    
    
RETARDO
    MOVWF TEMP_DELAY  ; Usar el valor de TEMP como retardo
LOOP_RETARDO
    DECFSZ TEMP_DELAY,1
    GOTO LOOP_RETARDO
    RETURN
;DISTANCIA NOTES
INCREMENT_COUNTER
    INCF TICS_COUNTER_L, F	; Incrementa comptador low
    BSF LATA,3,0
    RETURN
RESET_COUNTER
    CLRF TICS_COUNTER_L
    
    RETURN
    
; --------------------------------------------
; CONFIGURAR PUERTOS
; --------------------------------------------
INIT_PORTS
    SETF    ADCON1
    ;BSF     INTCON2, RBPU
    ; Configurar RB3 (ECHO) como entrada, RB2 (TRIGGER) como salida
    BSF TRISB,3,0
    BCF TRISB,2,0
    CLRF TRISD,0
    CLRF LATD,0
    CLRF TRISA,0
    CLRF LATA,0
  
    ; Configurar RC5 como salida (Altavoz)
    BCF TRISC,5,0
    BCF PORTC,5,0
    ;configurar TMR0
    BCF RCON,IPEN,ACCESS ;Desactivem les prioritats
    MOVLW b'10001000' ;Configurem el timer0 sin prescaler
    MOVWF T0CON,ACCESS
    BCF INTCON, TMR0IF, ACCESS	;Netejem
    MOVLW HIGH(.64736)	    
    MOVWF TMR0H,0
    MOVLW LOW(.64736)	   
    MOVWF TMR0L,0
    BSF INTCON, GIE, ACCESS      ; Habilitar interrupciones globales
    BSF INTCON, PEIE, ACCESS     ; Habilitar interrupciones periféricas
    BSF INTCON, TMR0IE, ACCESS   ; Habilitar interrupción del Timer0
    RETURN
   

    
CONFIG_OSC  
    MOVLW b'01110000' ;8MHz, oscil·lador primari
    MOVWF OSCCON, ACCESS  
    MOVLW b'01000000' ;PLL (x4)
    MOVWF OSCTUNE, ACCESS ;Oscil·lador intern a 32MHz (8MHz *4)
    RETURN
    
; --------------------------------------------
; PROGRAMA PRINCIPAL
; --------------------------------------------
MAIN
    CALL CONFIG_OSC
    CALL INIT_PORTS
    
LOOP
    CALL ENVIAR_PULSO_10US
    CALL MEDIR_DISTANCIA
    CALL CALCULAR_NOTA
    ;CALL GENERAR_SONIDO_RC5  ; Generar sonido en RC5 manualmente

    GOTO LOOP

END