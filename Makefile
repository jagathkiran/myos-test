IMG = myos.img
BOOT = bootboot/bootboot.efi
KERNEL = mykernel.x86_64.elf
UEFI_VARS = ovmf/OVMF_VARS.4m.fd
FONT = font.psf

CFLAGS = -Wall -fpic -ffreestanding -fno-stack-protector -nostdinc -nostdlib -Ibootboot/
LDFLAGS =  -nostdlib -n -T link.ld
STRIPFLAGS =  -s -K mmio -K fb -K bootboot -K environment -K initstack

.PHONY: all clean 

all : $(KERNEL) $(BOOT) $(IMG) 
	qemu-system-x86_64 \
  -drive if=pflash,format=raw,unit=0,file=ovmf/OVMF_CODE.4m.fd,readonly=on \
  -drive if=pflash,format=raw,unit=1,file=ovmf/OVMF_VARS.4m.fd \
  -drive file=myos.img,format=raw \
  -m 512M \
  -serial stdio \
  -vga virtio

$(IMG): $(KERNEL) $(BOOT)
	dd if=/dev/zero of=$(IMG) bs=1M count=64
	mkfs.fat -F 32 $(IMG)
	mkdir mnt
	sudo mount $(IMG) mnt
	sudo mkdir -p mnt/EFI/BOOT
	sudo mkdir -p mnt/BOOTBOOT
	sudo cp $(BOOT) mnt/EFI/BOOT/BOOTX64.EFI
	mkdir -p tmp/sys
	cp $(KERNEL) tmp/sys/core
	(cd tmp && tar -cf ../INITRD .)
	rm -rf tmp
	sudo cp INITRD mnt/BOOTBOOT/INITRD
	echo "screen=1280x1024" > CONFIG
	sudo cp CONFIG mnt/BOOTBOOT/CONFIG
	sudo umount mnt
	rmdir mnt

$(KERNEL): kernel.c font.psf
	x86_64-elf-gcc $(CFLAGS) -mno-red-zone -c kernel.c -o kernel.o
	x86_64-elf-ld -r -b binary -o font.o font.psf
	x86_64-elf-ld $(LDFLAGS) kernel.o font.o -o $(KERNEL)
	x86_64-elf-strip $(STRIPFLAGS) $(KERNEL)
	x86_64-elf-readelf -hls $(KERNEL) >mykernel.x86_64.txt

clean : 
	rm -f *.o $(KERNEL) *.txt $(IMG) INITRD CONFIG || true
	rm -rf mnt tmp || true
