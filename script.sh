#!/bin/bash

# Partition the disk
fdisk /dev/vda << EOF
m
n
p
1


+1G
n
p
2

+2G
n
e
3



w
EOF

# Format the partitions
mkfs.fat -F32 /dev/vda1
mkswap /dev/vda2
swapon /dev/vda2
mkfs.ext4 /dev/vda3

# Mount the root partition
mount /dev/vda3 /mnt

# Install base system
if ! pacstrap /mnt base linux linux-firmware; then
    echo "Error: Failed to install base system."
    exit 1
fi

# Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Chroot into the new system
arch-chroot /mnt << CHROOT
# Set timezone
ln -sf /usr/share/zoneinfo/India/Kolkata /etc/localtime
hwclock --systohc

# Install nano text editor
pacman -S --noconfirm nano neovim sudo

# Edit locale.gen file
sed -i 's/#en_IN.UTF-8/en_IN.UTF-8/' /etc/locale.gen

# Generate locale
locale-gen

# Set hostname
echo "breezela" > /etc/hostname

# Edit hosts file
cat <<EOF > /etc/hosts
127.0.0.1 localhost
::1 localhost
127.0.1.1   breezela.localdomain breezela
EOF

# Set root password
passwd

# Create a new user
useradd -m user1
passwd user1

# Add the new user to necessary groups
usermod -aG wheel,audio,video,optical,storage user1

# Configure sudoers using visudo
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers

# Install GRUB and related tools
pacman -S --noconfirm grub efibootmgr dosfstools os-prober mtools
mkdir -p /boot/EFI
mount /dev/vda1 /boot/EFI
grub-install --target=x86_64-efi --efi-directory=/boot/EFI --bootloader-id=grub_uefi --recheck
grub-mkconfig -o /boot/grub/grub.cfg

# Install and enable NetworkManager
pacman -S --noconfirm networkmanager
systemctl enable NetworkManager

exit
CHROOT

echo "Installation complete. You can now reboot."
