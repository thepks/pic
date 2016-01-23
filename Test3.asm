	LIST p=16f628 				;	tell assembler what chip we are using (if you are using the 16f628a, then
	include <p16f628.inc>		;	make sure you change this line and the previous line to read p16f628a

	__CONFIG h'3f58' 

	org 0x20
	counter EQU 0x71
	lastread EQU 0x72
 
	org 0x00
        goto main
	
	org 0x04
	RLF counter,1
	btfss counter,6
	goto skipop
	movlw 0x01
	movwf counter
skipop: nop
	BANKSEL PORTB
	movf lastread,1
	btfsc STATUS,Z
	goto pattern
	movf counter,w
	andwf lastread,w 
	movwf PORTB
	goto doneit
pattern: nop
	movf counter,w
	andlw 0x3f
	movwf PORTB
doneit: nop
	BANKSEL INTCON
	bcf INTCON, INTF
	bcf INTCON, T0IF
	BANKSEL PORTB
	retfie
	
main:
	BANKSEL CMCON
	movlw 0x07					;	This will turn the comparators OFF.
	movwf CMCON

	BANKSEL TRISB
	movlw 0x00
	movwf TRISB	;	We can set each bit individualy. Each port having 8-bits or 8 pins.
	movlw 0x0F
	movwf TRISA
	  
 	BANKSEL TMR0
	movlw 0x00
	movwf TMR0
   
	BANKSEL OPTION_REG
;     BSF OPTION_REG, INTEDG   
	movlw 0x86 ;b'10000110'
	movwf OPTION_REG 
;     BCF OPTION_REG, T0CS
;     BCF OPTION_REG, PSA
	BANKSEL INTCON
;     BCF INTCON, INTF    ; clear interrupt flag
;     BCF INTCON, INTE    ; mask for external interrupts
;     BSF INTCON, T0IE
;     BSF INTCON, PEIE
;     BSF INTCON, GIE     ; enable interrupts
;     BCF INTCON, RBIE
;     BCF INTCON, T0IF
	MOVLW 0xa0
	movwf INTCON

	BANKSEL PORTB
  	MOVLW 0x01
	MOVWF counter

setup:		

begin: nop
	movf PORTA,w
	MOVWF lastread
	goto begin
	
   	end	

