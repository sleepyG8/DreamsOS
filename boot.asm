; Will add jmp to kernel when I write it, Im in no rush to finish this right now
; This boots into 32 bit protected mode and prints
; Next step is embedding a kernel and jmp to it easy stuff

[org 0x7C00]

cld
cli

; Set ES to the destination segment (0x0300 -> physical 0x3000)
xor ax, ax 
mov ds, ax
mov es, ax

;mov si, code        ; source = address of db buffer
;mov  di, 0x1000      ; destination = physical 0x3000
;mov cx, code_end - code  ; length of buffer

rep movsb     ; si -> di

;jmp 0x0000:0x1000

in al, 0x92
or al, 2		; setup A20
out 0x92, al

lgdt [gdtr]                 ; load GDTR with size+base of GDT

mov ah, 0x00
mov al, 0x03
int 0x10

mov eax, cr0
or  eax, 1                  ; set PE bit (bit 0)
mov cr0, eax

jmp 0x08:pmode_entry        ; far jump to 32-bit code segment selector

; ---------------------
; 32-bit protected mode
; ---------------------
[bits 32]
pmode_entry:
    mov ax, 0x10            ; data segment selector
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x9FC00

    mov ax, 0x10
    mov ds, ax

mov word [dword 0x1000], 0x0753
mov ebx, [dword 0x1000]

mov [dword 0xB8000], ebx   ; 'S'
mov word [0xB8002], 0x074C   ; 'L'
mov word [0xB8004], 0x0745   ; 'E'
mov word [0xB8006], 0x0745   ; 'E'
mov word [0xB8008], 0x0750   ; 'P'

;mov esi, code
;mov edi, 0x1000
;mov ecx, code_end - code

;rep movsb

;jmp dword 0x08:0x1000

mov edi, 0xB8010
.key2:
    in al, 0x64        ; read status
    test al, 1
    jz .key2

    in al, 0x60        ; read scan code
    ; AL now contains the scan code

    mov ah, 0x07       ; attribute (light grey on black)
    mov byte [edi], al  ; print scan code as a character

    cmp al, 0x10
    je QPress

    add edi, 0x00002
    jmp .key2


QPress: 

    clear_screen:
    mov edi, 0xB8000        ; VGA memory
    mov ecx, 2000           ; number of cells
    mov ax, 0x0720          ; space with attribute

    .clear_loop:
    mov [edi], ax
    add edi, 2
    loop .clear_loop


    mov edi, 0xB8000
    mov word [edi],  0x0753   ; S
    add edi, 0x00002
    mov word [edi],  0x074C   ; L
    add edi, 0x00002
    mov word [edi],  0x0745   ; E
    add edi, 0x00002
    mov word [edi],  0x0745   ; E
    add edi, 0x00002
    mov word [edi],  0x0750   ; P
    add edi, 0x00002
    mov word [edi], 0x073E      ; >
    add edi, 0x00004

    jmp .key

.key:
    in al, 0x64        ; read status
    test al, 1
    jz .key

    in al, 0x60        ; read scan code
    ; AL now contains the scan code

    mov ah, 0x07       ; attribute (light grey on black)
    mov [edi], al  ; print scan code as a character

    cmp al, 0x10
    je QPress

    add edi, 0x00002
    jmp .key


hang: jmp hang

[bits 16]
gdt_start:
    dq 0x0000000000000000           ; null

    ; 32-bit code: base=0, limit=4GiB, gran=4KiB, present, ring 0
    ; 0x00CF9A000000FFFF = limit(FFFF) base(00000000) flags(9A) gran(CF)
    dq 0x00CF9A000000FFFF

    ; 32-bit data: base=0, limit=4GiB, gran=4KiB, present, ring 0
    dq 0x00CF92000000FFFF
gdt_end:

gdtr:
    dw gdt_end - gdt_start - 1
    dd gdt_start

;jmp 0x0000:0x1000	        ; call code

code:

    mov eax, 0x10
    mov ebx, eax
    mov word [dword 0xB8012], 0x0753
    
    jmp $

code_end:

times 510-($-$$) db 0
dw 0xAA55

jmp $

