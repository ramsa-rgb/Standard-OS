[ORG 0x7c00]
[BITS 16]

section .code
_start:
    jmp 0x0000:boot
    times 8-($-$$) db 0

    ;	Boot Information Table
    bi_PrimaryVolumeDescriptor  resd  1    ; LBA of the Primary Volume Descriptor
    bi_BootFileLocation         resd  1    ; LBA of the Boot File
    bi_BootFileLength           resd  1    ; Length of the boot file in bytes
    bi_Checksum                 resd  1    ; 32 bit checksum
    bi_Reserved                 resb  40   ; Reserved 'for future standardization'

boot:
    ; A20 활성화
    in al, 0x92
    or al, 2
    out 0x92, al

    ; print
    mov ax, 0
    mov es, ax
    mov bx, Msg0
    call print

    ; VESA 정보 얻기
    xor ax, ax

    mov es, ax
    mov di, VBEMODE

    mov ax, 0x4f01
    mov cx, 0115h
    int 10h

    ; VESA 모드 설정

    mov ax, 0x4f02
    mov bx, 4115h
    int 10h

    ; E820 메모리 맵
    xor ax, ax

    mov es, ax
    mov di, 0x8400

    xor ebx, ebx

    e820.loop:
        mov edx, 534D4150h
        mov eax, 0xe820
        mov ecx, 24
        
        int 15h

        jc e820.loopend

        cmp eax, 534D4150h
        jne e820.loopend

        xor ch, ch
        add di, cx

        cmp ebx, 0
        je e820.loopend
        jne e820.loop
    e820.loopend:

    mov [E820END], di

    ; 32bit protected mode
    cli

    xor ax, ax
    mov ds, ax

    lgdt [GDTR]

    mov eax, cr0
    or eax, 1
    mov cr0, eax

    jmp 08h:protected_main

print:
    ; es:bx
    mov ah, 0x0e
    print.loop:
        mov al, [es:bx]

        cmp al, 0
        jz print.loopend

        int 10h
        add bx, 1

        jmp print.loop
    print.loopend:

    ret

[BITS 32]
protected_main:
    mov ax, 0x10

    mov ds, ax
    mov es, ax
    mov ss, ax
    mov esp, 0x9fc00

    xor eax, eax
    xor ebx, ebx
    xor ecx, ecx
    xor edx, edx

    ; 프레임버퍼 얻기 및 쓰기
    mov ebx, VBEMODE
    mov eax, [ebx + 0x28]

    mov [FrameBuffer], eax

    mov eax, E820END

    mov dword [esp-4], 0 ; bus
    mov dword [esp-8], 1 ; slot
    mov dword [esp-12], 0 ; function
    mov dword [esp-16], 0 ; offset

    sub esp, 16

    call pciwordread

    add esp, 16

    cli
    hlt
    jmp $

pciwordread:
    ; esp+16 bus
    ; esp+12 slot
    ; esp+8 function
    ; esp+4 offset
    ; esp+0 return address

    ; address ecx

    ; offset
    mov eax, [esp+4]
    and al, 0xfc

    add ecx, eax

    ; function
    mov eax, [esp+8]
    shl eax, 8

    add ecx, eax

    ; slot
    mov eax, [esp+12]
    shl eax, 11

    add ecx, eax
    
    ; bus
    mov eax, [esp+16]
    shl eax, 16

    add ecx, eax

    ; 보내기
    mov eax, ecx

    mov ecx, 1
    shl ecx, 31

    add eax, ecx

    mov dx, 0xcf8
    out dx, eax

    xor eax, eax

    mov dx, 0xcfc
    in ax, dx

    ; dx 반환
    ret


[BITS 16]
section .data
    Msg0 db "Standard OS is Booting...", 0

    GDT32:
        GDT32.NULL:
            dw 0 ; Limit Down
            dw 0 ; Base Down
            db 0 ; Base Middle
            db 0 ; Access
            db 0 ; Flags | Limit Top
            db 0 ; Base Top
        GDT32.CODE:
            dw 0xFFFF ; Limit Down
            dw 0 ; Base Down
            db 0 ; Base Middle
            db 0b10011010 ; Access
            db 0b11001111 ; Flags | Limit Top
            db 0 ; Base Top
        GDT32.DATA:
            dw 0xFFFF ; Limit Down
            dw 0 ; Base Down
            db 0 ; Base Middle
            db 0b10010011 ; Access
            db 0b11001111 ; Flags | Limit Top
            db 0 ; Base Top
    GDTR:
        dw GDTR - GDT32
        dd GDT32
    
    VBEMODE resb 256
    FrameBuffer dd 0
    E820END dd 0