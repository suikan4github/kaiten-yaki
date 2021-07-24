#!/bin/bash

# Create a key file for LUKS and register it as contents of the initramfs image
function chrooted_job() {
	# Mount the rest of partitions by target /etc/fstab
	mount -a

	# Prepare the crypto tool in the install target
	echo "...Installing cryptsetup-initramfs package."
	xbps-install -y lvm2 cryptsetup

	# Prepare a new key file to embed in to the ramfs.
	# This new file contains a new key to open the LUKS volume. 
	# The new key is 4096byte length binary value. 
	# Because this key is sotred as "cleartext", in the target file sysmte,
	# only root is allowed to access this key file. 
	echo "...Prepairing key file."
	mkdir /etc/luks
	dd if=/dev/urandom of=/etc/luks/boot_os.keyfile bs=4096 count=1 status=none
	chmod u=rx,go-rwx /etc/luks
	chmod u=r,go-rwx /etc/luks/boot_os.keyfile

	# Add the new key to the LUKS 2nd key slot. The passphrase is required to modify the LUKS keyslot.  
	echo "...Adding a key to the key file."
	printf %s "${PASSPHRASE}" | cryptsetup luksAddKey --iter-time "${ITERTIME}" -d - "${DEV}${CRYPTPARTITION}" /etc/luks/boot_os.keyfile

	# Register the LUKS voluem to /etc/crypttab to tell "This volume is encrypted" 
	echo "...Adding LUKS volume info to /etc/crypttab."
	echo "${CRYPTPARTNAME} UUID=$(blkid -s UUID -o value ${DEV}${CRYPTPARTITION}) /etc/luks/boot_os.keyfile luks,discard" >> /etc/crypttab

	# Add key file to the list of the intems in initfsram. 
	# See https://man7.org/linux/man-pages/man5/dracut.conf.5.html for details.
	echo "...Directing to include keyfile into the initfsram"
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
