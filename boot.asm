bits 16
org 0x7C00

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax

    mov ss, ax
    mov sp, 0x7C00
    sti

    mov [boot_drive], dl


    mov bx, 0x8000; dest

    mov ah, 0x02        ; INT 13h, read sectors
    mov al, 20          ; N=20 sectors
    mov ch, 0           ; cylinder 0
    mov cl, 2           ; sector 2
    mov dh, 0           ; head 0
    mov dl, [boot_drive]

    int 0x13
    jc disk_error
    call success; 

    jmp 0x0000:0x8000

success:
    mov si, important_msg
    jmp print_cstr

disk_error:
    mov si, error_msg

print_cstr: ; si - string location
    lodsb
    test al, al
    jz .stop
    mov ah, 0x0E
    int 0x10
    jmp print_cstr
.stop:
    ret

boot_drive db 0

error_msg db "Disk read error!", 0
important_msg db 10, 10, 32, 32, "cipa", 10, "cyce", 10, "wadowice", 10, 13, 0

times 510 - ($ - $$) db 0; is it Perl?

dw 0xAA55; bootsector magic number
