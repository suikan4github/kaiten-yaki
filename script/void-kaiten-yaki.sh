#!/bin/bash -u

function main() {
	# Load configuration parameter
	source config.sh

	# Load functions
	source lib/confirmation.sh
	source lib/preinstall.sh
	# source lib/parainstall.sh # we have customized parainstall
	source lib/parainstall_msg.sh


	# This is the mount point of the install target. 
	export TARGETMOUNTPOINT="/mnt/target"

	# Distribution check
	if ! uname -a | grep void -i > /dev/null ; then	# "Void" is not found in the OS name.
		echo "*********************************************************************************"
		uname -a
		cat <<- HEREDOC 
		*********************************************************************************
		This system seems to be not Void Linux, while this script is dediated to the Void Linux.
		Are you sure you want to run this script for installation? [Y/N]
		HEREDOC
		read YESNO
		if [ ${YESNO} != "Y" -a ${YESNO} != "y" ] ; then
			cat <<- HEREDOC 1>&2

			...Installation process terminated..
			HEREDOC
			return
		fi	# if YES

	fi # "Void" is not found in the OS name.

	# ******************************************************************************* 
	#                                Confirmation before installation 
	# ******************************************************************************* 

	# Common part of the parameter confirmation
	if ! confirmation ; then
		return 1 # with error status
	fi

	# ******************************************************************************* 
	#                                Pre-install stage 
	# ******************************************************************************* 

	# Install essential packages.
	xbps-install -y -Su xbps gptfdisk

	# Common part of the pre-install stage
	if ! pre_install ; then
		return 1 # with error status
	fi

	# ADD "rd.auto=1 cryptdevice=/dev/sda2:${CRYPTPARTNAME} root=/dev/mapper/${VGNAME}-${ROOTNAME}" to GRUB.
	# This is magical part. I have not understood why this is required. 
	# Anyway, without this modification, Void Linux doesn't boot. 
	# Refer https://wiki.voidlinux.org/Install_LVM_LUKS#Installation_using_void-installer
	echo "...Modify /etc/default/grub."
	sed -i "s#loglevel=4#loglevel=4 rd.auto=1 cryptdevice=${DEV}${CRYPTPARTITION}:${CRYPTPARTNAME} root=/dev/mapper/${VGNAME}-${LVROOTNAME}#" /etc/default/grub

	# ******************************************************************************* 
	#                                Para-install stage 
	# ******************************************************************************* 

	# Show common message to let the operator focus on the critical part
	parainstall_msg
	# Void-Linux dependent message
	cat <<- HEREDOC

	************************ CAUTION! CAUTION! CAUTION! ****************************
	
	Make sure to click "NO", if the void-installer ask you to reboot.
	Just exit the installer without rebooting. Other wise, your system
	is unable to boot. 

	Type return key to start void-installer.
	HEREDOC

	# waitfor a console input
	read dummy_var

	# Start the background target/etc/default/grub cheker.
	# The definition of this function is down below.
	grub_check_and_modify &

	# Record the PID of the background checker. 
	grub_check_and_modify_id=$!

	# Start void-installer 
	void-installer 
	
	# Check if background checker still exist
	if ps $grub_check_and_modify_id  > /dev/null ; then	# If exists
	# If exist, the grub was not modifyed -> void-installer termianted unexpectedly
		cat <<-HEREDOC 1>&2
		***** ERROR : The GUI/TUI installer terminated unexpectedly. ***** 
		...Deleting the new logical volume "${VGNAME}-${LVROOTNAME}".
		HEREDOC
		lvremove -f /dev/mapper/${VGNAME}-${LVROOTNAME} 
		echo "...Deactivating all logical volumes in volume group \"${VGNAME}\"."
		vgchange -a n ${VGNAME}
		echo "...Closing LUKS volume \"${CRYPTPARTNAME}\"."
		cryptsetup close  ${CRYPTPARTNAME}
		cat <<-HEREDOC 1>&2

		...The new logical volume has been deleted. You can retry Kaiten-yaki again. 
		...Installation process terminated.
		HEREDOC
		return 1 # with error status
	fi

	# At here, the installation was successful. 

	# ******************************************************************************* 
	#                                Post-install stage 
	# ******************************************************************************* 

	## Mount the target file system
	# ${TARGETMOUNTPOINT} is created by the GUI/TUI installer
	echo "...Mounting /dev/mapper/${VGNAME}-${LVROOTNAME} on ${TARGETMOUNTPOINT}."
	mount /dev/mapper/${VGNAME}-${LVROOTNAME} ${TARGETMOUNTPOINT}

	# And mount other directories
	echo "...Mounting all other dirs."
	for n in proc sys dev etc/resolv.conf; do mount --rbind "/$n" "${TARGETMOUNTPOINT}/$n"; done

	# Change root and create the keyfile and ramfs image for Linux kernel. 
	echo "...Chroot to ${TARGETMOUNTPOINT}."
	cat <<- HEREDOC | chroot ${TARGETMOUNTPOINT} /bin/bash
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
	echo "...update-grub."
	update-grub

	# Leave chroot
	HEREDOC

	# Unmount all
	echo "...Unmounting all."
	umount -R ${TARGETMOUNTPOINT}

	# Finishing message
	cat <<- HEREDOC
	****************** Post-install process finished ******************

	...Ready to reboot.
	HEREDOC

	# Normal end
	return 0
}


# This function will be executed in the background context, to watch the TUI installer. 
function grub_check_and_modify() {

	# While the /etc/default/grub in the install target is NOT existing, keep sleeping.
	# If installer terminated without file copy, this script also terminates.
	while [ ! -e ${TARGETMOUNTPOINT}/etc/default/grub ]
	do
		sleep 1 # 1sec.
	done # while

	# Perhaps, too neuvous. Wait 1 more sectond to avoid the rece condition.
	sleep 1 # 1sec.

	# Make target GRUB aware to the crypt partition
	# This must do it after start of the file copy by installer, but before the end of the file copy.
	echo "...Adding GRUB_ENABLE_CRYPTODISK entry to ${TARGETMOUNTPOINT}/etc/default/grub "
	echo "GRUB_ENABLE_CRYPTODISK=y" >> ${TARGETMOUNTPOINT}/etc/default/grub

	# succesfull return
	return 0

} # para install

# Execute
main