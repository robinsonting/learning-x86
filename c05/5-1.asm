mov ax, 0xb800
mov es, ax

; print "Label offset: "
mov byte [es:0xaa0], 'L'
mov byte [es:0xaa1], 0x07
mov byte [es:0xaa2], 'a'
mov byte [es:0xaa3], 0x07
mov byte [es:0xaa4], 'b'
mov byte [es:0xaa5], 0x07
mov byte [es:0xaa6], 'e'
mov byte [es:0xaa7], 0x07
mov byte [es:0xaa8], 'l'
mov byte [es:0xaa9], 0x07
mov byte [es:0xaaa], ' '
mov byte [es:0xaab], 0x07
mov byte [es:0xaac], 'o'
mov byte [es:0xaad], 0x07
mov byte [es:0xaae], 'f'
mov byte [es:0xaaf], 0x07
mov byte [es:0xab0], 'f'
mov byte [es:0xab1], 0x07
mov byte [es:0xab2], 's'
mov byte [es:0xab3], 0x07
mov byte [es:0xab4], 'e'
mov byte [es:0xab5], 0x07
mov byte [es:0xab6], 't'
mov byte [es:0xab7], 0x07
mov byte [es:0xab8], ':'
mov byte [es:0xab9], 0x07
mov byte [es:0xaba], ' '
mov byte [es:0xabb], 0x07

; 通过除余的方式把number转化成字符串
mov ax, number              ; 被除数
mov bx, 10                  ; 除数

xor dx, dx                  ; dx清零
div bx
mov [0x7c00 + number + 0x00], dl

xor dx, dx
div bx
mov [0x7c00 + number + 0x01], dl

xor dx, dx
div bx
mov [0x7c00 + number + 0x02], dl

xor dx, dx
div bx
mov [0x7c00 + number + 0x03], dl

xor dx, dx
div bx
mov [0x7c00 + number + 0x04], dl

mov al, [0x7c00 + number + 0x04]
add al, 0x30
mov byte [es:0xabc], al

mov al, [0x7c00 + number + 0x03]
add al, 0x30
mov byte [es:0xabe], al

mov al, [0x7c00 + number + 0x02]
add al, 0x30
mov byte [es:0xac0], al

mov al, [0x7c00 + number + 0x01]
add al, 0x30
mov byte [es:0xac2], al

mov al, [0x7c00 + number + 0x00]
add al, 0x30
mov byte [es:0xac4], al

jmp $

number:
    db 0

times 510 - ($ - $$) db 0
db 0x55, 0xaa