
#!/bin/bash


mkfs.fat -F32 /dev/nvme0n1p1
mkswap /dev/nvme0n1p2
swapon
mkfs.ext4 /dev/nvme0n1p1

mount /dev/nvme0n1p3 /mnt


pacstrap /mnt base linux linux-firmware


genfstab -U /mnt >> /mnt/etc/fstab

arch-chroot /mnt << CHROOT


# Set timezone
ln -sf /usr/share/zoneinfo/India/Kolkata /etc/localtime
hwclock --systohc

# Install nano text editor
pacman -S --noconfirm nano

# Edit locale.gen file to uncomment en_IN.UTF-8
sed -i 's/#en_IN.UTF-8/en_IN.UTF-8/' /etc/locale.gen

# Generate locale
locale-gen

# Edit hostname file with nano
nano /etc/hostname
echo "breezelap" > /etc/hostname

# Edit hosts file with nano
nano /etc/hosts
echo "127.0.0.1 localhost" > /etc/hosts
echo "::1 localhost" >> /etc/hosts
echo "127.0.1.1 breezelap.localdomain breezelap" >> /etc/hosts

# Set root password
echo "Set root password:"
passwd
pass
pass

# Create a new user
useradd -m breeze
echo "Set password for user 'breeze':"
passwd breeze
pass
pass

# Add the new user to necessary groups
usermod -aG wheel,audio,video,optical,storage breeze

# Install sudo
pacman -S sudo

# Configure sudoers using nano
#EDITOR=nano visudo

# Install GRUB and related tools
pacman -S grub
pacman -S efibootmgr dosfstools os-prober mtools # If doing UEFI
mkdir /boot/EFI # If doing UEFI
mount /dev/nvme0n1p1 /boot/EFI # Mount FAT32 EFI partition (if doing UEFI)
grub-install --target=x86_64-efi --efi --bootloader-id=grub_uefi --recheck # If doing UEFI
grub-mkconfig -o /boot/grub/grub.cfg

# Install and enable NetworkManager
pacman -S networkmanager
systemctl enable NetworkManager

# Reboot the system
exit # Exit the chroot
umount -l /mnt # Unmount /mnt
reboot # Reboot the system
