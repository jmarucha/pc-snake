org 0x7C00

%ifndef UNSAFE_SKIP_JMP
jmp 0:start
%endif
start:
%include "snake_game.asm"


%assign s ($-$$)
%warning GAME SIZE: s


times 510 - ($ - $$) db 0; is it Perl?

dw 0xAA55; bootsector magic number