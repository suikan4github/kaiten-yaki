#!/bin/bash

# Varidate whether script is executed as sourced or not
(return 0 2>/dev/null) && sourced=1 || sourced=0
if [ $sourced -eq 0 ] ; then
	cat <<HEREDOC 1>&2
***** ERROR : Must execute as source *****
Execute as following : 
source 3-post-install.sh

Installation terminates.
HEREDOC
	exit
fi

## Mount the target file system
# /target is created by the Ubiquity installer
mount /dev/mapper/${VGNAME}-${LVROOTNAME} /target

# And mount other directories
for n in proc sys dev etc/resolv.conf; do mount --rbind "/$n" "/target/$n"; done

# Change root
cat <<HEREDOC | chroot /target /bin/bash
```
# Mount the rest of partitions by target /etc/fstab
mount -a

# Set up the kernel hook of encryption
apt install -y cryptsetup-initramfs
echo "KEYFILE_PATTERN=/etc/luks/*.keyfile" >> /etc/cryptsetup-initramfs/conf-hook
echo "UMASK=0077" >> /etc/initramfs-tools/initramfs.conf

# Prepare a key file to embed in to the ramfs.
mkdir /etc/luks
dd if=/dev/urandom of=/etc/luks/boot_os.keyfile bs=4096 count=1
chmod u=rx,go-rwx /etc/luks
chmod u=r,go-rwx /etc/luks/boot_os.keyfile

# Add a key to the key file. Use the passphrase in the environment variable. 
printf %s "${PASSPHRASE}" | cryptsetup luksAddKey -d - "${DEV}${CRYPTPARTITION}" /etc/luks/boot_os.keyfile

# Add the LUKS volume information to /etc/crypttab to decrypt by kernel.  
echo "${CRYPTPARTNAME} UUID=$(blkid -s UUID -o value ${DEV}${CRYPTPARTITION}) /etc/luks/boot_os.keyfile luks,discard" >> /etc/crypttab

# Finally, update the ramfs initial image with the key file. 
update-initramfs -uk all

# Leave chroot
exit
HEREDOC

echo "3-para-install.sh : Done."