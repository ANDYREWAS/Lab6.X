; Archivo:	Prelab6.s
; Dispositivo:	PIC16F887
; Autor:	Andres Najera
; Compilador:	pic-as (v2.35), MPLABX V6.00
;                
; Programa:	TMR1 y contadorinterno con incrementos cada 1000ms
   	
; Creado:	28 feb 2022
; Última modificación: 21 feb 2022
    
PROCESSOR 16F887
    
; PIC16F887 Configuration Bit Settings

; Assembly source line config statements

; CONFIG1
  CONFIG  FOSC = INTRC_NOCLKOUT ; Oscillator Selection bits (INTOSCIO oscillator: I/O function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
  CONFIG  WDTE = OFF            ; Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
  CONFIG  PWRTE = ON            ; Power-up Timer Enable bit (PWRT enabled)
  CONFIG  MCLRE = OFF           ; RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
  CONFIG  CP = OFF              ; Code Protection bit (Program memory code protection is disabled)
  CONFIG  CPD = OFF             ; Data Code Protection bit (Data memory code protection is disabled)
  CONFIG  BOREN = OFF           ; Brown Out Reset Selection bits (BOR disabled)
  CONFIG  IESO = OFF            ; Internal External Switchover bit (Internal/External Switchover mode is disabled)
  CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
  CONFIG  LVP = ON              ; Low Voltage Programming Enable bit (RB3/PGM pin has PGM function, low voltage programming enabled)

; CONFIG2
  CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
  CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits (Write protection off)

// config statements should precede project file includes.
#include <xc.inc>
  

RESET_TMR1 MACRO TMR1_H, TMR1_L
    MOVLW   TMR1_H	    ; Literal a guardar en TMR1H
    MOVWF   TMR1H	    ; Guardamos literal en TMR1H
    MOVLW   TMR1_L	    ; Literal a guardar en TMR1L
    MOVWF   TMR1L	    ; Guardamos literal en TMR1L
    BCF	    TMR1IF	    ; Limpiamos bandera de int. TMR1
    ENDM    
    
PSECT udata_shr		    ; Memoria compartida
    W_TEMP:		DS 1
    STATUS_TEMP:	DS 1
    
    
PSECT resVect, class=CODE, abs, delta=2
ORG 00h			    ; posición 0000h para el reset
;------------ VECTOR RESET --------------
resetVec:
    PAGESEL MAIN	; Cambio de pagina
    GOTO    MAIN
    
PSECT intVect, class=CODE, abs, delta=2
ORG 04h			    ; posición 0004h para interrupciones
;------- VECTOR INTERRUPCIONES ----------
    PUSH:
    MOVWF   W_TEMP	    ; Guardamos W
    SWAPF   STATUS, W
    MOVWF   STATUS_TEMP	    ; Guardamos STATUS
    
ISR:
    BTFSC   TMR1IF	    ; Interrupcion de TMR1?
    CALL    INT_TMR1
 
    
POP:
    SWAPF   STATUS_TEMP, W  
    MOVWF   STATUS	    ; Recuperamos el valor de reg STATUS
    SWAPF   W_TEMP, F	    
    SWAPF   W_TEMP, W	    ; Recuperamos valor de W
    RETFIE		    ; Regresamos a ciclo principal
    
INT_TMR1:
    RESET_TMR1 0xE0, 0xC0   ; Reiniciamos TMR1 para 1000ms
    INCF    PORTA	    ; Incremento en PORTA
    RETURN

MAIN:
    CALL    CONFIG_IO	    ; Configuración de I/O
    CALL    CONFIG_RELOJ    ; Configuración de Oscilador
    CALL    CONFIG_TMR1	    ; Configuración de TMR1
    CALL    CONFIG_INT	    ; Configuración de interrupciones
    BANKSEL PORTD	    ; Cambio a banco 00
    
LOOP:
    ; Código que se va a estar ejecutando mientras no hayan interrupciones
    GOTO    LOOP	

CONFIG_RELOJ:
    BANKSEL OSCCON	    ; cambiamos a banco 01
    BSF	    OSCCON, 0	    ; SCS -> 1, Usamos reloj interno
    BCF	    OSCCON, 6
    BSF	    OSCCON, 5
    BCF	    OSCCON, 4	    ; IRCF<2:0> -> 010 250KHz
    RETURN
    
CONFIG_TMR1:
    BANKSEL T1CON	    ; Cambiamos a banco 00
    BCF	    TMR1GE	    ; TMR1 siempre cuenta
    BSF	    T1CKPS1	    ; prescaler 1:8
    BSF	    T1CKPS0
    BCF	    T1OSCEN	    ; LP deshabilitado
    BCF	    TMR1CS	    ; Reloj interno
    BSF	    TMR1ON	    ; Prendemos TMR1
    
    RESET_TMR1 0xE0, 0xC0   ; Reiniciamos TMR1 para 1000ms
    RETURN
    

CONFIG_IO:
    BANKSEL ANSEL
    CLRF    ANSEL
    CLRF    ANSELH	    ; I/O digitales
    BANKSEL TRISD
    CLRF    TRISA	    ; PORTA como salida
    BANKSEL PORTD
    CLRF    PORTA	    ; Apagamos PORTA
    RETURN
    
CONFIG_INT:
    BANKSEL PIE1	    ; Cambiamos a banco 01
    BSF	    TMR1IE	    ; Habilitamos interrupciones de TMR1
    
    BANKSEL INTCON	    ; Cambiamos a banco 00
    BSF	    PEIE	    ; Habilitamos interrupciones de perifericos
    BSF	    GIE		    ; Habilitamos interrupciones
    BCF	    TMR1IF	    ; Limpiamos bandera de TMR1
    RETURN    