mov ax, 81      ; dividend
mov dx, 0       ; clear dx to store remainder
mov bx, 18      ; devisor
div bx          ; ax / bx, quotient is stored in ax, remainder is stored in dx

mov [0x7c00 + result + 0x00], al
mov [0x7c00 + result + 0x01], dl

mov ax, 0xb800
mov es, ax

mov al, [0x7c00 + result + 0x00]
add al, 0x30
mov [es:0x500], al
mov al, [0x7c00 + result + 0x01]
add al, 0x30
mov [es:0x502], al

jmp $

result:
    db 0, 0

times 510 - ($ - $$) db 0
db 0x55, 0xaa
