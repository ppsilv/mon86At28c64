        CPU 8086
        BITS 16

; Port
COM1:	DW		0x3F8
; Here are the port numbers for various UART registers:
uart_tx_rx 		EQU  0xf8 ; COM1 + 0x0   ; 0 DLAB = 0 for Regs. TX and RX
uart_DLL 		EQU  0xf8 ; COM1 + 0x0   ; 0 DLAB = 1 Divisor lacth low
uart_IER 		EQU  0xf9 ; COM1 + 0x1   ; 1 DLAB = 0 Interrupt Enable Register
uart_DLH 		EQU  0xf9 ; COM1 + 0x1   ; 1 DLAB = 1 Divisor lacth high
uart_ISR 		EQU  0xfa ; COM1 + 0x2   ; 2 IIR Interrupt Ident. Register READ ONLY
uart_FCR 		EQU  0xfa ; COM1 + 0x2   ; 2 Fifo Control Resgister WRITE ONLY
uart_LCR 		EQU  0xfb ; COM1 + 0x3   ; 3 Line Control Register
uart_MCR 		EQU  0xfc ; COM1 + 0x4   ; 4 Modem Control Register
uart_LSR 		EQU  0xfd ; COM1 + 0x5   ; 5 Line Status Register
uart_MSR 		EQU  0xfe ; COM1 + 0x6   ; 6 Modem Status Register
uart_scratch 	EQU  0xff ; COM1 + 0x7   ; 7 SCR Scratch Register

UART_FREQUENCY		equ 11055000

;Baudrates
UART_BAUD_9600:		DW	UART_FREQUENCY/(  9600 * 16)
UART_BAUD_14400:	DW	UART_FREQUENCY/( 14400 * 16)
UART_BAUD_19200:	DW	UART_FREQUENCY/( 19200 * 16)
UART_BAUD_38400:	DW  UART_FREQUENCY/( 38400 * 16)
UART_BAUD_57600:	DW	UART_FREQUENCY/( 57600 * 16)
UART_BAUD_115200:	DW	UART_FREQUENCY/(115200 * 16)

UART_TX_WAIT		EQU	600		; Count before a TX times out
        ;org	0x100

serial_init:   jmp     serial_init2

msg0_01:   db "Serial driver for 16C550",0
;configure_uart
;Parameters:
;			AH =  flow control bits
;			AL =  DLL divisor latch low
configure_uart:
			PUSH AX
			MOV		AL,0x0	 		;
			OUT  	uart_IER,	AL	; Disable interrupts

			MOV		AL, 0x80			;
			OUT     uart_LCR,	AL 	; Turn DLAB on

			POP	 AX
			MOV		AL, 0x08
			OUT     uart_DLL,   AL	; Set divisor low

			MOV		AL, 0x00		;
			OUT     uart_DLH,	AL	; Set divisor high

			MOV     AL, 0x03	; AH
			OUT     uart_LCR,	AL	; Write out flow control bits 8,1,N

			MOV 	AL,0x81			;
			OUT     uart_ISR,	AL	; Turn on FIFO, with trigger level of 8.
								                ; This turn on the 16bytes buffer!

			mov cx, 0xFF
			call	basicDelay
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
			JZ	OUT_UART_TX				; If set, then TX is empty, goto transmit
			DEC	BX
			JNZ LOOP_UART_TX		; Otherwise loop
			POP	AX							; We've timed out at this point so
			CLC							; Clear the carry flag and preserve A
			RET
OUT_UART_TX:
			POP	AX							; Good to send at this point, so
			OUT	uart_tx_rx,AL			; Write the character to the UART transmit buffer
			mov cx, 0xff
			call	basicDelay
			STC						; Set carry flag
			RET

serial_init2:
    		MOV      AH,0x03            ; 8 bits, 1 stop, no parity
    		MOV      AL,8 ;UART_BAUD_38400	; Baud rate
    		call configure_uart        	; Put these settings into the UART
			ret

serialLoop:
			mov	al,'A'
			OUT	uart_tx_rx, AL
			mov	cx,0xff
			call basicDelay
			jmp serialLoop

			ret


