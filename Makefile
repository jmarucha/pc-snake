ASM = nasm
DOSBOX = dosbox-x

ASM_FILES = $(wildcard *.asm)
SETTINGS=settings.asm

all: snake.img

snake.img: $(ASM_FILES)
	$(ASM) -p $(SETTINGS) bootsector.asm -f bin -o snake.img

snake_lean.img: $(ASM_FILES)
	$(ASM) -p settings_lean.asm bootsector.asm -f bin -o snake_lean.img

snake_standard.img: $(ASM_FILES)
	$(ASM) -p settings.asm bootsector.asm -f bin -o snake_standard.img

snake_debug.img: $(ASM_FILES)
	$(ASM) -p $(SETTINGS) bootloader.asm -f bin -o snake_debug.img -l snake_debug.lst

debug_and_stop: snake_debug.img
	qemu-system-i386 -drive format=raw,file=snake_debug.img -S -s

debug_and_run: snake_debug.img
	qemu-system-i386 -drive format=raw,file=snake_debug.img -s


run: snake.img
	qemu-system-i386 -drive format=raw,file=snake.img

dosbox: snake.img
	truncate -s360K snake.img
	$(DOSBOX) -conf dosbox.conf

clean:
	rm -f boot.bin snake.bin snake.img

stat:
	@wc -c *.bin
