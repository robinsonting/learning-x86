; 打印1 + 2 + 3 + ... + 1000 =
; 感受vstart的作用，所有的汇编地址都会从vstart为起点，也就是text实际值是0x7c00 + 0x0003
; 但编译后的这些语句都是连续的，只是因为计算机启动过程的规定，会把第0扇区的代码（经过验证的）
; 加载到0x7c00位置
section mbr vstart=0x7c00
            jmp start

    text:
            db '1 + 2 + 3 + ... + 1000 = '

    start:
            mov ax, 0xb800
            mov es, ax

            mov bx, text
            mov si, 0
            mov cx, start - text
            call get_cursor
    print:
            shl di, 1               ; 写入两个字符，所以需要扩大2倍
            mov ah, 0x07
            mov al, [bx + si]
            mov [es:di], ax
            inc si
            shr di, 1               ; 再缩小2倍
            inc di                  ; 自增1，指示光标移动到下一个位置
            call set_cursor
            loop print

            jmp $
    
    get_cursor:
            mov dx, 0x3d4
            mov al, 0xe
            out dx, al
            mov dx, 0x3d5
            in al, dx
            mov ah, al

            mov dx, 0x3d4
            mov al, 0xf
            out dx, al
            mov dx, 0x3d5
            in al, dx

            mov di, ax

            ret

    set_cursor:
            push dx
            push bx

            mov bx, di
            mov dx, 0x3d4
            mov al, 0xe
            out dx, al
            mov dx, 0x3d5
            mov al, bh
            out dx, al

            mov dx, 0x3d4
            mov al, 0xf
            out dx, al
            mov dx, 0x3d5
            mov al, bl
            out dx, al

            pop bx
            pop dx
            
            ret

            times 510 - ($ - $$) db 0
                db 0x55, 0xaa