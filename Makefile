IMG = myos.img
BOOT = bootboot.efi
KERNEL = mykernel.x86_64.elf
UEFI_VARS = OVMF_VARS.4m.fd

all : $(IMG) $(BOOT) $(KERNEL) $(UEFI_VARS)
	qemu-system-x86_64 \
  -drive if=pflash,format=raw,unit=0,file=/usr/share/edk2-ovmf/x64/OVMF_CODE.4m.fd,readonly=on \
  -drive if=pflash,format=raw,unit=1,file=OVMF_VARS.4m.fd \
  -drive file=myos.img,format=raw \
  -m 512M \
  -serial stdio \
  -vga virtio


