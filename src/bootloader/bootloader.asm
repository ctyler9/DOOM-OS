org 0x7C00
bits 16

%define ENDL 0x0D, 0x0A

start:
    jmp main

main:
    ; disable interrupts
    cli 

    ; set up data segments
    mov ax, 0 
    mov ds, ax
    mov es, ax

    ; setup stack 
    mov ss, ax 
    mov sp, 0x7c00      ; stack grows downwards from where we are loaded in memory

    ;save drive number to read kernel later 
    mov dl, drive_num

    ; enable interrupts 
    sti 

    ; print message 
    mov si, msg_hello 
    call print 

    hlt
    
    ; read kernel into memory at 0x1000
    mov cx, 20 
    mov dl, drive_num 
    mov si, disk_packet 
    mov segment, 0x1000
    mov sector, 1


sector_loop:
    mov ah, 0x42        ; Move the immediate value 0x42 into AH
    int 0x13            ; readv sys call 

    jc disk_error       ; Jump to 'disk_error' label if the carry flag is set

    add word ptr [sector], 64      ; Add 64 to the value stored at 'sector'
    add word ptr [offset], 0x8000   ; Add 0x8000 to the value stored at 'offset'
    jnc sector_same_segment        ; Jump to 'sector_same_segment' if no carry flag is set

    ; Increment 'segment', reset 'offset' if on a different segment
    add word ptr [segment], 0x1000  ; Add 0x1000 to the value stored at 'segment'
    mov word ptr [offset], 0x0000   ; Move the immediate value 0x0000 into 'offset'

sector_same_segment:
    ; Decrements CX and loops if nonzero
    loop sector_loop

    ; Video mode: 320x200 @ 16 colors
    mov ah, 0x00
    mov al, 0x13
    int 0x10        ; ioctyl sys call

    ; Enable A20 line
    cli

    ; Read and save state
    call enable_a20_wait0
    mov al, 0xD0
    out 0x64, al
    call enable_a20_wait1
    xor ax, ax
    in al, 0x60

    ; Write new state with A20 bit set (0x2)
    push ax
    call enable_a20_wait0
    mov al, 0xD1
    out 0x64, al
    call enable_a20_wait0
    pop ax
    or ax, 0x2
    out 0x60, al

    ; Enable PE flag
    mov eax, cr0
    or eax, 0x1
    mov cr0, eax

    ; Jump to flush prefetch queue
    jmp flush

flush:
    lidt idt
    lgdt gdtp

    mov ax, gdt_data_segment - gdt_start
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x3000
    jmp 0x8:entry32

bits 32    ; Specify 32-bit mode for the following code

entry32:
    ; Jump to the kernel loaded at 0x10000
    mov eax, 0x10000
    jmp dword [eax]

_loop:
    jmp _loop

bits 16    ; Specify 16-bit mode for the following code

enable_a20_wait0:
    xor ax, ax
    in al, 0x64
    btc ax, 1
    jc enable_a20_wait0
    ret

enable_a20_wait1:
    xor ax, ax
    in al, 0x64
    btc ax, 0
    jnc enable_a20_wait1
    ret

;
; print a string to the screen 
; Params: 
;   - ds:si points to string 
;
print:
    ; save registers we will modify 
    push si 
    push ax 
    push bx 

.loop: 
    lodsb   ; loads next character in al 
    or al, al   ; verify if next chracter is null?
    jz .done 

    mov ah, 0x0E    ; call bios interrupt 
    mov bh, 0       ; set page number to 0 
    int 0x10

    jmp .loop

.done: 
    pop bx 
    pop ax 
    pop si 
    ret


; vars 
drive_num: 
    dw 0x0000

disk_packet:
    db 0x10, 0x00

num_sectors:
    dw 0x0040

offset:
    dw 0x0000

segment:
    dw 0x0000

sector:
    dq 0x00000000


drive_num: db 0x0000
msg_hello: db "DOOM-OS", ENDL, 0
msg_hello2: db "DOOOOOOM-OS", ENDL, 0
msg_error: db "DISK Error", ENDL, 0

align 16
gdtp:
    dw gdt_end - gdt_start - 1
    dd gdt_start

align 16
gdt_start:
gdt_null:
    dq 0
gdt_code_segment:
    dw 0xffff
    dw 0x0000
    db 0x00
    db 0b10011010
    db 0b11001111
    db 0x00
gdt_data_segment:
    dw 0xffff
    dw 0x0000
    db 0x00
    db 0b10010010
    db 0b11001111
    db 0x00
gdt_end:


; MBR BOOT SIGNATURE
times 510-($-$$) db 0
dw 0AA55h
