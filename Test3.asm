	LIST p=16f628 				;	tell assembler what chip we are using (if you are using the 16f628a, then
	include <p16f628.inc>		;	make sure you change this line and the previous line to read p16f628a

	__CONFIG h'3f58' 

	ORG 0x20
counter EQU 0x71
lastread EQU 0x72
speed1 EQU 0x73
speed2 EQU 0x74
Save_W EQU 0x75
Save_Status EQU 0x76
 
	ORG 0x00
        GOTO setup
	
	ORG 0x04
; Interrupt handler
; first store the items that will be impacted by the Int
        MOVWF   Save_W
        SWAPF   STATUS, W
        MOVWF   Save_Status
	MOVF speed1,w
; now the processing
	IORLW 0x00
	BTFSC STATUS,Z
	GOTO temp_part
	MOVF speed2,w
	IORLW 0x00
	BTFSC STATUS,Z
	GOTO increment_speed_2
	INCF speed1,1
	GOTO temp_part
increment_speed_2: NOP
	INCF speed2,1
temp_part: NOP
	BANKSEL PORTB
	MOVLW 0x3f
	ANDWF lastread,w 
	MOVWF PORTB
doneit: NOP
	BANKSEL INTCON
	BCF INTCON, INTF
	BCF INTCON, T0IF
	BANKSEL PORTB
; Finally reset the items before returning
	SWAPF   Save_Status, W
	MOVWF   STATUS
	SWAPF   Save_W, F
	SWAPF   Save_W, W
	RETFIE
	
setup:
	BANKSEL CMCON
	MOVLW 0x07					;	This will turn the comparators OFF.
	MOVWF CMCON

	BANKSEL TRISB
	MOVLW 0x00
	MOVWF TRISB	;	We can set each bit individualy. Each port having 8-bits or 8 pins.
	MOVLW 0x0F
	MOVWF TRISA
	  
 	BANKSEL TMR0
	MOVLW 0x00
	MOVWF TMR0
   
	BANKSEL OPTION_REG
;     BSF OPTION_REG, INTEDG   
	MOVLW 0x86 ;b'10000110'
	MOVWF OPTION_REG 
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
	MOVWF INTCON

	BANKSEL PORTB
  	MOVLW 0x01
	MOVWF counter
	MOVLW 0x00
	MOVWF lastread
	MOVWF speed1
	MOVWF speed2


begin: NOP
	MOVF speed1,w
	IORWF speed2, w
	BTFSS STATUS,Z
	CALL reset_speed_timers
	MOVF PORTA,w
	IORLW 0x00
	BTFSS STATUS,Z
	CALL start_timer
	MOVF PORTA,w
	IORWF lastread,1
	GOTO begin
	
reset_speed_timers:
	NOP
	MOVLW 0x00
	ANDWF speed1,1
	ANDWF speed2,1
	RETURN

start_timer:
	NOP
	MOVF speed1,w
	IORLW 0x00
	BTFSS STATUS,Z
	GOTO start_timer_2
	MOVLW 0x01
	MOVWF speed1
	RETURN
start_timer_2:
	NOP
	MOVWF 0x01
	MOVWF speed2
	RETURN


   	END	
