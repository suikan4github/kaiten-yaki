#!/bin/bash

# Include configuration. This sript file have to be executed at Kaiten-yaki/script dir
# shellcheck disable=SC1091
source config.sh

# Create a key file for LUKS and register it as contents of the initramfs image
function chrooted_job() {
		# Mount the rest of partitions by target /etc/fstab
		mount -a

		# Set up the kernel hook of encryption
		echo "...Installing cryptsetup-initramfs package."
		xbps-install -y lvm2 cryptsetup

		# Prepare a key file to embed in to the ramfs.
		echo "...Prepairing key file."
		mkdir /etc/luks
		dd if=/dev/urandom of=/etc/luks/boot_os.keyfile bs=4096 count=1 status=none
		chmod u=rx,go-rwx /etc/luks
		chmod u=r,go-rwx /etc/luks/boot_os.keyfile

		# Add a key to the key file. Use the passphrase in the environment variable. 
		echo "...Adding a key to the key file."
		printf %s "${PASSPHRASE}" | cryptsetup luksAddKey -d - "${DEV}${CRYPTPARTITION}" /etc/luks/boot_os.keyfile

		# Add the LUKS volume information to /etc/crypttab to decrypt by kernel.  
		echo "...Adding LUKS volume info to /etc/crypttab."
		echo "${CRYPTPARTNAME} UUID=$(blkid -s UUID -o value ${DEV}${CRYPTPARTITION}) /etc/luks/boot_os.keyfile luks,discard" >> /etc/crypttab

		# Putting key file into the ramfs initial image
		echo "...Registering key file to the ramfs"
		echo 'install_items+=" /etc/luks/boot_os.keyfile /etc/crypttab " ' > /etc/dracut.conf.d/10-crypt.conf

		# Finally, update the ramfs initial image with the key file. 
		echo "...Upadting initramfs."
		xbps-reconfigure -fa
		echo "...grub-mkconfig."
		grub-mkconfig -o /boot/grub/grub.cfg

		# Leave chroot
}

# Execute job
chrooted_job
