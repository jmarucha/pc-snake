cpu 8086

%include "keys.asm"
%include "consts.asm"
%include "colors.asm"


CELL_EMPTY equ COLOR_BLACK
CELL_SNAKE equ COLOR_LIGHT_GREEN
CELL_SNAKE_FULL equ COLOR_GREEN
CELL_FOOD equ COLOR_LIGHT_RED

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
    
    mov  ah, 00h
    int  1Ah            ; CX:DX = liczba tików
    mov  [seed], dx
    

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
    ; pos = new_head
    call move_head
    call deq_push

    push word [pos_x]
    push word [pos_y]

    call deq_peek

    call compute_screen_pos
    mov al, [es:di]
    cmp al, CELL_SNAKE_FULL
    jz .skip_pop
    inc byte [deq_begin]
    .skip_pop:
    ; pos = tail
    mov al, CELL_EMPTY
    ; mov al, COLOR_BLUE ; debug poop
    call draw_at
    

    mov ax, [food_x]
    mov [pos_x], ax
    mov ax, [food_y]
    mov [pos_y], ax
    ; pos = food
    mov al, CELL_FOOD
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

deq_peek:
    mov bl, [deq_begin]
    xor bh, bh
    sal bx,1
    
    mov ax, [bx+DEQUE_ORIG_Y]
    mov [pos_y], ax
    mov ax, [bx+DEQUE_ORIG_X]
    mov [pos_x], ax

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

move_head:
    mov al, [paused]
    test al, al
    jz .cont 
    ret
    .cont:
    call compute_screen_pos
    mov al, [es:di]

    cmp al, CELL_EMPTY
    jz .draw_new_head
    cmp al, COLOR_BLUE
    jz .draw_new_head
    ; END DEBUG POOP

    cmp al, CELL_FOOD ; food
    jz .consume_food
    jmp game_over
.consume_food:

    call random_0_89
    mov [food_x], ax
    call random_0_89
    mov [food_y], ax

; draw new head
    mov al, CELL_SNAKE_FULL
    call draw_at
    ret

.draw_new_head:
    mov al, CELL_SNAKE
    call draw_at
    ret

game_over:
    mov al, COLOR_RED
    DRAW_RECT_AT \
        BOARD_POS_X,\
        BOARD_POS_Y+(BOARD_HEIGHT-20)/2,\
        BOARD_WIDTH,\
        20
    jmp game_over

random_0_89:
    mov  ax, [seed]
    mov  bx, 25173
    mul  bx
    add  ax, 13849
    mov  [seed], ax

    xor  dx, dx
    mov  bx, 90
    div  bx
    mov  ax, dx
    ret

%include "globals.asm"