cl = C:\Program Files\Microsoft Visual Studio\18\Community\VC\Tools\MSVC\14.51.36231\bin\Hostx64\x86\cl.exe
link = C:\Program Files\Microsoft Visual Studio\18\Community\VC\Tools\MSVC\14.51.36231\bin\Hostx64\x86\link.exe

fe := $(wildcard obj)

all: bin/standardos.iso

bin/standardos.iso: BOOTINBIOS BOOTINUEFI
	xorriso -as mkisofs -o bin/standardos.iso -iso-level 4 -r -J -eltorito-alt-boot -b BOOT/BIOS/BOOT -no-emul-boot -boot-load-size 4 -boot-info-table -eltorito-alt-boot -e BOOT/UEFI/ESP.img -no-emul-boot iso/

ifeq ($(OS), Windows_NT)
ifeq ($(fe), )
BOOTINBIOS: src/BOOT/BIOS/main.asm
	mkdir obj
	mkdir obj\BOOT
	mkdir obj\BOOT\BIOS
	mkdir obj\BOOT\UEFI
	mkdir obj\KRNL

	mkdir iso
	mkdir iso\BOOT
	mkdir iso\BOOT\BIOS
	mkdir iso\BOOT\UEFI

	mkdir bin

	nasm -f bin src/BOOT/BIOS/main.asm -o iso/BOOT/BIOS/BOOT
else
BOOTINBIOS: src/BOOT/BIOS/main.asm
	nasm -f bin src/BOOT/BIOS/main.asm -o iso/BOOT/BIOS/BOOT
endif
else
BOOTINBIOS: src/BOOT/BIOS/main.asm
ifeq ($(fe), )
	mkdir obj
	mkdir obj/BOOT
	mkdir obj/BOOT/BIOS
	mkdir obj/BOOT/UEFI
	mkdir obj/KRNL

	mkdir iso
	mkdir iso/BOOT
	mkdir iso/BOOT/BIOS
	mkdir iso/BOOT/UEFI

	mkdir bin

	nasm -f bin src/BOOT/BIOS/main.asm -o iso/BOOT/BIOS/BOOT
else
BOOTINBIOS: src/BOOT/BIOS/main.asm
	nasm -f bin src/BOOT/BIOS/main.asm -o iso/BOOT/BIOS/BOOT
endif
endif

ifeq ($(OS), Windows_NT)
BOOTINUEFI: src/BOOT/UEFI/main.c
	$(cl) /Isrc/BOOT/UEFI /arch:IA32 /nologo /c /GS- /GR- /Oi- src/BOOT/UEFI/main.c /Foobj/BOOT/UEFI/main.obj
	$(link) /SUBSYSTEM:EFI_APPLICATION /ENTRY:EFI_MAIN /MACHINE:X86 /OUT:obj/BOOT/UEFI/BOOTIA32.EFI obj/BOOT/UEFI/main.obj

	del iso\BOOT\UEFI\ESP.img
	fsutil file createnew iso/BOOT/UEFI/ESP.img 10485760

	mkfs.vfat iso/BOOT/UEFI/ESP.img

	mmd -i iso/BOOT/UEFI/ESP.img ::/EFI
	mmd -i iso/BOOT/UEFI/ESP.img ::/EFI/BOOT
	mcopy -i iso/BOOT/UEFI/ESP.img obj/BOOT/UEFI/BOOTIA32.EFI ::/EFI/BOOT
else
BOOTINUEFI: src/BOOT/UEFI/main.c
	clang -c -ffreestanding -nostdlib -fno-builtin -nostdinc++ --target=i686-pc-windows-msvc -Isrc/BOOT/UEFI src/BOOT/UEFI/main.c -o obj/BOOT/UEFI/main.obj
	lld-link /entry:EFI_MAIN /subsystem:EFI_APPLICATION /machine:X86 /out:obj/BOOT/UEFI/BOOTIA32.EFI obj/BOOT/UEFI/main.obj

	rm -f iso/BOOT/UEFI/ESP.img
	dd if=/dev/zero of=iso/BOOT/UEFI/ESP.img bs=10485760 count=1

	mkfs.vfat iso/BOOT/UEFI/ESP.img

	mmd -i iso/BOOT/UEFI/ESP.img ::/EFI
	mmd -i iso/BOOT/UEFI/ESP.img ::/EFI/BOOT
	mcopy -i iso/BOOT/UEFI/ESP.img obj/BOOT/UEFI/BOOTIA32.EFI ::/EFI/BOOT
endif

ifeq ($(OS), Windows_NT)
runuefi:
	qemu-system-x86_64 -device vmware-svga,vgamem_mb=256 -device e1000 -machine pc-q35-10.2,acpi=on,usb=on,sata=on -cpu Skylake-Client,+x2apic -m 2G -drive if=pflash,file="C:\Program Files\qemu\share\edk2-i386-code.fd",format=raw,index=0 -cdrom bin/standardos.iso -monitor stdio
else
runuefi:
	qemu-system-x86_64 -device vmware-svga,vgamem_mb=256 -device e1000 -machine pc-q35-10.2,acpi=on,usb=on,sata=on -cpu Skylake-Client,+x2apic -m 2G -drive if=pflash,file="~/../usr/share/qemu/edk2-i386-code.fd",format=raw,index=0 -cdrom bin/standardos.iso -monitor stdio
endif

runbios:
	qemu-system-x86_64 -device vmware-svga,vgamem_mb=256 -device e1000 -machine pc-q35-10.2,acpi=on,usb=on,sata=on -cpu Skylake-Client,+x2apic -m 2G -cdrom bin/standardos.iso -monitor stdio

ifeq ($(OS), Windows_NT)
clean:
	del obj\BOOT\UEFI\BOOTIA32.EFI
	del obj\BOOT\UEFI\main.obj

	del iso\BOOT\BIOS\BOOT
	del iso\BOOT\UEFI\ESP.img

	del bin\standardos.iso
else
clean:
	rm -f obj/BOOT/UEFI/BOOTIA32.EFI
	rm -f obj/BOOT/UEFI/main.obj

	rm -f iso/BOOT/BIOS/BOOT
	rm -f ESP.img

	rm -f bin/standardos.iso
endif