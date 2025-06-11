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
TEMP EQU   0x0050
CONTADOR_NOTAS EQU  0x0051




ORG     0x0000
GOTO    MAIN

 
 
; Subrutina para cargar el Timer0 (20 ms)
CARREGA_TIMER
    BCF     INTCON,TMR0IF,0   ; Limpiar el bit de interrupción
    MOVLW   0xF3              ; Valor bajo para 20 ms
    MOVWF   TMR0L             ; Escribir el valor en TMR0L
    MOVLW   0xFC              ; Valor bajo para 20 ms
    MOVWF   TMR0H             ; Escribir el valor en TMR0H
    RETURN
    
ESPERA
    ; Configurar y cargar el Timer0 para 20 ms
    BSF T0CON, 7, 0     ; Activar el Timer0
    CALL CARREGA_TIMER       ; Carga los valores iniciales para 20 ms
    COMPROBAR
    BTFSS INTCON, TMR0IF, 0  ; Verificar si se cumplió el periodo
    GOTO COMPROBAR         ; Si no, seguir esperando

    ; Desactivar el Timer0 y limpiar el flag de interrupción
    BCF T0CON, TMR0ON, 0     ; Desactivar el Timer0
    BCF INTCON, TMR0IF, 0    ; Limpiar el flag del Timer0
    ;CLRF FSR0H
    MOVF FSR0
    ADDLW 0x01
    MOVWF FSR0L
    RETURN


HIGH_RSI
    BTFSS   INTCON,TMR0IF,0   ; Verificar si la interrupción es del Timer0
    RETFIE  FAST		
    CALL    CARREGA_TIMER     ; Recargar el valor inicial del Timer0
    ;BTG     LATA,4,0          ; Invertir el estado del LED en RA3
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

    CALL INIT_START_GAME ;Prepara los puertos, las variables, los FSR, las interrupciones etc.

    MOVF CANTIDAD_NOTAS, W
    MOVWF CONTADOR_NOTAS      ; Copiar la cantidad de notas guardadas

    MOVLW PRIMER_DATO         ; Apuntar a la primera nota
    MOVWF FSR0L

MOSTRAR_NOTA
    CALL UPDATE_7SEG          ; Mostrar la nota actual en el display

    ; Esperar 3 segundos (150 veces 20 ms)
    MOVLW 0x96
    MOVWF TEMP
ESPERAR_3S
    CALL ESPERA
    DECFSZ TEMP,1,0
    GOTO ESPERAR_3S

    INCF FSR0L,1,0            ; Pasar a la siguiente nota
    DECFSZ CONTADOR_NOTAS,1,0
    GOTO MOSTRAR_NOTA

    GOTO STOP_PROGRAM
    
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
    BTFSC PORTA,1,0 ;Miramos si StartGame está activado
    GOTO START_GAME ;Esto se ejecuta SI SG ESTÁ ACTIVADO
    GOTO MODO_GUARDAR_DATOS

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
    
    ; DESACTIVAR cualquier interrupción (esto es temporal xq en este codigo todavia no necesitamos)
    MOVLW b'00000000'
    MOVWF INTCON
    
    ; COMENZAMOS
    
    ;Preparamos el puntero INDF0 para guardar las NOTAS y las DURACIONES
    MOVLW 0x0000
    MOVWF FSR0H
    MOVLW 0x0000
    MOVWF FSR0L
    MOVLW PRIMER_DATO
    MOVWF FSR0L
    
    ;Configuro una interrupcion para depuerar
    MOVLW   b'01000111'       ; Configurar Timer0 en modo de 16 bits, prescaler 1:256
    MOVWF   T0CON             ; Escribir la configuración del Timer0
    MOVLW b'00100000'  ; Configuración del INTCON:
                   ; Bit 7 (GIE/GIEH) = 0 -> Interrupciones globales deshabilitadas
                   ; Bit 6 (PEIE/GIEL) = 0 -> Interrupciones de periféricos deshabilitadas
                   ; Bit 5 (R0IE) = 0 -> Interrupción del Timer0 deshabilitada
                   ; Bit 2 (TMR0IF) = 1 -> Flag del Timer0 habilitado (para consulta)
    MOVWF INTCON       ; Escribir la configuración en el registro

	
    GOTO MODO_GUARDAR_DATOS
    
    END
