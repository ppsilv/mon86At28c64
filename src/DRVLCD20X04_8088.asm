        CPU 8086
        BITS 16
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
        mov  dx,LCD_DATA
        out dx, al
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

