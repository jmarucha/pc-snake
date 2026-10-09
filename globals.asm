
; globals

pos dw SCREEN_WIDTH*(BOARD_POS_Y + (37 * SNAKE_WIDTH) % BOARD_HEIGHT)\
+ BOARD_POS_X + (21*SNAKE_WIDTH) % BOARD_WIDTH

food_pos dw SCREEN_WIDTH*(BOARD_POS_Y + (20 * SNAKE_WIDTH) % BOARD_HEIGHT)\
+ BOARD_POS_X + (4*SNAKE_WIDTH) % BOARD_WIDTH

%ifdef GLOBALS_IN_DEAD_CODE
    clock equ (DEAD_free_zero_0 + 1) ; lower byte of MOV immediate
    score equ (DEAD_free_zero_1 + 1) ; lower byte of MOV immediate

    deq_begin equ DEAD_bios_opcode_1 ; opcode
    deq_end equ DEAD_bios_opcode_2 ; opcode

    last_scancode equ (DEAD_free_zero_2 + 1) ; operand of 8-bit MOV
%else
    clock db 0
    score db 0

    deq_begin db 0
    deq_end db 0

    last_scancode db 0
%endif

; bootsector magic number
seed equ 0x7DFE