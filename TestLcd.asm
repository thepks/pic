	LIST p=16f628 				;	tell assembler what chip we are using (if you are using the 16f628a, then
	include <p16f628.inc>		;	make sure you change this line and the previous line to read p16f628a

	__CONFIG h'3f58' 

	ORG 0x20
speed_enable  EQU 0x71
speed0 EQU 0x72
speed1 EQU 0x73
Save_W EQU 0x75
Save_Status EQU 0x76
Count EQU 0x77
Enable      EQU     00              ;GP2 - LCD enable
Clock       EQU     01              ;GP4 - shift register clock and LCD
                                    ;      command/data select
Data_In     EQU     02              ;GP5 - shift register data input

Cmnd_Mode   EQU     00              ;LCD register select command mode
Data_Mode   EQU     01              ;LCD register select data mode

Data_Byte   EQU 0x78
Reg_Select  EQU 0x79                ;LCD register select flag

 
	ORG 0x00
        GOTO setup
	
	ORG 0x04
; Interrupt handler
; first store the items that will be impacted by the Int
        MOVWF   Save_W
        SWAPF   STATUS, W
        MOVWF   Save_Status
; now the processing
	MOVF speed_enable, w
	BTFSC STATUS,Z
	GOTO end_fie
	INCF speed1,f
	MOVF speed1,w
	BCF STATUS,Z
	ANDLW 0xF0
	BTFSS STATUS,Z
	GOTO display_speed0 
	GOTO end_fie
display_speed0: NOP	
	MOVLW   Cmnd_Mode
        MOVWF   Reg_Select
        MOVLW   0x80            ;write at start of line 1 (address 0x00)
        CALL    Send_Byte
        CALL    Delay50us
        MOVLW   Data_Mode
        MOVWF   Reg_Select

	MOVF speed0,W
	ANDLW 0xF0
	SWAPF W,W
	CALL Number_lookup
	CALL Send_Byte

	MOVF speed0,W
	ANDLW 0x0F
	CALL Number_lookup
	CALL Send_Byte
	MOVLW 0x0
	MOVWF speed1
	INCF speed0,F


end_fie: NOP
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
	MOVLW 0x00
	MOVWF speed_enable
	BANKSEL CMCON
	MOVLW 0x07					;	This will turn the comparators OFF.
	MOVWF CMCON

	BANKSEL TRISB
	MOVLW 0x00
	MOVWF TRISB	;	We can set each bit individualy. Each port having 8-bits or 8 pins.
	  
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
	MOVLW 0x00
	MOVWF speed1
	MOVWF speed0

	;clear output
	MOVWF PORTB

	;delay 100
	CALL Delay100ms
	CALL Init_LCD
	CALL Test_Code1
	MOVLW 0x01
	MOVWF speed_enable 


begin: NOP
	GOTO begin
	

; Delay routines
;-----------------------------------

Delay50us   MOVLW   d'12'
            GOTO    Cntdwn

Delay1ms    MOVLW   d'246'
            GOTO    Cntdwn

Delay100ms  MOVLW   d'99'
            MOVWF   Count
loop100ms   CALL    Delay1ms
            DECFSZ  Count,  F
            GOTO    loop100ms
            RETURN

Cntdwn      ADDLW   -1              ;decrement W
            BTFSS   STATUS, Z       ;Zero flag set?
            GOTO    Cntdwn          ;No, keep looping
            RETURN                  ;Yes, timeout done


Init_LCD    MOVLW   Cmnd_Mode       ;all init done in LCD command mode
            MOVWF   Reg_Select
            MOVLW   0x30
            CALL    Send_Byte
            CALL    Delay1ms        ;Delay greater than 4.1ms
            CALL    Delay1ms
            CALL    Delay1ms
            MOVLW   0x0E            ;Set for 16 characters, 2 lines
            CALL    Send_Byte
            CALL    Delay50us
            CALL    Delay50us
            MOVLW   0x06
            CALL    Send_Byte
            CALL    Delay50us
	    CALL    Delay50us
            MOVLW   0x01
            CALL    Send_Byte
            CALL    Delay50us
	    CALL    Delay50us
            RETURN

Send_Byte  	MOVWF   Data_Byte       ;Send what's in W
	        MOVLW   0x08            ;8 bits to send
	        MOVWF   Count
sendloop    BCF     PORTB, Clock     ;Clock may have been left high
            RLF     Data_Byte, F    ;MSB sent first
            BTFSS   STATUS, C       ;Test the carry bit
	        BCF     PORTB, Data_In   ;Set data bit to '0'
	        BTFSC   STATUS, C       ;Test the carry bit
	        BSF     PORTB, Data_In   ;Set data bit to a '1'
	        BSF     PORTB, Clock     ;shift reg clocks on rising edge
            DECFSZ  Count,F
            GOTO    sendloop
            BTFSS   Reg_Select, 0   ;Clock was left in a high state. It will
                                    ;now be used as LCD mode select where
                                    ;0 = command mode, 1 = data mode
            BCF     PORTB, Clock     ;Command Mode so set Clock line low
            BSF     PORTB, Enable    ;Need a short positive pulse for LCD
            NOP                     ;to read data from the shift register
            BCF     PORTB, Enable
            RETURN

Test_Code1  MOVLW   Cmnd_Mode
            MOVWF   Reg_Select
            MOVLW   0x80            ;write at start of line 1 (address 0x00)
            CALL    Send_Byte
            CALL    Delay50us
            MOVLW   Data_Mode
            MOVWF   Reg_Select
            MOVLW   'H'
            CALL    Send_Byte
            MOVLW   'E' 
            CALL    Send_Byte
	    MOVLW   'L'
	    CALL    Send_Byte
	    MOVLW   'L'
	    CALL    Send_Byte
	    MOVLW   'O'
	    CALL    Send_Byte	
            RETURN

Number_lookup	ADDWF PCL,f
		RETLW '0'
		RETLW '1'
		RETLW '2'
		RETLW '3'
		RETLW '4'
		RETLW '5'
		RETLW '6'
		RETLW '7'
		RETLW '8'
		RETLW '9'
		RETLW 'A'
		RETLW 'B'
		RETLW 'C'
		RETLW 'D'
		RETLW 'E'
		RETLW 'F'

   	END	
