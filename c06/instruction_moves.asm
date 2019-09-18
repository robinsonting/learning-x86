jmp near start

text:
    db 'L', 0x07, 'a', 0x07, 'b', 0x07, 'e', 0x07, 'l', 0x07, ' ', 0x07, 'o', 0x07, 'f', 0x07, 'f', 0x07, 's', 0x07, \
    'e', 0x07, 't', 0x07, ':', 0x07, ' ', 0x07
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

jmp $
times 510 - ($ - $$) db 0
db 0x55, 0xaa