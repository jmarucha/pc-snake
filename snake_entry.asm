

org 0x7C00

%include "snake_game.asm"


%assign CODE_SIZE ($-$$)
%warning Code size: CODE_SIZE


times 510 - ($ - $$) db 0; is it Perl?

dw 0xAA55; bootsector magic number