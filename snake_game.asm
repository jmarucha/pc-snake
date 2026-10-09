cpu 8086

%include "settings.asm"
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
    
    ; init
    cli
    cld
    xor ax, ax
    mov ds, ax

    mov ss, ax
    DEAD_free_zero_0:
    mov sp, 0x7C00

    DEAD_free_zero_1:
    mov ax, 0xA000
    mov es, ax

    ; clock interrupt
    DEAD_free_zero_3:
    mov word [0x20], clock_interrupt
    DEAD_free_zero_4:
    mov word [0x22], cs
    sti

    mov ax, 0x13; VGA 320x200x8
    DEAD_bios_opcode_1:
    int 0x10
    
    mov al, COLOR_BACKGROUND ; this black generates collisions
    call clear_to_color

    ; draw board
    mov al, COLOR_BORDER
    DRAW_RECT_AT \
        BOARD_POS_X - BOARD_BORDER,\
        BOARD_POS_Y - BOARD_BORDER,\
        BOARD_WIDTH + BOARD_BORDER * 2,\
        BOARD_HEIGHT + BOARD_BORDER * 2
    mov al, CELL_EMPTY
    DRAW_RECT_AT \
        BOARD_POS_X,\
        BOARD_POS_Y,\
        BOARD_WIDTH,\
        BOARD_HEIGHT
    
    DEAD_free_zero_2:
    mov  ah, 00h
    DEAD_bios_opcode_2:
    int  1Ah
    mov  [seed], dx

    %ifdef UNSAFE_CLOCK
    mov cl, 4
    %else
    mov cx, 4
    %endif
    .l:
    call deq_push
    loop .l
    ; mov al, CELL_SNAKE
    call draw_at

main_loop:

    mov cl, [clock]
    or cl, cl
    jz main_loop
    dec word [clock]

    call kbd_handler

    ; pos = head

    ; compute new head position or handle pause

    ; stack abuse
    mov ax, .head_collisions
    push ax
        mov ah, [last_scancode]
        cmp ah, KEY_LEFT
        je .left
        cmp ah, KEY_RIGHT
        je .right
        cmp ah, KEY_UP
        je .up
        cmp ah, KEY_DOWN
        je .down
        pop ax ; fix call stack
        jmp main_loop ; paused


    .left:
        sub word [pos], SNAKE_WIDTH
        ret
    .right:
        add word [pos], SNAKE_WIDTH
        ret
    .up:
        sub word [pos], SNAKE_WIDTH*SCREEN_WIDTH
        ret
    .down:
        add word [pos], SNAKE_WIDTH*SCREEN_WIDTH
        ret

    .head_collisions:
    ; pos = new_head
        mov di, [pos]
        mov al, [es:di]

        cmp al, CELL_EMPTY
        jz .draw_new_head
        ; cmp al, COLOR_BLUE
        ; jz .draw_new_head
        ; END DEBUG POOP

        cmp al, CELL_FOOD ; food
        jz .consume_food
        jmp game_over ; collision
    .consume_food:

    ; update score
        inc byte [score]
        mov al, [score]
        aam
        add ax, 0x3030 ; num + 0x30 = chr(num)
        push ax

        mov ah, 02h
        xor bh, bh ; PAGE 0
        mov dx, (SCORE_POSITION_Y/8)*256+(SCORE_POSITION_X/8)
        int 10h

        pop dx

        mov ah, 0Eh
        xchg dh, al
        mov bl, COLOR_WHITE
        %ifndef UNSAFE_BIOS_CALLS
            xor bh, bh
        %endif
        int 10h
        xchg dl, al
        %ifndef UNSAFE_BIOS_CALLS
            mov ah, 0Eh
            xor bh, bh
            mov bl, COLOR_WHITE
        %endif
        int 10h


    ; generate new food
        call random_0_BS_MIN1

        mov bx, SNAKE_WIDTH
        mul bx
        add ax, BOARD_POS_X+BOARD_POS_Y*SCREEN_WIDTH
        ; X-offset from BOARD_POS
        mov [food_pos], ax
        call random_0_BS_MIN1
        mov bx, SCREEN_WIDTH*SNAKE_WIDTH
        mul bx
        add [food_pos], ax
        ; Y-offset from BOARD_POS

    ; draw new head
        mov al, CELL_SNAKE_FULL
        jmp .move_head_end

    .draw_new_head:
        mov al, CELL_SNAKE
        jmp .move_head_end
.move_head_end:
    call draw_at
    call deq_push

    push word [pos]

    ; tail move logic
    call deq_peek
    mov di, [pos]
    mov al, [es:di]

    %ifdef SIMPLIFIED_TAIL_STATE_MACHINE
        cmp al, CELL_SNAKE_FULL
        jz .skip_pop
        inc byte [deq_begin]
        .skip_pop:
        mov al, CELL_EMPTY
        call draw_at
    %else
        cmp al, CELL_SNAKE_FULL
        mov al, CELL_SNAKE
        je  .skip_pop
        inc byte [deq_begin]
        mov al, CELL_EMPTY
        .skip_pop:
        call draw_at
    %endif


    ;call compute_screen_pos
    mov di, [food_pos]
    mov [pos], di
    ; pos = food
    mov al, CELL_FOOD
    mov di, [pos]
    call draw_at

    pop word [pos]
    ; pos = head


    jmp main_loop


draw_at:
    ; using globals pos_x, pos_y
    push ax
    mov di, [pos]
    mov bl, SNAKE_WIDTH

    %ifdef UNSAFE_IDK
        mov cl, SNAKE_WIDTH
    %else
        mov cx, SNAKE_WIDTH
    %endif
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

clock_interrupt:
    push ax
    ;; shouldn't be risky to assume ds=0

    ; push ds
    ; mov ax, cs
    ; mov ds, ax

    inc byte [clock]

    mov al, 20h
    out 20h, al ; ack

    ; pop ds
    pop ax
    iret

DEQUE_ORIG equ 0x500;

deq_push:
    mov bl, [deq_end]
    xor bh, bh
    sal bx,1
    
    mov ax, [pos]
    mov [bx+DEQUE_ORIG], ax

    inc byte [deq_end]
    ret

deq_peek:
    mov bl, [deq_begin]
    xor bh, bh
    sal bx,1
    
    mov ax, [bx+DEQUE_ORIG]
    mov [pos], ax

    ret


game_over:
    mov al, COLOR_RED
    DRAW_RECT_AT \
        BOARD_POS_X,\
        BOARD_POS_Y+(BOARD_HEIGHT-20)/2,\
        BOARD_WIDTH,\
        20
    jmp game_over

random_0_BS_MIN1:
    mov  ax, [seed]
    mov  bx, 25173
    mul  bx
    add  ax, 13849
    mov  [seed], ax

    xor  dx, dx
    mov  bx, BOARD_SIZE/SNAKE_WIDTH
    div  bx
    mov  ax, dx
    ret

%include "globals.asm"
