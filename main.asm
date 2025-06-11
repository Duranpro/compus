#include <p18f4321.inc>

    CONFIG OSC = HSPLL
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
TICS_COUNTER EQU 0x24
COMPROBA EQU 0x35
AUX0 EQU 0x56
AUX1 EQU 0x57
 
ORG 0x0000
GOTO MAIN
ORG 0x0008
GOTO HIGH_RSI
ORG 0x0018
RETFIE FAST
; --------------------------------------------
; FUNCION HIGH_RSI
; --------------------------------------------
HIGH_RSI
    BCF INTCON, GIE, ACCESS    ;desabilitar
    BCF INTCON, TMR0IE, ACCESS  
    
    BTFSC INTCON, TMR0IF, ACCESS    ;Mirem si la interrupcio del timer0, saltem sino es
    CALL TIMER0_RSI
    
    BSF INTCON, GIE, ACCESS     ; Habilitar interrupciones periféricas
    BSF INTCON, TMR0IE, ACCESS   ; Habilitar interrupción del Timer0
    RETFIE FAST
    
    
; --------------------------------------------
; FUNCION QUE GESTIONA INTERUPCIONES DEL TIMER0
; --------------------------------------------  
TIMER0_RSI
    BCF INTCON, TMR0IF ;carreguem de nou el numero i posem flag a 0
    MOVLW HIGH(.64736)	    
    MOVWF TMR0H,0
    MOVLW LOW(.64736)	   
    MOVWF TMR0L,0
   
    BTFSC PORTB, 3		; Si echo activo, incrementa
    CALL NOTA_INCREMENT
    
    BTFSC COMPROBA, 0
    CALL MEDIR_DISTANCIA
    
    BCF COMPROBA, 0
    BTFSC PORTB, 3
    BSF COMPROBA, 0		; Si echo activo, comproba activo
    
    BTFSS PORTB, 3		; Si echo inactiu, reiniciar comptador
    CALL NOTA_RESET
    
    BSF INTCON, GIE, ACCESS     ; Habilitar interrupciones periféricas
    BSF INTCON, TMR0IE, ACCESS   ; Habilitar interrupción del Timer0
    RETFIE FAST
; --------------------------------------------
; FUNCIONES QUE GESTIONA LA DISTANCIA DE LAS NOTAS
; --------------------------------------------  
NOTA_INCREMENT
    INCF TICS_COUNTER, F	; Incrementa comptador 
    RETURN
    
NOTA_RESET
    CLRF TICS_COUNTER		;reincia el contador
    RETURN 
; --------------------------------------------
; ENVÍA UN PULSO ULTRASÓNICO DE 10us
; --------------------------------------------
ENVIAR_PULSO_10US
   
    BSF LATB,2,0  ; Activar TRIGGER (RB2)
    NOP
    NOP
    NOP
    NOP
    NOP
    BCF LATB,2,0  ; Desactivar TRIGGER
    CALL ESPERA
    RETURN
; --------------------------------------------
; MIDE EL TIEMPO DEL PULSO ECHO
; --------------------------------------------
MEDIR_DISTANCIA
    BTFSS PORTB,3 ;controlar just quan baixa per saber quan temps ha estat actiu
    CALL ECHO_BAJO
    RETURN
    
ECHO_BAJO
    MOVF TICS_COUNTER, W
    MOVWF DISTANCIA
    RETURN

; --------------------------------------------
; MAPEA DISTANCIA A UNA NOTA MUSICAL
; --------------------------------------------
CALCULAR_NOTA
   
    MOVLW .5
    CPFSGT DISTANCIA
    GOTO SET_DO

    MOVLW .10
    CPFSGT DISTANCIA
    GOTO SET_RE

    MOVLW .15
    CPFSGT DISTANCIA
    GOTO SET_MI

    MOVLW .20
    CPFSGT DISTANCIA
    GOTO SET_FA

    MOVLW .25
    CPFSGT DISTANCIA
    GOTO SET_SOL

    MOVLW .30
    CPFSGT DISTANCIA
    GOTO SET_LA

    GOTO SET_SI

SET_DO
    MOVLW b'00000001'
    MOVWF LATD
    MOVLW .6
    GOTO SET_NOTA
SET_RE
    MOVLW b'00000010'
    MOVWF LATD
    MOVLW .12
    GOTO SET_NOTA
SET_MI
    MOVLW b'00000011'
    MOVWF LATD
    MOVLW .18
    GOTO SET_NOTA
SET_FA
    MOVLW b'00000100'
    MOVWF LATD
    MOVLW .24
    GOTO SET_NOTA
SET_SOL
    MOVLW b'00000101'
    MOVWF LATD
    MOVLW .30
    GOTO SET_NOTA
SET_LA
    MOVLW b'00000110'
    MOVWF LATD
    MOVLW .36
    GOTO SET_NOTA
SET_SI
    MOVLW b'00000111'
    MOVWF LATD
    MOVLW .42

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
; RETARDOS
; --------------------------------------------
;espera para el triger
ESPERA
    MOVLW   0x0B
    MOVWF   AUX0
LOOP1
    MOVLW   0xFC
    MOVWF   AUX1
LOOP2
    NOP
    NOP
    DECFSZ  AUX1, F
    GOTO    LOOP2
    DECFSZ  AUX0, F
    GOTO    LOOP1
    RETURN
    
;espera para el altavoz  
RETARDO
    MOVWF TEMP_DELAY  ; Usar el valor de TEMP como retardo
LOOP_RETARDO
    DECFSZ TEMP_DELAY,1
    GOTO LOOP_RETARDO
    RETURN
    
; --------------------------------------------
; CONFIGURAR PUERTOS
; --------------------------------------------
INIT_PORTS
    SETF    ADCON1 ;pins digitals
    BSF     INTCON2, RBPU ;desactivar pullups
    ; Configurar RB3 (ECHO) como entrada, RB2 (TRIGGER) como salida
    BSF TRISB,3,0
    BCF TRISB,2,0
    ;bits debugging
    CLRF TRISD,0
    CLRF LATD,0
    CLRF TRISA,0
    CLRF LATA,0
    ; Configurar RC5 como salida (Altavoz)
    BCF TRISC,5,0
    BCF PORTC,5,0
    RETURN
    
    CONFIG_TMR0
    ;configurar TMR0
    BCF RCON,IPEN,ACCESS ;Desactivem prioritats
    MOVLW b'10001000' ;Configurem el timer0 sin prescaler
    MOVWF T0CON,ACCESS
    BCF INTCON, TMR0IF, ACCESS	;Netejem flag
    MOVLW HIGH(.64736)	    ;carguem per 1000 instruccions timer 0,1ms
    MOVWF TMR0H,0
    MOVLW LOW(.64736)	   
    MOVWF TMR0L,0
    BSF INTCON, GIE, ACCESS      ; Habilitar interrupciones globales
    BSF INTCON, PEIE, ACCESS     ; Habilitar interrupciones periféricas
    BSF INTCON, TMR0IE, ACCESS   ; Habilitar interrupción del Timer0
    RETURN
   

    
; --------------------------------------------
; PROGRAMA PRINCIPAL
; --------------------------------------------
MAIN
    CALL INIT_PORTS
    CALL CONFIG_TMR0
LOOP
    CALL ENVIAR_PULSO_10US
    CALL CALCULAR_NOTA
    CALL GENERAR_SONIDO_RC5  ; Generar sonido en RC5 manualmente

    GOTO LOOP

END