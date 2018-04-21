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
DATOX		 RES	    1
DATOY		 RES        1
DATOZ		 RES        1
NUMDATO		 RES        1
CAMBIO		 RES	    1
;*******************************************************************************
 
RES_VECT  CODE    0x0000            ; processor reset vector
    GOTO    SETUP                   ; go to beginning of program
















    
ISR_VECTOR CODE 0X04
PUSH:
    MOVWF VTEMP
    SWAPF STATUS, W
    MOVWF STATUST
    
ISR:
;Revisar datos
 
;Revisar boton
;Revisar Canales Analogicos



; revsiar TMR0
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
    
    BSF PIE1, ADIE	;Habilito interrupciones del ADC
    ;Limpio puertos
    CLRF TRISD
    BCF STATUS, RP0
    BCF STATUS, RP1	;Banco0
    
	;Reinicio todas las variables
    CLRF PORTD
    CLRF DATOS
    CLRF DATOX
    CLRF DATOY
    CLRF DATOZ
    CLRF NUMDATO
    CLRF CONTAR
    CLRF VADC1
    CLRF VADC2
    BSF CAMBIO,0

;Llamar subs dse configuracion
;Limpiar variables y establecer valor inicial de banderas 
	
    GOTO MAINLOOP
    
MAINLOOP:
;Revisar si estoy recibiendo datos

;Revisar BAN

;LOOP MODO MANUAL   
	
;Quekear AD
;Leer analogios
:Servos	

	;LOOP MODO COMPU

	;Escribir en servos datos de la compu
    
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
;#############################################################  
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
 ;#############################################################   
INITTMR0
   BSF STATUS, RP0
   BCF STATUS, RP1	;BANCO 1
    
    
   BCF OPTION_REG, T0CS	;MODO TEMPORIZADOR
   BSF OPTION_REG, T0SE	;Flanco subida
   BCF OPTION_REG, PSA	;PRESCALER ASIGNAMOS A TMR0
   
   BCF OPTION_REG, PS2
   BCF OPTION_REG, PS1
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
;#############################################################     
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
;########################################    
DELAY	;SUB-RUTINA
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

