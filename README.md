# pc-snake

This is bloat free version of popular game `snake`. It fits entirely into drive's bootsector,
currently being playable at 476 bytes.

## Minimal system requirements

- Intel 8088 or newer
- 8kB of RAM
- IBM PC-compatible BIOS

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
