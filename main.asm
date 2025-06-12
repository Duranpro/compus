#include <p18f4321.inc>

CONFIG  OSC=HSPLL      ; Oscilador de alta velocidad
CONFIG  PBADEN=DIG  ; PORTB en modo digital
CONFIG  WDT=OFF     ; Desactivar el Watchdog Timer
    
    
SEVENSEGMENTS_OFF EQU b'11111111'  ; Apagado
SEVENSEGMENTS_GUION EQU b'11111101' ; 0: a, b, c, d, e, f
SEVENSEGMENTS_CERO EQU b'10000010' ; 0: a, b, c, d, e, f
SEVENSEGMENTS_UNO EQU b'11111010'  ; 1: b, c
SEVENSEGMENTS_DOS EQU b'10010001'  ; 2: a, b, d, e, g
SEVENSEGMENTS_TRES EQU b'10000101' ; 3: 
SEVENSEGMENTS_CUATRO EQU b'11001100' ; 4: b, c, f, g
SEVENSEGMENTS_CINCO EQU b'10100100'  ; 5: a, c, d, f, g
SEVENSEGMENTS_SEIS EQU b'10100000'   ; 6: a, c, d, e, f, g
SEVENSEGMENTS_SIETE EQU b'10001111'  ; 7: a, b, c
SEVENSEGMENTS_OCHO EQU b'10000000'   ; 8: a, b, c, d, e, f, g
SEVENSEGMENTS_NUEVE EQU b'10001100'  ; 9: a, b, c, d, f, g
 
CANTIDAD_NOTAS EQU   0x0020
PRIMER_DATO EQU      0x0030 ;A PARTIR DE AQUÍ COMENZAMOS A GUARDAR LAS NOTAS (del bit 0 al 2) Y LAS DURACIONES (del bit 3 al 4)
PUNTERO_7SEG EQU     0x0040
TEMP EQU             0x0050
TEMP1 EQU            0x0052
TEMP2 EQU            0x0053
TEMP4 EQU            0x0054
NOTA_ACTUAL EQU      0x0051
AUX0 EQU 0x56
AUX1 EQU 0x57
TIMER0_COUNTER_H EQU 0x0055
TIMER0_COUNTER_L EQU 0x0058
SEGON1 EQU 0x0059
ORG 0x0000
GOTO MAIN
ORG 0x0008
GOTO HIGH_RSI
ORG 0x0018
RETFIE FAST

 
 
; Subrutina para cargar el Timer0 (20 ms)
TIMER0_RSI
    BCF INTCON, TMR0IF ;carreguem de nou el numero i posem flag a 0
    MOVLW HIGH(.64536)	    
    MOVWF TMR0H,0
    MOVLW LOW(.64536)	   
    MOVWF TMR0L,0
    
    BTFSS SEGON1, 0
    CALL INCREMENTAR_1s
    BTFSS SEGON1, 0
    CALL VALIDATE_TIME
    
    ;BTFSC PORTA,1,0 ;Miramos si StartGame está activado
    ;CALL ENVIAR_PULSO_10US 
    
    RETURN
    
REINICIA_COMPTADORS
    CLRF TIMER0_COUNTER_L		    ; és la actual
    CLRF TIMER0_COUNTER_H
    CLRF SEGON1
    BCF LATA,3,0
    RETURN
    
VALIDATE_TIME
    
    MOVF TIMER0_COUNTER_L, W
    SUBLW 0x10
    BTFSS STATUS, Z
    RETURN
    
    MOVF TIMER0_COUNTER_H, W
    SUBLW 0x27
    BTFSS STATUS, Z
    RETURN
    BSF LATA,3,0
    SETF SEGON1                    ; Ja he comptat els 500milis inicials
    
    RETURN

INCREMENTAR_1s
    
    INCF TIMER0_COUNTER_L, F
    BTFSC STATUS, Z
    INCF TIMER0_COUNTER_H, F
    RETURN
; --------------------------------------------
; RETARDOS
; --------------------------------------------
;espera para el triger
ESPERA2
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
;espera temporal para las notas
ESPERA
    BSF T0CON, TMR0ON, 0
    CALL TIMER0_RSI
COMPROBAR
    BTFSS INTCON, TMR0IF, 0
    GOTO COMPROBAR
    BCF T0CON, TMR0ON, 0
    BCF INTCON, TMR0IF, 0
    RETURN
;espera para las notas 1 seg  
ESPERA_3SEG
    MOVLW d'100'
    MOVWF TEMP2
WAIT_3_SEC_LOOP2
    MOVLW d'100'
    MOVWF TEMP1
WAIT_3_SEC_LOOP1
    CALL ESPERA
    DECFSZ TEMP1, F
    GOTO WAIT_3_SEC_LOOP1
    DECFSZ TEMP2, F
    GOTO WAIT_3_SEC_LOOP2
    RETURN


HIGH_RSI
    BCF INTCON, GIE, ACCESS    ;desabilitar
    BCF INTCON, TMR0IE, ACCESS  
    
    BTFSC INTCON, TMR0IF, ACCESS    ;Mirem si la interrupcio del timer0, saltem sino es
    CALL TIMER0_RSI
    
    BSF INTCON, GIE, ACCESS     ; Habilitar interrupciones periféricas
    BSF INTCON, TMR0IE, ACCESS   ; Habilitar interrupción del Timer0
    RETFIE  FAST
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
    CALL ESPERA2
    RETURN
;********************************************************************************
;GUARDAR NOTAS y DURACIONES
    
    
;NOTAS: Falta hacer el bucle que corra START_GAME hasta que se llegue a la cantidad guardada en CANTIDAD_NOTAS
;********************************************************************************
    
GET_SEVEN_SEG ;ESTO NO SE USAAAAAAAAAA
    ADDWF PCL, F          ; Sumar el índice al contador de programa
    ; Salta al valor correspondiente en la tabla siguiente;
SEVENSEG_TABLE
    RETLW b'10000010'      ; 0
    RETLW b'11111010'      ; 1
    RETLW b'10010001'      ; 2
    RETLW b'10000101'      ; 3
    RETLW b'11001100'      ; 4
    RETLW b'10100100'      ; 5
    RETLW b'10100000'      ; 6
    RETLW b'10001111'      ; 7
    RETLW b'10000000'      ; 8
    RETLW b'10001100'      ; 9
    RETURN                 ; Retornar a START_GAME
    
    
INIT_START_GAME
    ;Preparamos el puntero para las notas
    BCF LATA,3,0
    
    MOVLW PUNTERO_7SEG
    MOVWF FSR0L
    
    MOVLW SEVENSEGMENTS_CERO
    MOVWF INDF0
    INCF FSR0L,1,0
    MOVLW SEVENSEGMENTS_UNO
    MOVWF INDF0
    INCF FSR0L,1,0
    MOVLW SEVENSEGMENTS_DOS
    MOVWF INDF0
    INCF FSR0L,1,0
    MOVLW SEVENSEGMENTS_TRES
    MOVWF INDF0
    INCF FSR0L,1,0
    MOVLW SEVENSEGMENTS_CUATRO
    MOVWF INDF0
    INCF FSR0L,1,0
    MOVLW SEVENSEGMENTS_CINCO
    MOVWF INDF0
    INCF FSR0L,1,0
    MOVLW SEVENSEGMENTS_SEIS
    MOVWF INDF0
    INCF FSR0L,1,0
    MOVLW SEVENSEGMENTS_SIETE
    MOVWF INDF0
    INCF FSR0L,1,0
    
    CLRF SEGON1
    
    MOVLW PRIMER_DATO ; Colocar el puntero en la primera nota
    MOVWF FSR0L
    
    
    ; Configurar PORTD como salida para el display de 7 segmentos
    BCF     TRISD,0,0
    BCF     TRISD,1,0
    BCF     TRISD,2,0
    BCF     TRISD,3,0
    BCF     TRISD,4,0
    BCF     TRISD,5,0
    BCF     TRISD,6,0
    BCF     TRISD,7,0
    
    MOVLW 0x0000
    MOVWF FSR1H
    
    RETURN

UPDATE_7SEG ; Pre: INDF0 debe apuntar al numero que se quiere mostrar

    MOVF INDF0, W       ; Cargar el valor de la dirección apuntada por INDF0 al WREG
    ANDLW 0x07          ; Enmascarar para obtener los 3 LSB (00000111)
    ADDLW PUNTERO_7SEG        ; Sumar el valor de los 3 LSB + 0x0040
    MOVWF FSR1L
    
    MOVF INDF1, W
    MOVWF LATD,0
    RETURN
    
UPDATE_LENGTH ; Pre: INDF0 debe apuntar a la duracion que se quiere mostrar
    ; Post: Muestra por los dos leds RA3 y 4 el valor de la duracion
    
    
    MOVF INDF0,W
    ANDLW 0x0018
    MOVWF TEMP
    
    RETURN
    
STOP_PROGRAM
    MOVLW 0x0000  ; Desactivar todas las interrupciones
    MOVWF INTCON       ; Escribir la configuración en el registro
    
    BCF LATA,3,0
    BCF LATA,4,0
    
    MOVLW SEVENSEGMENTS_GUION
    MOVWF LATD
    
    LOOP
	GOTO LOOP
    GOTO STOP_PROGRAM
    
PROCESAR_NOTA_ACTUAL ; Devuelve 1 al WREG si esta era la ultima nota, 0 sino.
    
    ; Falta hacer lo del retorno al WREG
    CALL UPDATE_7SEG
    CALL UPDATE_LENGTH
    INCF FSR0L,1,0 ; Pasar a la siguiente nota y duración
    INCF NOTA_ACTUAL, 1, 0
    
    ;CALL ESPERA_3SEG
    MOVF   CANTIDAD_NOTAS, W
    SUBWF  NOTA_ACTUAL, W    ; WREG = WREG (CANTIDAD NOTAS) - NOTA_ACTUAL
    BTFSS  STATUS, Z
    GOTO NO_ES_ULTIMA

    ; Si son iguales (es la última nota)
    MOVLW 0xFF
    MOVWF TEMP4
    GOTO SEGUIR

    NO_ES_ULTIMA
    MOVLW 0x00
    MOVWF TEMP4

    SEGUIR
    CALL REINICIA_COMPTADORS
    BTFSC TEMP4,0,0
    GOTO STOP_PROGRAM 
    RETURN
          
    
START_GAME ; Pre: En FSR0L está cargado PRIMER_DATO
    
    ;INDF0 Apunta a la nota que hay que sacar por el 7seg
    ;INDF1 Se usa en UPDATE_7SEG y apunta a el valor a sacar por el 7seg
    
    CALL INIT_START_GAME ;Prepara los puertos, las variables, los FSR, las interrupciones etc.
    
    
    ;CALL UPDATE_7SEG    ; Llamar a la rutina para obtener el valor
    CALL UPDATE_LENGTH
    
    ;INCF FSR0L,1,0 ;Pasamos a la siguiente nota y duracion
    
    ;************************
    ; PROCESAMIENTO DE NOTAS
    ;************************
    PROCESAR_NOTAS
    ; Esta funcion dejará cargado en el WREG un 1 si ha acabado y un 0 si no.
    BTFSC SEGON1, 0
    CALL PROCESAR_NOTA_ACTUAL
    CALL ENVIAR_PULSO_10US 
    GOTO PROCESAR_NOTAS
    
    ;************************
      
GOTO START_GAME
    
GUARDAR_DATOS
    
    ;GUARDAR NOTA y DURACION (estan ambas en el puerto C)
    MOVF PORTC, 0,0  ;Leemos los datos del puerto C
    ANDLW 0x1F  ;Como del puerto C solo nos interesa Note3: RC0, Note2: RC1, Note0: RC2, Duration0: RC3, Duration1: RC4, multiplicamos por '00011111' para ignorar el resto de bits
    MOVWF INDF0 ;Pasamos el valor a la memoria
    
    
    INCF FSR0L,1,0
    INCF CANTIDAD_NOTAS,1,0

    
    ESPERAR_NEWNOTE
    BTFSS PORTA,5,0
    RETURN
    BSF LATA,0,0 ; Mandamos el pulso de ACK
    BCF LATA,0,0
    GOTO ESPERAR_NEWNOTE
    
MODO_GUARDAR_DATOS
    
    BTFSC PORTA,5,0 ;Miramos si NewNote está activado
    CALL GUARDAR_DATOS ;Esto se ejecuta SI NN ESTÁ ACTIVADO
    BTFSC PORTA,1,0 ;Miramos si StartGame está activado
    GOTO START_GAME ;Esto se ejecuta SI SG ESTÁ ACTIVADO
    GOTO MODO_GUARDAR_DATOS

CONFIG_TMR0
    ;configurar TMR0
    BCF RCON,IPEN,ACCESS ;Desactivem prioritats
    MOVLW b'10001000' ;Configurem el timer0 sin prescaler
    MOVWF T0CON,ACCESS
    BCF INTCON, TMR0IF, ACCESS	;Netejem flag
    MOVLW HIGH(.64536)	    ;carguem per 1000 instruccions timer 0,1ms
    MOVWF TMR0H,0
    MOVLW LOW(.64536)	   
    MOVWF TMR0L,0
    BSF INTCON, GIE, ACCESS      ; Habilitar interrupciones globales
    BSF INTCON, PEIE, ACCESS     ; Habilitar interrupciones periféricas
    BSF INTCON, TMR0IE, ACCESS   ; Habilitar interrupción del Timer0
    RETURN   
    
INIT_PORTS
    CLRF    PORTA
    CLRF    PORTB
    CLRF    PORTC
    CLRF    PORTD
    
    CLRF    LATA
    CLRF    LATB
    CLRF    LATC
    CLRF    LATD
    
    SETF    TRISA,0		; Ponemos todo como entrada inicialmente, de esta forma, los puertos que no usemos quedarán como entradas.
    SETF    TRISB,0
    SETF    TRISC,0
    SETF    TRISD,0
    
    BCF     TRISA,3,0           ; Configurar RA3 como salida (LED)
    BCF     TRISA,4,0           ; Configurar RA4 como salida (LED)
    
    ;Configuracion de los puertos

    ;Configurar RA3 y RA4 como salidas
    BCF TRISA,3,0
    BCF TRISA,4,0
    BCF LATA,3,0 
    BCF LATA,4,0
    
    ;Poner RC4 y RC3 como entradas (RC4: Duration1, RC3: Duration0)
    BSF TRISC,4,0 ;****************
    BSF TRISC,3,0 ;****************
    
    ;RA0: ACK como salida y RA1: StartGame como entrada
    BCF TRISA,0,0 ;****************
    BSF TRISA,1,0 ;****************
    
    ;RB5: NewNote como entrada
    BSF TRISA,5,0 ;*************
    
    ;NOTE[3..0]: Note3: RC0, Note2: RC1, Note0: RC2 como entradas
    BSF TRISC,0,0 ;*************
    BSF TRISC,1,0 ;*************
    BSF TRISC,2,0 ;*************
    
    CLRF CANTIDAD_NOTAS ;Poner a 0 la cantidad de notas
    CLRF NOTA_ACTUAL
    
    
    ; COMENZAMOS
    
    ;Preparamos el puntero INDF0 para guardar las NOTAS y las DURACIONES
    MOVLW 0x0000
    MOVWF FSR0H
    MOVLW PRIMER_DATO
    MOVWF FSR0L

    BCF TRISB, 2, 0
    BSF TRISB, 3, 0
    
    RETURN
    
    
MAIN
    CALL INIT_PORTS
    CALL CONFIG_TMR0
    ; Configuración de los puertos
    SETF    ADCON1            ; Configurar PORTA como digital
    
    
    GOTO MODO_GUARDAR_DATOS
    
    
    
    END