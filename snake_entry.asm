

org 0x7C00

%include "snake_game.asm"


%assign s ($-$$)
%warning GAME SIZE: s


times 510 - ($ - $$) db 0; is it Perl?

dw 0xAA55; bootsector magic number