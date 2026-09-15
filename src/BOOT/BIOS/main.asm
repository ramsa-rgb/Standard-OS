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
        
        add di, 24

        cmp ebx, 0
        je e820.loopend
        jne e820.loop
    e820.loopend:

    mov [E820END], di

    ; Get 8x16 Pointer
    mov ax, 0x1130
    mov bh, 6h

    int 10h

    ; Copy 8x16 Character (At 0x10000)
    mov ax, es
    mov ds, ax

    mov ax, 0x1000
    mov es, ax

    mov si, bp
    xor di, di

    mov cx, 2048 

    cld
    rep movsw

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
    mov ax, 0x10 ; 커널 데이터
    mov ds, ax

    mov ax, 0x10 ; 커널 스택
    mov ss, ax

    mov ax, 0x28
    ltr ax

    mov esp, 0x9fc00

    xor eax, eax
    xor ebx, ebx
    xor ecx, ecx
    xor edx, edx

    ; 프레임버퍼 얻기 및 쓰기
    mov ebx, VBEMODE
    mov eax, [ebx + 0x28]

    mov [FrameBuffer], eax

    ; Pitch 얻기
    mov ebx, VBEMODE
    mov ax, [ebx + 0x10]

    mov [Pitch], ax

    mov eax, E820END

    ; pciread를 위한 코드
    
    mov dword [esp-4], 0 ; datasize
    mov dword [esp-8], 0 ; bus
    mov dword [esp-12], 1 ; slot
    mov dword [esp-16], 0 ; function
    mov dword [esp-20], 0 ; offset

    sub esp, 20

    call pciread

    add esp, 20

    ; pciread를 위한 코드 끝

    ; 문자열 출력을 위한 코드

    mov eax, [Row]
    mov ebx, [Columns]
    mov dword [Color], 0x00FFFFFF
    mov edx, Msg0

    call gprint

    ; 문자열 출력을 위한 코드 끝

    ; pciread를 위한 코드
    
    mov dword [esp-4], 0 ; datasize
    mov dword [esp-8], 0 ; bus
    mov dword [esp-12], 31 ; slot
    mov dword [esp-16], 2 ; function
    mov dword [esp-20], 0 ; offset

    sub esp, 20

    call pciread

    add esp, 20

    ; pciread를 위한 코드 끝

    mov eax, 1
    cpuid

    shr edx, 9
    and edx, 1

    cmp edx, 1 

    jz nox2apicend

    nox2apic:
        ; 문자열 출력을 위한 코드
    
        mov eax, 18
        mov ebx, 35
        mov dword [Color], 0x00FFFFFF
        mov edx, Msg1

        call gprint

        mov eax, 19
        mov ebx, 44
        mov dword [Color], 0x00FF0000
        mov edx, SH

        call gprint

        ; 문자열 출력을 위한 코드 끝

        cli
        hlt 
    nox2apicend:

    ; APIC 베이스 얻기
    mov ecx, 0x1B
    rdmsr
    
    ; 얻은 APIC 베이스로 CPU에 APIC 등록.
    ; apic 주소는 eax에

    and eax, 0xfffff000

    mov [APIC], eax

    or eax, 0x800

    wrmsr

    mov eax, [APIC]
    add eax, 0x30
    mov edx, [eax]

    ; apic 활성화
    mov eax, [APIC + 0xf0]
    add eax, 0x100
    mov [APIC + 0xf0], eax

    cli
    hlt
    jmp $

gprint:
    ; eax row
    ; ebx col
    ; ecx charbuffer
    ; edx string

    push eax
    push ebx
    push ecx
    push ebp
    push esi
    push edi

    imul eax, 16
    imul ebx, 8

    gprint.charloop:
        xor ecx, ecx

        mov cl, [edx]

        imul ecx, 10h
        add ecx, 0x10000 ; char 폰트 있는 주소로 정의

        ; ebp로 카운트
        xor ebp, ebp

        push eax

        gprint.drawloop:

            push ecx
            mov ecx, [ecx]

            ; 비트 카운트
            xor esi, esi
            ; 줄 카운트
            xor edi, edi

            push ebx

            gprint.drawloop.bitloop:
                push edi
                push esi

                mov edi, esi
                and edi, 7
                xor edi, 7

                and esi, ~7
                add esi, edi

                bt ecx, esi

                pop esi
                pop edi

                jnc no

                yes:
                    call drawpixel
                no:

                add esi, 1
                add edi, 1
                add ebx, 1

                cmp edi, 8
                jne gprint.drawloop.bitloop.rowupend

                gprint.drawloop.bitloop.rowup:
                    add eax, 1
                    xor edi, edi
                    pop ebx

                    push ebx
                gprint.drawloop.bitloop.rowupend:

                cmp esi, 32
                jne gprint.drawloop.bitloop
            gprint.drawloop.bitloopend:
            
            pop ebx

            mov [0x100000 + ebp*4], ecx

            pop ecx

            add ecx, 4
            add ebp, 1

            cmp ebp, 4
            jne gprint.drawloop
        gprint.drawloopend:

        pop eax

        add dword [Columns], 1
        add edx, 1
        add ebx, 8

        cmp ebx, 800
        jnz gprint.charloop.rowupend

        gprint.charloop.rowup:
            xor ebx, ebx
            mov dword [Columns], 0

            push ebx

            mov ebx, [Row]
            add ebx, 1

            pop ebx

            add eax, 16
        gprint.charloop.rowupend:

        cmp byte [edx], 0
        jnz gprint.charloop
    gprint.charloopend:

    pop edi
    pop esi
    pop ebp
    pop ecx
    pop ebx
    pop eax

    ret

drawpixel:
    ; eax row
    ; ebx col

    push eax
    push ebx
    push ecx

    imul eax, [Pitch]
    imul ebx, 3

    add ebx, eax

    add ebx, [FrameBuffer]

    mov ecx, [Color]
    mov dword [ebx], ecx

    pop ecx
    pop ebx
    pop eax

    ret


pciread:
    ; esp+20 datasize
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

    ; esp+20이 0이면 eax
    ; 1이면 ax
    ; 2면 al

    mov ecx, [esp+20]
    cmp ecx, 1

    jg two
    jl zero
    jz one

    zero:
        in eax, dx
        ret
    one:
        in ax, dx
        ret
    two:
        in al, dx
        ret


[BITS 16]
section .data
    Msg0 db "Standard OS is Booting...", 0
    Msg1 db "The CPU wasn't support x2apic.", 0

    SH db "System Halted", 0
    GDT32:
        GDT32.NULL:
            dw 0 ; Limit Down
            dw 0 ; Base Down
            db 0 ; Base Middle
            db 0 ; Access
            db 0 ; Flags | Limit Top
            db 0 ; Base Top
        GDT32.KRNLCODE:
            dw 0xFFFF ; Limit Down
            dw 0 ; Base Down
            db 0 ; Base Middle
            db 0b10011010 ; Access
            db 0b11001111 ; Flags | Limit Top
            db 0 ; Base Top
        GDT32.KRNLDATA:
            dw 0xFFFF ; Limit Down
            dw 0 ; Base Down
            db 0 ; Base Middle
            db 0b10010011 ; Access
            db 0b11001111 ; Flags | Limit Top
            db 0 ; Base Top
        GDT32.USERCODE:
            dw 0xFFFF ; Limit Down
            dw 0 ; Base Down
            db 0 ; Base Middle
            db 0b11111010 ; Access
            db 0b11001111 ; Flags | Limit Top
            db 0 ; Base Top
        GDT32.USERDATA:
            dw 0xFFFF ; Limit Down
            dw 0 ; Base Down
            db 0 ; Base Middle
            db 0b11110011 ; Access
            db 0b11001111 ; Flags | Limit Top
            db 0 ; Base Top
        GDT32.TSS: ; 0x68
            dw 0x68 ; Limit Down
            dw 0 ; Base Down
            db 0x10 ; Base Middle
            db 0b10001001 ; Access
            db 0b00000000 ; Flags | Limit Top
            db 0 ; Base Top
    GDTR:
        dw GDTR - GDT32
        dd GDT32
    
    VBEMODE resb 256
    FrameBuffer dd 0
    E820END dd 0
    Pitch dd 0

    APIC dq 0

    Color dd 0
    Row dd 0
    Columns dd 0