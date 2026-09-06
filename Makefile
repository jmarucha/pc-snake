ASM = nasm
DOSBOX = dosbox-x

all: snake.img

boot.bin: boot.asm
	$(ASM) boot.asm -f bin -o boot.bin

snake.bin: snake.asm
	$(ASM) snake.asm -f bin -o snake.bin

snake.img: boot.bin snake.bin
	dd if=/dev/zero of=snake.img bs=512 count=2880
	dd if=boot.bin of=snake.img conv=notrunc
	dd if=snake.bin of=snake.img bs=512 seek=1 conv=notrunc

run: snake.img
	qemu-system-i386 -drive format=raw,file=snake.img

dosbox: snake.img
	$(DOSBOX) -conf dosbox.conf

clean:
	rm -f boot.bin snake.bin snake.img

stat:
	@wc -c *.bin
