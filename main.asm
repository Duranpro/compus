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
TEMP1 EQU   0x0050
TEMP2 EQU   0x0051
TEMP EQU   0x0052


ORG 0x0000
GOTO MAIN
ORG 0x0008
GOTO HIGH_RSI
ORG 0x0018
RETFIE FAST
 
 
; Subrutina para cargar el Timer0 (20 ms)
TIMER0_RSI
    BCF INTCON, TMR0IF ;carreguem de nou el numero i posem flag a 0
    MOVLW HIGH(.64736)	    
    MOVWF TMR0H,0
    MOVLW LOW(.64736)	   
    MOVWF TMR0L,0
    RETURN

ESPERA
    BSF T0CON, TMR0ON, 0
    CALL TIMER0_RSI
COMPROBAR
    BTFSS INTCON, TMR0IF, 0
    GOTO COMPROBAR
    BCF T0CON, TMR0ON, 0
    BCF INTCON, TMR0IF, 0
    RETURN



HIGH_RSI
    BCF INTCON, GIE, ACCESS    ;desabilitar
    BCF INTCON, TMR0IE, ACCESS  
    
    BTFSC INTCON, TMR0IF, ACCESS    ;Mirem si la interrupcio del timer0, saltem sino es
    CALL TIMER0_RSI
    
    BSF INTCON, GIE, ACCESS     ; Habilitar interrupciones periféricas
    BSF INTCON, TMR0IE, ACCESS   ; Habilitar interrupción del Timer0
    RETFIE  FAST
 
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

UPDATE_7SEG

    MOVF INDF0, W       ; Cargar el valor de la dirección apuntada por INDF0 al WREG
    ANDLW 0x07          ; Enmascarar para obtener los 3 LSB (00000111)
    ADDLW PUNTERO_7SEG        ; Sumar el valor de los 3 LSB + 0x0040
    MOVWF FSR1L
    
    MOVF INDF1, W
    MOVWF LATD,0
    RETURN
    
UPDATE_LENGTH
    BCF LATA,3,0
    BCF LATA,4,0
    MOVF INDF0,W
    ANDLW 0x0018
    MOVWF TEMP
    BTFSC TEMP,3,0
    BSF LATA,3,0
    BTFSC TEMP,4,0
    BSF LATA,4,0
    RETURN
    
DISPLAY_NOTES_LOOP
    MOVLW PRIMER_DATO
    MOVWF FSR0L

DISPLAY_NEXT_NOTE
    MOVF INDF0, W
    ANDLW 0x07
    ADDLW PUNTERO_7SEG
    MOVWF FSR1L

    MOVF INDF1, W
    MOVWF LATD
    
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

    INCF FSR0L, F

    MOVLW PRIMER_DATO
    ADDWF CANTIDAD_NOTAS, W
    SUBWF FSR0L, W
    BTFSS STATUS, Z
    RETURN

    GOTO STOP_PROGRAM
   
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

START_GAME
    
    
    CALL DISPLAY_NEXT_NOTE   ; Aquí mostramos las notas cada 3 segundos
             
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
    BSF LATA,3,0 ;Esto es para debugar, ni caso
    BCF LATA,3,0
    BTFSC PORTA,5,0 ;Miramos si NewNote está activado
    CALL GUARDAR_DATOS ;Esto se ejecuta SI NN ESTÁ ACTIVADO
    BTFSC PORTA,1,0 
    CALL INIT_START_GAME ;Prepara los puertos, las variables, los FSR, las interrupciones etc.
    BTFSC PORTA,1,0 
    CALL DISPLAY_NOTES_LOOP
    BTFSC PORTA,1,0 ;Miramos si StartGame está activado
    GOTO START_GAME ;Esto se ejecuta SI SG ESTÁ ACTIVADO
    GOTO MODO_GUARDAR_DATOS
    
    
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
    
MAIN
    ; Configuración de los puertos
    SETF    ADCON1            ; Configurar PORTA como digital
    
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
    
    CALL CONFIG_TMR0
    
    ; COMENZAMOS
    
    ;Preparamos el puntero INDF0 para guardar las NOTAS y las DURACIONES
    MOVLW 0x0000
    MOVWF FSR0H
    MOVLW 0x0000
    MOVWF FSR0L
    MOVLW PRIMER_DATO
    MOVWF FSR0L
    
   

	
    GOTO MODO_GUARDAR_DATOS
    
    END