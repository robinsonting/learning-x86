    jmp near start

text:
    db 'L', 0x07, 'a', 0x07, 'b', 0x07, 'e', 0x07, 'l', 0x07, ' ', 0x07, 'o', 0x07, 'f', 0x07, 'f',\
    0x07, 's', 0x07, 'e', 0x07, 't', 0x07, ':', 0x07, ' ', 0x07
number:
    db 0, 0, 0, 0, 0

start:
    mov ax, 0x07c0
    mov ds, ax

    mov ax, 0xb800
    mov es, ax

    cld
    mov di, 0xb40
    mov si, text
    mov cx, (number - text) / 2
    rep movsw

    mov ax, number                  ; 被除数
    mov si, 10                      ; 除数
    mov bx, number                  ; 基址
    mov cx, (start - number)        ; 循环次数

divide:
    xor dx, dx
    div si
    mov [bx], dl
    inc bx
    loop divide

    mov bx, number
    mov si, (start - number) - 1
    mov cx, (start - number)

print:
    mov al, [bx + si]
    dec si
    add al, 0x30
    mov ah, 0x04
    mov [es:di], ax
    add di, 2
    loop print

jmp $
times 510 - ($ - $$) db 0
db 0x55, 0xaa