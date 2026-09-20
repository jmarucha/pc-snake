ASM = nasm
DOSBOX = dosbox-x

ASM_FILES = globals.asm consts.asm colors.asm keys.asm snake_game.asm

all: snake.img

snake.img: snake.asm $(ASM_FILES)
	$(ASM) snake.asm -f bin -o snake.img

snake_debug.img: snake_debug.asm $(ASM_FILES)
	$(ASM) snake_debug.asm -f bin -o snake_debug.img

debug: snake_debug.img
	qemu-system-i386 -drive format=raw,file=snake_debug.img


run: snake.img
	qemu-system-i386 -drive format=raw,file=snake.img

dosbox: snake.img
	$(DOSBOX) -conf dosbox.conf

clean:
	rm -f boot.bin snake.bin snake.img

stat:
	@wc -c *.bin
