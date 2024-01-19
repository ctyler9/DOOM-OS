UNAME := $(shell uname)

ifeq ($(UNAME),Linux)
	CC=gcc -elf_i386
	AS=as --32
	LD=ld -m elf_i386
else
	CC=i386-elf-gcc
	AS=i386-elf-as
	LD=i386-elf-ld
endif

GFLAGS=
CCFLAGS=-m32 -std=c11 -O2 -g -Wall -Wextra -Wpedantic -Wstrict-aliasing
CCFLAGS+=-Wno-pointer-arith -Wno-unused-parameter
CCFLAGS+=-nostdlib -nostdinc -ffreestanding -fno-pie -fno-stack-protector
CCFLAGS+=-fno-builtin-function -fno-builtin
ASFLAGS=
LDFLAGS=

BOOTSECT_SRCS=\
	src/stage0.S

DOOM_SRCS= src/doom.c src/doom2.c

BOOTSECT_OBJS=$(BOOTSECT_SRCS:.S=.o)

KERNEL_C_SRCS=$(filter-out $(DOOM_SRCS), $(wildcard src/*.c))
KERNEL_S_SRCS=$(filter-out $(BOOTSECT_SRCS), $(wildcard src/*.S))
KERNEL_OBJS=$(KERNEL_C_SRCS:.c=.o) $(KERNEL_S_SRCS:.S=.o)

BOOTSECT=bootsect.bin
KERNEL=kernel.bin
ISO=boot.iso

all: dirs bootsect kernel

clean:
	rm -f ./**/*.o
	rm -f ./*.iso
	rm -f ./**/*.elf
	rm -f ./**/*.bin

%.o: %.c
	$(CC) -o $@ -c $< $(GFLAGS) $(CCFLAGS)

%.o: %.S
	$(AS) -o $@ -c $< $(GFLAGS) $(ASFLAGS)

dirs:
	@echo "created bin"
	mkdir -p bin

bootsect: $(BOOTSECT_OBJS)
	@echo "making bootsect"
	$(LD) -o ./bin/$(BOOTSECT) $^ -Ttext 0x7C00 --oformat=binary

kernel: $(KERNEL_OBJS)
	@echo "making kernel"
	$(LD) -o ./bin/$(KERNEL) $^ $(LDFLAGS) -Tsrc/link.ld

doom: ./src/doom.c
	gcc -o ./bin/doom ./src/doom.c -lncurses -lm

doom2: ./src/doom2.c
	gcc -o ./bin/doom2 ./src/doom2.c -lncurses -lm
	gcc ./src/doom2.c $(ncursesw5-config --cflags) -o /bin/doom2 -lncursesw -lm

iso: dirs bootsect kernel
	@echo "Creating boot.iso"
	dd if=/dev/zero of=boot.iso bs=512 count=2880
	dd if=./bin/$(BOOTSECT) of=boot.iso conv=notrunc bs=512 seek=0 count=1
	dd if=./bin/$(KERNEL) of=boot.iso conv=notrunc bs=512 seek=1 count=2048


