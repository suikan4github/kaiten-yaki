#!/bin/bash

# Varidate whether script is executed as sourced or not
(return 0 2>/dev/null) && sourced=1 || sourced=0
if [ $sourced -eq 0 ] ; then
	cat <<HEREDOC 1>&2
***** ERROR : Must execute as source *****
Execute as following : 
source 3-post-install.sh

Installation terminated.
HEREDOC
	exit    # use "exit" instead of "return", if not "sourced" execusion
fi # "sourced" validation

## Mount the target file system
# /target is created by the Ubiquity installer
echo "...Mount /dev/mapper/${VGNAME}-${LVROOTNAME} on /mnt/target."
mount /dev/mapper/${VGNAME}-${LVROOTNAME} /mnt/target

# And mount other directories
echo "...Mount all other dirs."
for n in proc sys dev etc/resolv.conf; do mount --rbind "/$n" "/mnt/target/$n"; done

# Change root and create the keyfile and ramfs image for Linux kernel. 
echo "...Chroot to /target."
cat <<HEREDOC | chroot /mnt/target /bin/bash
# Mount the rest of partitions by target /etc/fstab
mount -a

# Set up the kernel hook of encryption
echo "...Install cryptsetup-initramfs package."
xbps-install -y lvm2 cryptsetup

# Prepare a key file to embed in to the ramfs.
echo "...Prepair key file."
mkdir /etc/luks
dd if=/dev/urandom of=/etc/luks/boot_os.keyfile bs=4096 count=1 status=none
chmod u=rx,go-rwx /etc/luks
chmod u=r,go-rwx /etc/luks/boot_os.keyfile

# Add a key to the key file. Use the passphrase in the environment variable. 
echo "...Add a key to the key file."
printf %s "${PASSPHRASE}" | cryptsetup luksAddKey -d - "${DEV}${CRYPTPARTITION}" /etc/luks/boot_os.keyfile

# Add the LUKS volume information to /etc/crypttab to decrypt by kernel.  
echo "...Add LUKS volume info to /etc/crypttab."
echo "${CRYPTPARTNAME} UUID=$(blkid -s UUID -o value ${DEV}${CRYPTPARTITION}) /etc/luks/boot_os.keyfile luks,discard" >> /etc/crypttab

echo "...Register key file to the ramfs"
echo 'install_items+=" /etc/luks/boot_os.keyfile /etc/crypttab " ' > /etc/dracut.conf.d/10-crypt.conf

# Finally, update the ramfs initial image with the key file. 
echo "...Upadte initramfs."
xbps-reconfigure -fa
echo "...grub-mkconfig."
grub-mkconfig -o /boot/grub/grub.cfg
echo "...update-grub."
update-grub

# Leave chroot
HEREDOC

# Unmount all
echo "...Unmount all."
umount -R /mnt/target

# Finishing message
cat <<HEREDOC
****************** Post-install process finished ******************

...Ready to reboot.
HEREDOC
