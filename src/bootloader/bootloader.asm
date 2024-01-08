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

    jmp $   ; infinite loop

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


drive_num: db 0x0000
msg_hello: db "DOOM-OS", ENDL, 0
msg_error: db "DISK Error", ENDL, 0


; MBR BOOT SIGNATURE
times 510-($-$$) db 0
dw 0AA55h
