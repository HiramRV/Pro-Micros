#include "p16f887.inc"

; CONFIG1
; __config 0x20F4
 __CONFIG _CONFIG1, _FOSC_INTRC_NOCLKOUT & _WDTE_OFF & _PWRTE_OFF & _MCLRE_ON & _CP_OFF & _CPD_OFF & _BOREN_OFF & _IESO_OFF & _FCMEN_OFF & _LVP_OFF
; CONFIG2
; __config 0x3FFF
 __CONFIG _CONFIG2, _BOR4V_BOR40V & _WRT_OFF
 
;*******************************************************************************
GPR_VAR        UDATA	    ; Variables Usuario      
CONT1		 RES	    1
CONT2		 RES	    1
VTEMP		 RES	    1
STATUST		 RES	    1
VADC2		 RES	    1
VADC1		 RES	    1
DATOS		 RES        1
CONTAR		 RES	    1
DATOINS		 RES	    1
DATOA		 RES        1
DATOB		 RES        1
NUMDATO		 RES        1
CAMBIO		 RES	    1
BAN		 RES	    1
;*******************************************************************************
 
RES_VECT  CODE    0x0000            ; processor reset vector
    GOTO    SETUP                   ; go to beginning of program
    
ISR_VECTOR CODE 0X04
PUSH:
    MOVWF VTEMP
    SWAPF STATUS, W
    MOVWF STATUST
    
ISR:
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
    BTFSS PIR1, RCIF	;Reviso si fue por lectura de datos
    GOTO POP			;Si no, me salgo
    BCF PIR1,RCIF		;Limpio bandera
    MOVF RCREG,W		;Muevo el dato que nos llego a W
    MOVWF DATOS			;Muestro el dato en el pic
    BTFSS CONTAR,0		;Reviso si estoy contado
    GOTO POP
    MOVLW .1
    ADDWF NUMDATO,F
POP:
    BSF INTCON, GIE		;Activo las interrupciones Globales
    SWAPF STATUST,W
    MOVWF STATUS
    SWAPF VTEMP,F
    SWAPF VTEMP,W
    
    RETFIE

MAIN_PROG CODE 
SETUP:
    CALL INITOSCCON
    CALL INITUSART
    CALL INITADC
    BSF STATUS, RP0
    BCF STATUS, RP1	;BANCO 1
    
;    BSF PIE1, ADIE	;Habilito interrupciones del ADC hasta que esté en modo manual
    ;Limpio puertos
    CLRF TRISD
    BCF STATUS, RP0
    BCF STATUS, RP1	;Banco0
    
	;Reinicio todas las variables
    CLRF PORTD
    CLRF DATOS
    CLRF DATOA
    CLRF DATOB
    CLRF DATOINS
;    MOVLW .1
;    MOVWF NUMDATO	;Seteo que tenga un dato en la recepción
    CLRF NUMDATO
    CLRF CONTAR
    CLRF VADC1
    CLRF VADC2
    BSF CAMBIO,0
	
    GOTO MAINLOOP
    
MAINLOOP:
    BTFSC CONTAR,0	;Estoy contando?
    GOTO RECIBIR	;Sí, entonces sigo recibiendo
    MOVF DATOS,W	;No, entonces reviso el primer dato
    SUBLW .64		;Reviso si el dato que recibi es el marcador de inicio
    BTFSS STATUS, Z	;Si no, reviso BAN
    GOTO RBAN
    BSF CONTAR,0	;Si lo es, activamos el modo contar
    GOTO MAINLOOP
RBAN:
    BTFSS BAN,0		;Reviso BAN
    GOTO YA		;Si está en 0 quiere decir que ya tiene datos y está en modo compu
    GOTO MANUAL		;Si está en 1 paso a modo manual

    GOTO MAINLOOP
    
RECIBIR:
DI:    
    MOVF NUMDATO,W
    SUBLW .1
    BTFSS STATUS, Z
    GOTO DA
    MOVF DATOS,W
    MOVWF DATOX			;Primer dato
    GOTO MAINLOOP
DA:
    MOVF NUMDATO,W
    SUBLW .2
    BTFSS STATUS, Z
    GOTO DB
    MOVF DATOS,W
    MOVWF DATOY			;Segundo DATO
    GOTO MAINLOOP
DB:
    MOVF NUMDATO,W
    SUBLW .3
    BTFSS STATUS, Z
    GOTO DEND
    MOVF DATOS,W
    MOVWF DATOZ			;Tercer dato
    GOTO MAINLOOP
DEND:
    BCF CONTAR,0		;Apago el bit para recibir mensajes
    CLRF NUMDATO		;Reinicio contador
    GOTO YA
;    GOTO MAINLOOP        
    
YA:
    BCF PIE1,ADIE	;Deshabilito interrupción del ADC
    BTFSS DATOINS,1
    CALL ARRIBA
    BTFSC DATOINS,1
    CALL ABAJO
    
    MOVF DATOA,W
    MOVWF CCP1RL
    MOVF DATOB,W
    MOVF CCP2RL
    
    GOTO MAINLOOP

MANUAL:
    BSF PIE1, ADIE	;Habilito interrupciones del ADC
    BSF ADCON0,GO
    
    BTFSS BOTON,0
    CALL ARRIBA
    BTFSC BOTON,0
    CALL ABAJO
    
    CALL DELAY
    ;MAPEO
    RRF VADC1,F		
    RRF VADC1,F
    RRF VADC1,F		;Corrimiento de 3 bit a la derecha (5msb)
    RRF VADC2,F
    RRF VADC2,F
    RRF VADC2,F		;Corrimiento de 3 bit a la derecha (5msb)
    MOVLW .32
    ADDWF VADC1,F
    ADDWF VADC2,F	;Sumo 32 para tener valores entre 32 y 64
    
    MOVF VADC1,W
    MOVWF CCP1RL
    MOVF VADC2,W
    MOVF CCP2RL
    
    GOTO MAINLOOP
    
    
    
    


;*******************************************************************************
; SUBRUTINA PARA CONFIGURAR USART
;*******************************************************************************   
INITUSART
    ;1
    BSF STATUS, RP0
    BCF STATUS, RP1	;BANCO 1
    
    BCF TXSTA, SYNC	;Comunicacion Asincrona
    BSF TXSTA, BRGH	;Velocidad alta BR
    CLRF SPBRGH
    MOVLW .25
    MOVWF SPBRG		;BG = 9615
    ;BANCO 3
    BSF STATUS, RP0
    BSF STATUS, RP1	;BANCO 3
    
    BSF BAUDCTL, BRG16	;BG DE 16 BITS
    ;2
    ;BANCO0
    BCF STATUS, RP0
    BCF STATUS, RP1	;Banco0
    
    BSF RCSTA, SPEN	;HABILITAMOS PUERTOS
    ;BANCO 1
    BSF STATUS, RP0
    BCF STATUS, RP1	;BANCO 1
    ;3
    BCF TXSTA, TX9	  ;8 BITS
    ;4	    
    ;BSF TXSTA, TXEN	;HABILITAMOS TRANSMISION?
    ;----Interupcciones DE recepcion
    BSF PIE1, RCIE	;Habilitamos banderas al recibir datos
    BSF INTCON,PEIE	;Interrupciones Perifericas
    BCF INTCON, GIE	;Dejo apagadas las interrupciones globales de momento
    
    BCF STATUS, RP0
    BCF STATUS, RP1	;Banco0
    BSF RCSTA, CREN	;Habilitamos recepcion
    ;6
    
    RETURN
;*******************************************************************************
; SUBRUTINA PARA CONFIGURAR OSCCON
;*******************************************************************************
INITOSCCON
    BSF STATUS, RP0
    BCF STATUS, RP1	;BANCO 1
    
    BSF OSCCON, IRCF2
    BSF OSCCON, IRCF1
    BCF OSCCON, IRCF0   ;4MHz
    
    BCF OSCCON, OSTS 	; INICIAMOS CON EL OSCILADOR INTERNO
    BSF OSCCON, HTS		;ESTABLE
    BSF OSCCON, SCS 	; RELOJ INTERNO PARA SISTEMA
    RETURN 
;*******************************************************************************
; SUBRUTINA PARA CONFIGURAR TIMER0
;******************************************************************************* 
INITTMR0
   BSF STATUS, RP0
   BCF STATUS, RP1	;BANCO 1
    
    
   BCF OPTION_REG, T0CS	;MODO TEMPORIZADOR
   BSF OPTION_REG, T0SE	;Flanco subida
   BCF OPTION_REG, PSA	;PRESCALER ASIGNAMOS A TMR0
   
   BCF OPTION_REG, PS2
   BSF OPTION_REG, PS1
   BSF OPTION_REG, PS0	;PRESCALER 1:4
   
   BCF STATUS, RP0
   BCF STATUS, RP1	;BANCO 0
   
   MOVLW .248
   MOVWF TMR0		;CARGAMOS N 
   BSF STATUS, RP0
   BCF STATUS, RP1	;BANCO 1
   
   BCF INTCON, T0IF	;Reinicio la bandera de T0
   
   BCF STATUS, RP0
   BCF STATUS, RP1	;BANCO 0
  
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
   GOTO CHECKT0IFUD2
   BCF INTCON,T0IF
   MOVLW .111
   MOVWF TMR0

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
   
   END