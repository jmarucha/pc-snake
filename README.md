# pc-snake

This is bloat free version of popular game `snake`. It fits entirely into drive's bootsector,
currently being playable at 462 bytes (or 448, with unsafe optimizations turned on).

![gameplay](./aux/gameplay.gif)

## Minimal system requirements

- Intel 8088 or newer
- 32kB+ of RAM (theoretically 8kB+ is sufficient, but no compatible machine had this little)
- VGA-compatible card
- IBM PC-compatible BIOS supporting Option ROM

## Building nad installing

Use `make snake.img` to build the bootsector image. If you want to put this bootsector onto drive,
refer to `dd` manpage.

## Testing

`make run` and `make dosbox` runs the program with QEMU and Dosbox respecively.

## Debug

`make debug` starts QEMU interrupted and with debug server.

Use `gdb` to connect:

```bash
$ gdb

(gdb) target remote :1234
# stuff with breakpoints
(gdb) continue
```

`snake_debug.lst` contains location addresses, just add 8000h to address straight after label.

## Tested platforms

In emulation:

- QEMU
- 86Box:
    - IBM PC (1981) with 32 kB RAM, IBM VGA card and GLaBIOS 0.4.0
    - IBM PC (1982) with 64 kB RAM, IBM VGA card -- older BIOSes lack Option ROM support
    - IBM PC XT (1986), IBM PC AT, and Compaq Deskpro 386 with variety of VGA ISA cards.

On metal:

- AMD Ryzen 5800X with 32 GB of RAM and VESA-compatible card (Nvidia 3080)
