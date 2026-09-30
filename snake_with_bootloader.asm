bits 16

;; version with bootloader


section mbr
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
    jmp 0x0000:0x8000

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

%assign s ($-$$)
%warning BOOTLOADER SIZE: s

times 510 - ($ - $$) db 0; is it Perl?

dw 0xAA55; bootsector magic 

section stage2 vstart=0x8000

%include "snake_game.asm"

%assign s ($-$$)
%warning GAME SIZE: s

times 20*512 - ($ - $$) db 0