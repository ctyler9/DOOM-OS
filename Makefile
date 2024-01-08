ASM=nasm 

SRC_DIR=src
BUILD_DIR=build

$(BUILD_DIR)/main_floppy.img: $(BUILD_DIR)/bootloader.bin
	cp $(BUILD_DIR)/bootloader.bin $(BUILD_DIR)/main_floppy.img 
	truncate -s 1440k $(BUILD_DIR)/main_floppy.img

$(BUILD_DIR)/bootloader.bin: $(SRC_DIR)/bootloader/bootloader.asm
	$(ASM) $(SRC_DIR)/bootloader/bootloader.asm -f bin -o $(BUILD_DIR)/bootloader.bin

