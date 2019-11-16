section mbr vstart=0x7c00
            mov ax, 0
            mov ss, ax
            mov sp, ax

            cli
            sti
            cli
            sti

            times 510 - ($ - $$) db 0
            db 0x55, 0xaa