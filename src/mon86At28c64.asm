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


%define	START		0E000h		; BIOS starts at offset 08000h
%define DATE		'22/10/24'
%define MODEL_BYTE	0FEh		; IBM PC/XT
%define VERSION		'1.0.00'		; BIOS version

bioscseg	equ	0F000h
biosdseg	equ	0040h

post_reg	equ	80h
serial_timeout	equ	7Ch	; byte[4] - serial port timeout values
equip_serial	equ	00h	; word[4] - addresses of serial ports
unused_reg	equ	0C0h	; used for hardware detection and I/O delays
equipment_list	equ	10h	; word - equpment list

        org	START

init:   jmp     init2
           ;12345678901234567890
msg0    db "8088 - CPU TXM/8 III",0
msg1    db "Paulo Silva  (c)2024",0
msg2    db "Mon86 V 1.0.00 2410A",0
msg3    db "1MB dram rom at28c64",0
row:    db 0, 40, 20, 84, 80

msg10   db "8088 - CPU TXM/8 III",13,10,0
msg11   db "Paulo Silva  (c)2024",13,10,0
msg12   db "Mon86 V 1.0.00 2410A",13,10,0
msg13   db "1MB dram rom at28c64",13,10,0

welcome		db	"XT 8088 BIOS, Version "
		db	VERSION
		db	". "
		db	"Copyright (C) 2024 - 2024 Paulo Silva(pgordao)", 0Dh, 0Ah
		db	"8088 - CPU TXM/8 III  "
		db	"Mon86 V 1.0.00 2410A 1MB dram rom at28c64", 0Dh, 0Ah, 0

init2:
        cli				; disable interrupts
        cld				; clear direction flag
        mov ax, 0x7000
        mov ss, ax
        mov ax, 0xF000
        mov ds, ax
        xor sp, sp
        mov es, sp

        call configure_uart
        mov	bx,welcome
        call print



loop:
        jmp loop
        ret

lcdMessage:
        call lcdInit

        mov ah, 0
        mov al, 0
        call setCursor
        mov	bx,msg0
        call printstr

        mov ah, 0
        mov al, 1
        call setCursor
        mov	bx,msg1
        call printstr

        mov ah, 0
        mov al, 2
        call setCursor
        mov	bx,msg2
        call printstr

        mov ah, 0
        mov al, 3
        call setCursor
        mov	bx,msg3
        call printstr
        ret

writeRam:
        push AX
        mov AX, 0h
        mov DS, AX
        pop AX
        mov [0h], AX
        ret
readRam:
        mov AX, 0h
        mov DS, AX
        mov AX,[0h]
        ret
;byte_to_hex_str
;This function return in AX the ascii code for hexadecimal number from 0 to F
;Parameters:
;               AL = imput
;               AX = output
;Changes CL
byte_to_hex_str:
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
	mov	ah,0Eh			; Int 10 function 0Eh - teletype output
	mov	bl,07h			; just in case we're in graphic mode
	int	10h
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

        setloc	0FFF0h			; Power-On Entry Point
reset:
        jmp 0xF000:init

        setloc	0FFF5h			; ROM Date in ASCII
        db	DATE			; BIOS release date MM/DD/YY
        db	20h

        setloc	0FFFEh			; System Model byte
        db	MODEL_BYTE
        db	0ffh
