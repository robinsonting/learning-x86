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
    mov di, 0xb40
    mov ah, 0x07
    mov cx, start - text
print:
    mov al, [bx + si]
    mov [es:di], ax
    add di, 2
    inc si
    loop print

    jmp $

times 510 - ($ - $$) db 0
    db 0x55, 0xaa