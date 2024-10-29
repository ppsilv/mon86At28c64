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

bioscseg	equ	0F000h
biosdseg	equ	0040h
LCD_CMD     EQU 0x80
LCD_DATA    EQU 0x81
;// commands
LCD_CLEARDISPLAY   EQU 0x01
LCD_RETURNHOME     EQU 0x02
LCD_ENTRYMODESET   EQU 0x04
LCD_DISPLAYCONTROL EQU 0x08
LCD_CURSORSHIFT    EQU 0x10
LCD_FUNCTIONSET    EQU 0x20
LCD_SETCGRAMADDR   EQU 0x40
LCD_SETDDRAMADDR   EQU 0x80


        org	START

init:   jmp     init2
           ;12345678901234567890
msg0:   db "8088 - CPU TXM/8 III",0
msg1:	db "Paulo Silva  (c)2024",0
msg2:   db "Mon86 V 1.0.00 2410A",0
msg3:   db "1MB dram rom at28c64",0
row:    db 0, 40, 20, 84, 80

init2:
        cli				; disable interrupts
        cld				; clear direction flag
        mov ax, 0x7000
        mov ss, ax
        mov ax, 0xF000
        mov ds, ax
        xor sp, sp
        mov es, sp
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

loop:
        jmp loop
        ret

printAL:
        out LCD_DATA, al
        mov cx, 0x1600
        call basicDelay
        ret

printAX:
        out LCD_DATA, al
        mov cx, 0x1600
        call basicDelay
        mov al,ah
        out LCD_DATA, al
        mov cx, 0x1600
        call basicDelay
        ret

printstr:
        mov al,byte ds:[bx]
        cmp al,0h
        jz  fim
        call printAL
        inc bx
        jmp printstr
fim:    ret

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

setCursor:
        push AX
        xor  ah,ah            ; limpa AH
        mov  bx, row          ; pega o endereço do array
        add  ax,bx            ; soma com o endereco com AL 1000+1 = 1001=40
        mov  bx, ax           ; poe o 1001 no bx
        mov  al, byte ds:[bx] ; bl = 40 lido da memoria 1001 em bx
        mov  bl, al
        pop  AX               ; resgata AH
        mov  al, bl
        add  al, ah
        or   al, LCD_SETDDRAMADDR ;| ( ah + al)
        out LCD_CMD, al
        mov cx, 0x1600
        call basicDelay

        ret
setCursor2:
        mov  al, 29
        or   al, LCD_SETDDRAMADDR ;| ( ah + al)
        out LCD_CMD, al
        mov cx, 0x1600
        call basicDelay
        ret

lcdInit:
        mov cx, 0x4800
        call basicDelay

        mov al, 0x30
        out LCD_CMD, al

        mov cx, 0x0800
        call basicDelay

        mov al, 0x30
        out LCD_CMD, al

        mov cx, 0x0160
        call basicDelay

        mov al, 0x38    ; function set
        out LCD_CMD, al

        mov cx, 0x1600
        call basicDelay

        mov al, 0x08    ; display off
        out LCD_CMD, al

        mov cx, 0x1600
        call basicDelay

        mov al, 0x01    ; clear display
        out LCD_CMD, al

        mov cx, 0x1600
        call basicDelay

        mov al, 0x02    ; return home
        out LCD_CMD, al

        mov cx, 0x1600
        call basicDelay

        mov al, 0x06    ; entry mode set
        out LCD_CMD, al

        mov cx, 0x1600
        call basicDelay

        mov al, 0x0c    ; display on, no cursor
        out LCD_CMD, al

        mov cx, 0x1600
        call basicDelay
        ret

basicDelay:
        dec cx
        jnz basicDelay
        ret


        setloc	0FFF0h			; Power-On Entry Point
reset:
        jmp 0xF000:init

        setloc	0FFF5h			; ROM Date in ASCII
        db	DATE			; BIOS release date MM/DD/YY
        db	20h

        setloc	0FFFEh			; System Model byte
        db	MODEL_BYTE
        db	0ffh


