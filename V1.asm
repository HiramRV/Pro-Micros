; PIC16F887 Configuration Bit Settings

; Assembly source line config statements

#include "p16f887.inc"

; CONFIG1
; __config 0x20F4
 __CONFIG _CONFIG1, _FOSC_INTRC_NOCLKOUT & _WDTE_OFF & _PWRTE_OFF & _MCLRE_ON & _CP_OFF & _CPD_OFF & _BOREN_OFF & _IESO_OFF & _FCMEN_OFF & _LVP_OFF
; CONFIG2
; __config 0x3FFF
 __CONFIG _CONFIG2, _BOR4V_BOR40V & _WRT_OFF 
;*******************************************************************************
; VARIABLES                                                                    ;
;*******************************************************************************

GPR_VAR        UDATA
STATUST	    RES     1
VTEMP       RES     1
DATOS       RES     1
CONTAR	    RES	    1
DATOINS	    RES	    1
DATOA	    RES     1
DATOB	    RES	    1
CONTADOR    RES	    1
BAN	    RES	    1
CONT2	    RES	    1
CONT1	    RES	    1
VADC2	    RES	    1
VADC1	    RES	    1
CAMBIO	    RES	    1
BOTON	    RES	    1
;*******************************************************************************
; RESET VECTOR                                                                 ;
;*******************************************************************************

RES_VECT  CODE    0x0000            ; processor reset vector
    GOTO    SETUP                   ; go to beginning of program

;*******************************************************************************
; INTERRUPCIONES                                                               ;
;******************************************************************************* 
    
ISR_VECTOR CODE 0X04          ; interrupt vector location
 
PUSH:
    MOVWF VTEMP
    SWAPF STATUS,W
    MOVWF STATUST
    BCF INTCON, GIE
    
    BTFSS PIR1, ADIF
    GOTO IRX
    BCF PIR1, ADIF	    ;Apago bandera de adc
    BTFSS CAMBIO,0	    ;Reviso esto para ver que valor de ADC cambiar
    GOTO C2
    GOTO C1
C1:
    MOVF ADRESH,W
    MOVWF VADC1
    GOTO POP
C2:
    MOVF ADRESH,W
    MOVWF VADC2
    GOTO POP
IRX:
    BTFSS PIR1, RCIF
    GOTO POP
    BCF PIR1,RCIF
    MOVF RCREG,W
    MOVWF DATOS
POP:
    BSF INTCON, GIE
    SWAPF STATUST,W
    MOVWF STATUS
    SWAPF VTEMP,F
    SWAPF VTEMP,W
    RETFIE 
;*******************************************************************************
; MAIN PROGRAM                                                                 ;
;*******************************************************************************   
     
MAIN_PROG CODE                      ; let linker place main program  
SETUP:
 
 BCF STATUS, RP1
 BSF STATUS, RP0  ; Banco 1
 
 BSF OSCCON, SCS
 BCF OSCCON, OSTS 
 BSF OSCCON, HTS 
 BSF OSCCON, IRCF0
 BSF OSCCON, IRCF1
 BCF OSCCON, IRCF2 ; OSCILACON 500 KHz
 
 ; PUERTO D COMO SALIDA
 CLRF TRISD
 ;BCF TRISC,6
 ;BSF TRISC,7

 CLRF ANSEL     ; PUERTOS I/O DIGITALES DE PUERTO A Y E
 ;BSF ANSEL,0	; RA0 SE USA COMO PUERTO ANALOGO
; BSF ANSEL,1	; RA1 SE USA COMO PUERTO ANALOGO
 CLRF ANSELH	; PUERTOS I/O DIGITALES DE PUERTO B
 
 ; LIMPIO EL PUERTO D
 CLRF PORTD 

INITUSART:
    
    BCF STATUS, RP1
    BSF STATUS, RP0  ; Banco 1
    
    ; SYNC= 0, BRGH=1
    ;MOVLW B'00000100'
    BCF TXSTA, SYNC
    BCF TXSTA, BRGH
        
    CLRF SPBRG ; LIMPIO SPBRG

    ; VALOR CALCULADO PARA SPBRG, FOSC= 4MHz, BAUDRATE=9600
    MOVLW .25
    MOVWF SPBRG

    BSF STATUS, RP1
    BSF STATUS, RP0  ; Banco 3 
  
    BCF BAUDCTL, BRG16  
    
    BCF STATUS, RP1
    BCF STATUS, RP0  ; Banco 0
    
    BSF RCSTA, SPEN
    
    BCF STATUS, RP1
    BSF STATUS, RP0  ; Banco 1
    
    BCF TXSTA, TX9
    
    BSF PIE1,RCIE
    BSF INTCON,PEIE
    BCF INTCON, GIE
    BCF STATUS, RP1
    BCF STATUS, RP0  ; Banco 0
    
    BSF RCSTA, CREN ; SE HABILITA RX 

; SUBRUTINA PARA INICIALIZAR TIMER0, RETRASO DE 0.5 ms
INICIOTIMER0:
    
    BSF STATUS, RP0
    BCF STATUS, RP1 ; BANCO 1
    
    BCF OPTION_REG, T0CS ; MODO DE TEMPORIZADOR, INTERNAL INSTRUCTION CYCLE CLOCK
    BSF OPTION_REG, T0SE ; AUMENTA EN FLANCO DE SUBIDA
    BCF OPTION_REG, PSA  ; SE ASIGNA EL PRESCALER AL TIMER0
    
    BCF OPTION_REG, PS2
    BCF OPTION_REG, PS1
    BSF OPTION_REG, PS0 ; 1:4
    
    BCF STATUS, RP0
    BCF STATUS, RP1  ; BANCO 0
    
    MOVLW .248	; N CALCULADO
    MOVWF TMR0	; SE CARGA N EN EL TIMER0
    
    BSF STATUS, RP0
    BCF STATUS, RP1 ; BANCO 1
    
    BCF INTCON, T0IF ;SE COLOCA EN 0 LA BANDERA T0IF
      
    BCF STATUS, RP0
    BCF STATUS, RP1  ; BANCO 0
 
    CLRF PORTD
    
    BSF STATUS, RP0
    BCF STATUS, RP1	;Banco1
    ;#####################################################
    ;BSF TRISB, RB0
    ;BSF TRISB, RB1	;Entradas RB 
    BCF TRISA, RA7	;RAY como salida
    BSF PIE1, ADIE	;Habilito interrupciones del ADC
    ;BSF STATUS, RP0
    ;BSF STATUS, RP1	;Banco3
    ;CLRF ANSELH ;Puetos i/o Digitales
    ;BSF STATUS, RP0
    ;BCF STATUS, RP1	;Banco1
    ;BSF IOCB, IOCB0	;Habilito Int cambio de estado RB0
    ;BSF IOCB, IOCB1	;Habilito Int cambio de estado RB1
    ;BCF INTCON, RBIF	;Apagamos bandera Int en RB
    ;BSF INTCON, RBIE	;Habilito Int, de cambio de estado Puerto B
    ;#####################################################
    BCF STATUS, RP0
    BCF STATUS, RP1  ; BANCO 0
 
    CLRF PORTA
    CLRF PORTB
    BSF PORTB,0
    
    CALL INITPWM1
    CALL INITPWM2
    CALL INITADC
    CLRF VADC1
    CLRF VADC2
    BSF CAMBIO,0
    
    BSF BAN,0	    ;Manual  por default
;*******************************************************************************************;
; MAINLOOP: SE CONVIERTE LA ENTRADA DE PORTA0 A UN VALOR BINARIO DE 1O BITS,                ;
; Y SE GUARDA EN LA VARIABLE SERVO1, LO MISMO CON EL VALOR DE PORTA1 Y SE GUARDA EN SERVO2. ;
; LUEGO LAS VARIABLES DE CARGAN A CCPR1L Y CCPR2L PARA MOVER LOS SERVOS                     ;
;*******************************************************************************************;    
 
MAINLOOP:
    BSF INTCON,GIE
    ;BTFSC PORTB,0
    ;GOTO CAMBIO1
    BTFSC CONTAR,0	;Estoy contando?
    GOTO RECIBIR	;Sí, entonces sigo recibiendo
    MOVLW .64		;Reviso si el dato que recibi es el marcador de inicio
    SUBWF DATOS,W	;No, entonces reviso el primer dato
    BTFSC STATUS, Z	;Si no, reviso BAN
    GOTO B_CONTAR
    GOTO B_BAN
  
B_CONTAR:    
    BSF CONTAR,0	;Si lo es, activamos el modo contar
    GOTO MAINLOOP   
B_BAN:
    BTFSC BAN,0
    GOTO D_ADC	    ;1-->ADC
    GOTO D_PC	    ;0-->PC
    
D_ADC:
    BSF PORTA, RA7	;LEd de modo
VA1:
    BSF ADCON0,1	;Comenzamos conversion
    CALL DELAY
    MOVF VADC1, W
    MOVWF CCPR1L 
    MOVWF PORTD
VA2:
    BSF INTCON, GIE	;Habilitamos interrupciones globales
    BTFSS BOTON,0
    CALL ARRIBA
    BTFSC BOTON,0
    CALL ABAJO
    
    BSF ADCON0, CHS3	;Canal analogo 12.
    BSF ADCON0, CHS2
    CALL DELAY
    BSF CAMBIO,0
    
    BSF ADCON0,1	;Comenzamos conversion
    CALL DELAY
    MOVF VADC2, W
    MOVWF CCPR2L
    
    BSF INTCON, GIE	;Habilitamos interrupciones globales
    BCF ADCON0, CHS3	;Canal analogo 4. 
    BCF ADCON0, CHS2	
    CALL DELAY
    BCF CAMBIO,0
    GOTO MAINLOOP
    
D_PC:
    BCF PORTA,RA7
    MOVLW B'00011111'
    ANDWF DATOA,F
    RRF DATOA,W
    MOVWF CCPR2L
    CALL DELAY
    
    MOVLW B'00011111'
    ANDWF DATOB,F
    RRF DATOB,W
    MOVWF CCPR1L
    GOTO MAINLOOP
    
RECIBIR:
    CLRF DATOS
    BCF STATUS, RP1
    BSF STATUS, RP0  ; Banco 1 
    BCF PIE1,RCIE
    BCF STATUS, RP0
    BCF STATUS, RP1  ; BANCO 0
DI:    
    BTFSS PIR1, RCIF
    GOTO $-1
    BCF PIR1,RCIF
    MOVF RCREG,W
    MOVWF DATOINS		;Primer dato
DALFA:
    BTFSS PIR1, RCIF
    GOTO $-1
    BCF PIR1,RCIF
    MOVF RCREG,W
    MOVWF DATOA			;Segundo DATO
DBETA:
    BTFSS PIR1, RCIF
    GOTO $-1
    BCF PIR1,RCIF
    MOVF RCREG,W
    MOVWF DATOB			;Tercer dato
DEND:
    BCF CONTAR,0		;Apago el bit para recibir mensajes
    CLRF DATOS
    BCF STATUS, RP1
    BSF STATUS, RP0  ; Banco 1 
    BSF PIE1,RCIE
    BCF STATUS, RP0
    BCF STATUS, RP1  ; BANCO 0
    GOTO MAINLOOP   
    
;*******************************************************************************    
CAMBIO1:
    ;BTFSS BAN,0
    ;GOTO RB0_C
    ;BCF BAN,0
    ;RETURN
RB0_C
    ;BSF BAN,0
    MOVLW .255
    MOVWF PORTD
    CALL DELAY
    GOTO MAINLOOP
 
;*******************************************************************************
; SUBRUTINA PARA INICIAR PWM
;******************************************************************************* 
INITPWM1
    ;Disable de PWM, setear TRIS
    BSF STATUS, RP0
    BCF STATUS, RP1	    ; BANCO 1
    BSF TRISC, TRISC2	    ; CCP1 ENTRADA
    ;Set PWM period
    MOVLW .155
    MOVWF PR2
    ;Configurar CCP
    BCF STATUS,RP0	    ; BANCO 0
    MOVLW B'00001100'	    ; MODO PWM
    MOVWF CCP1CON
    ;Set duty cycle
    MOVLW B'00111110'
    MOVWF CCPR1L
    ;Configurar e iniciar TMR2
    BCF PIR1,TMR2IF
    BSF T2CON,T2CKPS1
    BSF T2CON,T2CKPS0
    BSF T2CON,TMR2ON
    ;Habilitar salida del PWM
    BTFSS PIR1,TMR2IF
    GOTO $-1		    ; POSICIÓN PC - 1
    BCF PIR1,TMR2IF
    BSF STATUS,RP0	    ; BANCO 1
    BCF TRISC,TRISC2	    ; CCP1 SALIDA
    
    BCF STATUS,RP0
    RETURN
    
INITPWM2
    ;Disable de PWM, setear TRIS
    BSF STATUS, RP0
    BCF STATUS, RP1	    ; BANCO 1
    BSF TRISC, TRISC1	    ; CCP2  ENTRADA
    ;Configurar CCP
    BCF STATUS,RP0	    ; BANCO 0
    MOVLW B'00001100'	    ; MODO PWM
    MOVWF CCP2CON
    ;Set duty cycle
    MOVLW B'00111110'
    MOVWF CCPR2L
    ;Habilitar salida del PWM
    BTFSS PIR1,TMR2IF
    GOTO $-1		    ; POSICIÓN PC - 1
    BCF PIR1,TMR2IF
    BSF STATUS,RP0	    ; BANCO 1
    BCF TRISC,TRISC1	    ; CCP2 SALIDA
    
    BCF STATUS,RP0
    RETURN
;*******************************************************************************
; SUBRUTINA PARA CONFIGURAR ADC
;*******************************************************************************   
INITADC
   ;1
   BSF STATUS, RP0
   BCF STATUS, RP1	;Banco1
   
   BSF TRISA, RA0	;Entrada, Ansel 0
   BSF TRISB, RB0	;Entrada, Ansel 12
   
   BSF STATUS, RP0
   BSF STATUS, RP1	;Banco3
   
   CLRF ANSEL
   CLRF ANSELH
   BSF ANSEL, 0	;Bit 0, RA0, Analogica
   BSF ANSELH, ANS12	;Bit 12, Rb0, Analogica
   ;2
   BCF STATUS, RP0
   BCF STATUS, RP1	;Banco0
   
   BCF ADCON0, CHS3
   BCF ADCON0, CHS2
   BCF ADCON0, CHS1
   BCF ADCON0, CHS0	;Canal analogo 0, 0000, RA0

    ;3,6
   BSF STATUS, RP0
   BCF STATUS, RP1	;Banco1
   ;BCF ADCON1, VCFG1	;Voltaje de referencia fijo a VSS
   ;BCF ADCON1, VCFG0	;Voltaje de referencia fijo a VDD 
   ;BCF ADCON1, ADFM	;Justifico a la izquierda\
   MOVLW B'00000000'
   MOVWF ADCON1
   ;4
   BCF STATUS, RP0
   BCF STATUS, RP1	;Banco0
   
   BCF ADCON0, ADCS0
   BCF ADCON0, ADCS1	;Uso FOSC/2. Puede operar con FOSC 500Khz
   ;5
   BSF INTCON, PEIE	;Activo interrupciones perifericas
   BCF STATUS, RP0
   BCF STATUS, RP1	;Banco0   
   BCF PIR1, ADIF	;Apago bandera
   ;7
   BSF ADCON0, ADON	;Encedemos el ADC
   RETURN   

    ;*******************************************************************************
; SUBRUTINA DE DELAY
;******************************************************************************* 
DELAY
    CLRF CONT1
    CLRF CONT2
    MOVLW .1
    MOVWF CONT2
RESTAR1:	;CON :, Es una etiqueta. 
    MOVLW .5
    MOVWF CONT1
RESTAR2:
    DECFSZ CONT1, F
    GOTO RESTAR2
    DECFSZ CONT2, F
    GOTO RESTAR1
    
    RETURN 
;*******************************************************************************
; SUBRUTINA PARA SUBIR MARCADOR
;******************************************************************************* 
ARRIBA
   BSF PORTA,RA3
CHECKT0IFUP1:
   BTFSS INTCON,T0IF
   GOTO CHECKT0IFUP1
   BCF INTCON,T0IF
   MOVLW .248
   MOVWF TMR0
   
   BCF PORTA,RA3
CHECKT0IFUP2:
   BTFSS INTCON,T0IF
   GOTO CHECKT0IFUP2
   BCF INTCON,T0IF
   MOVLW .108
   MOVWF TMR0
   
   RETURN
   
;*******************************************************************************
; SUBRUTINA PARA BAJAR MARCADOR
;******************************************************************************* 
ABAJO
   BSF PORTA,RA3
CHECKT0IFD1:
   BTFSS INTCON,T0IF
   GOTO CHECKT0IFD1
   BCF INTCON,T0IF
   MOVLW .244
   MOVWF TMR0
   
   BCF PORTA,RA3
CHECKT0IFD2:
   BTFSS INTCON,T0IF
   GOTO CHECKT0IFD2
   BCF INTCON,T0IF
   MOVLW .111
   MOVWF TMR0

   RETURN    
    END