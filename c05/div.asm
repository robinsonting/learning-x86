mov ax, 0x1         ; dividend
mov dx, 0x1         ; clear dx to store remainder
mov bx, 10          ; devisor
div bx              ; ax / bx, quotient is stored in ax, remainder is stored in dx

jmp $

times 510 - ($ - $$) db 0
db 0x55, 0xaa
