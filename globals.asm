
; globals

pos_x dw 21
pos_y dw 37

pos dw SCREEN_WIDTH*(BOARD_POS_Y + (37 * SNAKE_WIDTH) % BOARD_HEIGHT) + BOARD_POS_X + (21*SNAKE_WIDTH) % BOARD_WIDTH

deq_begin db 0
deq_end db 1

food_x dw 4
food_y dw 20

food_pos dw SCREEN_WIDTH*(BOARD_POS_Y + (20 * SNAKE_WIDTH) % BOARD_HEIGHT) + BOARD_POS_X + (4*SNAKE_WIDTH) % BOARD_WIDTH

has_eaten db 0

clock db 0

; bootsector magic number
seed equ 0x7DFE