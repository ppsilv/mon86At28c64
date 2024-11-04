        CPU 8086
        BITS 16

%imacro setloc  1.nolist
%assign pad_bytes (%1-($-$$)-START)
%if pad_bytes < 0
%assign over_bytes -pad_bytes
%error Preceding code extends beyond setloc location by over_bytes bytes
%endif
%if pad_bytes > 0
%warning Inserting pad_bytes bytes
 times  pad_bytes db 0FFh
%endif
%endm
;History
; 2444 - Version 10.0.01 implemented print2
; 2444 - Version 10.0.01 fixed erro in UART_TX, no push de BX
; 2444 - Version 10.0.02 implemented prompt
; 2445 - Version 10.0.03 now run in a 32k bytes of eeprom.
;                        START = 0x8000
;                        init2 = 0xE000
;                        reset = 0xFFF0
; 0C000h

%define	START		08000h		; BIOS starts at offset 08000h
%define DATE		'22/10/24'
%define MODEL_BYTE	0FEh		; IBM PC/XT
%define VERSION		'1.0.02'	; BIOS version

%define context_off  0x0
%define context_seg  0x2
%define context_len  0x4
%define context_val  0x6000

bioscseg	equ	0F000h
dramcseg        equ     06000h
biosdseg	equ	0040h

post_reg	equ	80h
serial_timeout	equ	7Ch	; byte[4] - serial port timeout values
equip_serial	equ	00h	; word[4] - addresses of serial ports
unused_reg	equ	0C0h	; used for hardware detection and I/O delays
equipment_list	equ	10h	; word - equpment list

reg_addr_dump   equ     0x0000
reg_buff_read   equ     0x0002  ; buffer 255 bytes
reg_counter     equ     0x0100  ; char counter in the buffer
reg_next_dumm   equ     0x0101  ; next variable

        org	START

           jmp     init
           ;12345678901234567890
msg0    db "8088 - CPU TXM/8 III",0
msg1    db "Paulo Silva  (c)2024",0
msg2    db "Mon86 V 1.0.00 2443A",0
msg3    db "1MB dram rom at28c64",0
row:    db 0, 40, 20, 84, 80

        setloc	0E000h

welcome		db	"XT 8088 BIOS, Version "
		db	VERSION
		db	". ", 0Dh
		db	"Paulo Silva(pgordao) - Copyright (C) 2024", 0Dh
		db	"CPU 8088-2   board TXM/8 III  ", 0Dh
		db	"Mon86 V ",VERSION ," 2443A 1MB Dram Rom at28c64", 0Dh, 0
        
init:
        cli				; disable interrupts
        cld				; clear direction flag
        mov ax, 0x6000
        mov es, ax
        mov ax, 0x7000                  ; Segmento Stack
        mov ss, ax
        mov ax, 0xF000
        mov ds, ax
        xor sp, sp
        mov  bx,  reg_counter
        mov  byte es:[bx], 0x0 

        call configure_uart

        call scr_clear

        mov  bx, welcome
        call print2

        mov AX, 0xE000
        call writeRegAddrDump
        call dump
        jmp MainLoop

writeRegAddrDump:
        push AX
        mov AX, dramcseg ; Segmento DRAM
        mov ES, AX
        pop AX
        mov word es:[reg_addr_dump], AX
        mov bx, word es:[reg_addr_dump]
        ret

ReadLine:
        mov cl,0x0
        mov  bx,  reg_buff_read
loop:
        call printPrompt
loopP:  ;RX blocante
        call UART_RX_blct       
 ;       jnc  loopP
        call printch

        mov  byte es:[bx], al 
        mov  byte es:[bx+1], 0x0 
        inc  bx

        CMP  AL, 0x0A
        JNZ  loopP
        call printLf
        call printPrompt
        mov  BX, reg_buff_read
        call printFromDram
        ret

MainLoop:
        call ReadLine
        jmp MainLoop        
;=================================
; Dump memory
; Memory address: bx
;        counter: cx
dump:
        PUSH DS
        MOV  AX, 0xF000
        MOV DS, AX
        mov  Cl, 16

dump_01:        
        mov  al, 0x0d
        call UART_TX
        mov  AX, BX
        call print_hex
        mov  al, ':'
        call UART_TX
        MOV  AL, ' '
        CALL printch
        
        ;;Write 16 bytes em hexadecimal
        MOV  CH, 16
dump_02:
        MOV  AL, DS:[BX]
        CALL byte_to_hex_str
        PUSH AX
        CALL printch
        POP  AX
        MOV  AL, AH
        CALL printch
        MOV  AL, ' '
        CALL printch
        INC  BX
        DEC  CH
        JNZ  dump_02
        ;;Wrote 16 bytes

        MOV  AL, ' '
        CALL printch

        SUB  BX, 16

        ;;Write 16 bytes em ASCII
        MOV  CH, 16
dump_03:
        MOV  AL, DS:[BX]
        CMP  AL, 0x20
        JC  printPonto ; Flag carry set to 1 AL < 0x20
        CMP  AL, 0x80
        JnC  printPonto ; Flag carry set to 0 AL > 0x80
        CALL printch
        INC  BX
        DEC  CH
        JNZ  dump_03
        jmp  dump_Fim
printPonto:        
        MOV  AL, '.'
        CALL printch
        INC  BX
        DEC  CH
        JNZ  dump_03
        ;;Wrote 16 bytes

dump_Fim:
        DEC  CL
        JNZ  dump_01
        mov  al, 0x0d
        call UART_TX
        POP DS
        ret

printPrompt:
        mov al, '>'
        call printch
        ret

printLf:
        mov al, 0x0D
        call printch
        ret


lcdMessage:
        call lcdInit

        mov  ah, 0
        mov  al, 0
        call setCursor
        mov  bx,msg0
        call printstr

        mov  ah, 0
        mov  al, 1
        call setCursor
        mov  bx,msg1
        call printstr

        mov  ah, 0
        mov  al, 2
        call setCursor
        mov  bx,msg2
        call printstr

        mov  ah, 0
        mov  al, 3
        call setCursor
        mov  bx,msg3
        call printstr
        ret

writeRam:
        mov byte ES:[BX], AL
        ret
readRam:
        mov AL, byte ES:[BX]
        ret
;byte_to_hex_str
;This function return in AX the ascii code for hexadecimal number from 0 to F
;Parameters:
;               AL = imput
;               AX = output
;Changes CL
byte_to_hex_str:
        PUSH CX
        mov ah, al
        mov cl, 4
        shr al, cl
        and ax, 0x0f0f
        cmp al, 0x09
        jbe .1
        add al, 'A' - '0' - 10
.1:
        cmp ah, 0x09
        jbe .2
        add ah, 'A' - '0' - 10
.2:
        add ax, "00"
.ret:
        POP CX
        ret

;=========================================================================
; print_digit - print hexadecimal digit
; Input:
;	AL - bits 3...0 - digit to print (0...F)
; Output:
;	none
;-------------------------------------------------------------------------
print_digit:
	push	ax
	push	bx
	and	al,0Fh
	add	al,'0'			; convert to ASCII
	cmp	al,'9'			; less or equal 9?
	jna	.1
	add	al,'A'-'9'-1		; a hex digit
.1:
        call    printch
	pop	bx
	pop	ax
	ret

;=========================================================================
; print_hex - print 16-bit number in hexadecimal
; Input:
;	AX - number to print
; Output:
;	none
;-------------------------------------------------------------------------
print_hex:
	xchg	al,ah
	call	print_byte		; print the upper byte
	xchg	al,ah
	call	print_byte		; print the lower byte
	ret
;=========================================================================
; print_byte - print a byte in hexadecimal
; Input:
;	AL - byte to print
; Output:
;	none
;-------------------------------------------------------------------------
print_byte:
	rol	al,1
	rol	al,1
	rol	al,1
	rol	al,1
	call	print_digit
	rol	al,1
	rol	al,1
	rol	al,1
	rol	al,1
	call	print_digit
	ret

%include "DRV16C550_8088.asm"		
%include "DRVLCD20X04_8088.asm"	
;%include "serial1.inc"	
;%include "serial2.inc"	
;%include "errno.inc"	
;%include "messages.inc"	
%include "screen.asm"	

        setloc	0FFF0h			; Power-On Entry Point
reset:
        jmp 0xF000:init

        setloc	0FFF5h			; ROM Date in ASCII
        db	DATE			; BIOS release date MM/DD/YY
        db	20h

        setloc	0FFFEh			; System Model byte
        db	MODEL_BYTE
        db	0ffh
