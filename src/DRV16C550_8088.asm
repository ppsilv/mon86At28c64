        CPU 8086
        BITS 16

; Port
COM1:	DW		0x3F8
; Here are the port numbers for various UART registers:
uart_tx_rx 		EQU  0xf8 ; 0 DLAB = 0 for Regs. TX and RX
uart_DLL 		EQU  0xf8 ; 0 DLAB = 1 Divisor lacth low
uart_IER 		EQU  0xf9 ; 1 DLAB = 0 Interrupt Enable Register
uart_DLH 		EQU  0xf9 ; 1 DLAB = 1 Divisor lacth high
uart_ISR 		EQU  0xfa ; 2 IIR Interrupt Ident. Register READ ONLY
uart_FCR 		EQU  0xfa ; 2 Fifo Control Resgister WRITE ONLY
uart_LCR 		EQU  0xfb ; 3 Line Control Register
uart_MCR 		EQU  0xfc ; 4 Modem Control Register
uart_LSR 		EQU  0xfd ; 5 Line Status Register
uart_MSR 		EQU  0xfe ; 6 Modem Status Register
uart_scratch 	EQU  0xff ; 7 SCR Scratch Register

UART_FREQUENCY		equ 4915000
;Fomula UART_FREQUENCY/(  9600 * 16)
;Baudrates
UART_BAUD_9600		EQU 32
UART_BAUD_19200		EQU 16
UART_BAUD_38400		EQU  8
UART_BAUD_56800		EQU  5
UART_BAUD_115200	EQU  3
UART_BAUD_230400	EQU  1

UART_TX_WAIT		EQU	0x7fff		; Count before a TX times out

msg0_01:   db "Serial driver for 16C550",0
;configure_uart
;Parameters:None
;			
;			
configure_uart:
			mov cx, 0x2fff
			call	basicDelay
			MOV		AL,0x0	 		;
			OUT  	uart_IER,	AL	; Disable interrupts

			mov cx, 0x1f
			call	basicDelay

			MOV		AL, 0x80			;
			OUT     uart_LCR,	AL 	; Turn DLAB on
			mov cx, 0x1f
			call	basicDelay

			MOV		AL, UART_BAUD_38400 ;0x08
			OUT     uart_DLL,   AL	; Set divisor low
			mov cx, 0x1f
			call	basicDelay

			MOV		AL, 0x00		;
			OUT     uart_DLH,	AL	; Set divisor high
			mov cx, 0x1f
			call	basicDelay

			MOV     AL, 0x03	; AH	
			OUT     uart_LCR,	AL	; Write out flow control bits 8,1,N
			mov cx, 0x1f
			call	basicDelay

			MOV 	AL,0x81			;
			OUT     uart_ISR,	AL	; Turn on FIFO, with trigger level of 8.
								                ; This turn on the 16bytes buffer!
			RET
;UART_RX:
;Parameters: 
;			AL = return the available character
;			If al returns with a valid char flag carry is set, otherwise
;			flag carry is clear
UART_RX:	
			IN	AL, uart_LSR	 		; Get the line status register
			AND AL, 0x01		; Check for characters in buffer
			CLC 				; Clear carry
			JZ	END				; Just ret (with carry clear) if no characters
			IN	AL,uart_tx_rx	; Read the character from the UART receive buffer
			STC 				; Set the carry flag
END:			
			RET

UART_TX:
			PUSH AX
			MOV BX, UART_TX_WAIT			; Set CB to the transmit timeout
LOOP_UART_TX:
			IN	AL,	uart_LSR		; Get the line status register
			AND AL, 0x40					; Check for TX empty
			JNZ	OUT_UART_TX				; If set, then TX is empty, goto transmit
			DEC	BX
			JNZ LOOP_UART_TX		; Otherwise loop
			POP	AX							; We've timed out at this point so
			CLC							; Clear the carry flag and preserve A
			RET
OUT_UART_TX:
			POP	AX							; Good to send at this point, so		
			OUT	uart_tx_rx,AL			; Write the character to the UART transmit buffer
			mov cx, 0x1ff
			call	basicDelay
			STC						; Set carry flag
			RET
;print
;parameters:
;          bx = message address
;
print:
        	mov  al,byte ds:[bx]
        	cmp  al,0h
        	jz   fimPrint
        	OUT	uart_tx_rx,AL
			mov	cx, 0x27ff
			call basicDelay
        	inc  bx
        	jmp  print
fimPrint:   ret

		

serialLoop:
			mov	al,'C'
			call UART_TX
;			mov	cx, 0xff
;			call basicDelay
			jmp serialLoop

			ret
	

