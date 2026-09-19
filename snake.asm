cpu 8086

%include "keys.asm"
%include "consts.asm"
%include "colors.asm"


%macro DRAW_RECT_AT 4
    ; x, y, w, h
    
    mov bl, %4
    mov cx, %3
    mov di, ((%2)*SCREEN_WIDTH)+%1
    call draw_rect
%endmacro

org 0x8000
    
    ; init
    cli
    xor ax, ax
    mov ds, ax

    mov ss, ax
    mov sp, 0x7C00

    mov ax, 0xA000
    mov es, ax

    ; clock interrupt
    mov word [0x20], clock_interrupt
    mov word [0x22], cs
    sti

    mov ax, 0x13; VGA 320x200x8
    int 0x10
    
    mov al, 0
    call clear_to_color

    ; draw board
    mov al, 15
    DRAW_RECT_AT \
        BOARD_POS_Y - BOARD_BORDER,\
        BOARD_POS_X - BOARD_BORDER,\
        BOARD_WIDTH + BOARD_BORDER * 2,\
        BOARD_HEIGHT + BOARD_BORDER * 2
    mov al, 0
    DRAW_RECT_AT \
        BOARD_POS_Y,\
        BOARD_POS_X,\
        BOARD_WIDTH,\
        BOARD_HEIGHT
    

    call deq_push
    call deq_push
    call deq_push
    call deq_push

main_loop:

    call kbd_handler

    mov cx, [clock]
    or cx, cx
    jz main_loop
    dec word [clock]


    ; pos = head
    call compute_new_head_position
    call test_head_free
    call draw_at

    call deq_push

    push word [pos_x]
    push word [pos_y]
    call deq_pop

    ; pos = tail
    mov al, COLOR_BLUE
    call draw_at

    mov ax, [food_x]
    mov [pos_x], ax
    mov ax, [food_y]
    mov [pos_y], ax
    ; pos = food
    mov al, COLOR_LIGHT_RED
    call draw_at

    pop word [pos_y]
    pop word [pos_x]
    ; pos = head


    jmp main_loop


draw_at:
    ; using globals pos_x, pos_y
    push ax
    call compute_screen_pos
    mov bl, 2
    mov cx, 2
    pop ax
    jmp draw_rect


clear_to_color:
    ; input:
    ; AL = pixel color
    ; output:
    ; DI = CX = SCREEN_SIZE
    xor di, di
    mov cx, SCREEN_SIZE
    rep stosb
    ret

draw_rect:
    push bx
    ; input:
    ; AL = pixel color
    ; BL = heigh
    ; CX = width
    ; DI = pixel start
    .draw_line:
        push di
        push cx
        rep stosb
        pop cx
        pop di
        add di, 320
        dec bl
        jnz .draw_line
    pop bx
    ret 

times320:
    push bx
    mov bx, ax
    mov cl, 6
    shl ax, cl       ; y * 64
    mov cl, 8
    shl bx, cl       ; y * 256
    add ax, bx      ; y * 320
    pop bx
    ret

kbd_handler:
    mov ah, 0x01;peek
    int 0x16
    jz .skip_key
    mov ah, 0x00;pop key
    int 0x16

    cmp al, 0
    jnz .skip_key
    mov [last_scancode], ah
.skip_key:
    ret

compute_new_head_position:

    ; unpause
    mov al, 0
    mov [paused], al

    mov ah, [last_scancode]
    
    cmp ah, KEY_LEFT
    je .left
    cmp ah, KEY_RIGHT
    je .right
    cmp ah, KEY_UP
    je .up
    cmp ah, KEY_DOWN
    je .down

    ; still paused
    mov al, 1
    mov [paused], al

    ret


    .left:
        dec word [pos_x]
        ret
    .right:
        inc word [pos_x]
        ret
    .up:
        dec word [pos_y]
        ret
    .down:
        inc word [pos_y]
        ret

    last_scancode db 0
    paused db 0

clock_interrupt:
    push ax
    ;; shouldn't be risky to assume ds=0

    ; push ds
    ; mov ax, cs
    ; mov ds, ax

    inc word [clock]

    mov al, 20h
    out 20h, al ; ack

    ; pop ds
    pop ax
    iret


clock dw 0

; globals

pos_x dw 21
pos_y dw 37

deq_begin db 0
deq_end db 1

food_x dw 4
food_y dw 20

has_eaten db 0

DEQUE_ORIG_X equ 0x500 ; 256B size
DEQUE_ORIG_Y equ 0x700 ; 256B size

deq_push:
    mov bl, [deq_end]
    xor bh, bh
    sal bx,1
    
    mov ax, [pos_y]
    mov [bx+DEQUE_ORIG_Y], ax
    mov ax, [pos_x]
    mov [bx+DEQUE_ORIG_X], ax

    inc byte [deq_end]
    ret

deq_pop:
    mov bl, [deq_begin]
    xor bh, bh
    sal bx,1
    
    mov ax, [bx+DEQUE_ORIG_Y]
    mov [pos_y], ax
    mov ax, [bx+DEQUE_ORIG_X]
    mov [pos_x], ax

    inc byte [deq_begin]
    ret

compute_screen_pos:
    mov ax, [pos_y]
    sal ax, 1

    call times320
    mov bx, [pos_x]
    sal bx, 1
    add ax, bx

    add ax, SCREEN_WIDTH * BOARD_POS_Y + BOARD_POS_X
    mov di, ax
   ret


;; Game Logic

test_head_free:
    mov al, [paused]
    test al, al
    jnz .cont
    call compute_screen_pos
    mov al, [es:di]

    cmp al, COLOR_BLACK ; EMPTY SPACE
    jz .cont
    cmp al, COLOR_BLUE ; DEBUG SNAKE
    jz .cont
    cmp al, COLOR_LIGHT_RED ; food
    jz .cont
.cont:
    ret


game_over:
    mov al, 5
    DRAW_RECT_AT 50,50,10,10
    jmp game_over