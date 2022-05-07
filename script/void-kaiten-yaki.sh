#!/bin/bash -u

	# shellcheck disable=SC1091
	# Load configuration parameter
	source ./config.sh

	# Load common functions
	source ./lib/common.sh

function main() {

	# This is the mount point of the install target. 
	export TARGETMOUNTPOINT="/mnt/target"

	# ******************************************************************************* 
	#                                Confirmation before installation 
	# ******************************************************************************* 

	# parameters for distribution check
	export DISTRIBUTIONSIGNATURE="void"
	export DISTRIBUTIONNAME="Void Linux"

	# Check whetehr given signature exist or not
	if ! distribution_check ; then
		return 1 # with error status
	fi

	# Common part of the parameter confirmation
	if ! confirmation ; then
		return 1 # with error status
	fi

	# ******************************************************************************* 
	#                                Pre-install stage 
	# ******************************************************************************* 

	# Install essential packages.
	xbps-install -y -Su xbps gptfdisk

	# ADD "rd.auto=1 cryptdevice=/dev/sda2:${CRYPTPARTNAME} root=/dev/mapper/${VGNAME}-${ROOTNAME}" to GRUB.
	# This is magical part. I have not understood why this is required. 
	# Anyway, without this modification, Void Linux doesn't boot. 
	# Refer https://wiki.voidlinux.org/Install_LVM_LUKS#Installation_using_void-installer
	# This modification is guaratnteed once only. To allow  re-trying the installation after unexpected GUI/TUI installer quit. 
	export GRUB_ADDITIONAL_PARAMETERS="rd.auto=1 cryptdevice=${DEV}${CRYPTPARTITION}:${CRYPTPARTNAME} root=/dev/mapper/${VGNAME}-${LVROOTNAME}"
	if grep "$GRUB_ADDITIONAL_PARAMETERS" /etc/default/grub ; then	# Is additonal parameter already added? 
		# Yes 
		echo ".../etc/default/grub already modified. OK, skipping to modiy."
	else
		# Not yet. Let's add.
		echo "...Modify /etc/default/grub."
		sed -i -e  "/GRUB_CMDLINE_LINUX_DEFAULT/{s#\"#  ${GRUB_ADDITIONAL_PARAMETERS}\"#2}"  /etc/default/grub
	fi

	# Common part of the pre-install stage
	if ! pre_install ; then
		# If error, restore the modification.
		echo "...restoring /etc/default/grub, if needed"
		sed -i -e "s#${GRUB_ADDITIONAL_PARAMETERS}##" /etc/default/grub
		return 1 # with error status
	fi


	# ******************************************************************************* 
	#                                Para-install stage 
	# ******************************************************************************* 

	# Start the TUI installer and modify the target /etc/default/grub in background
	if ! para_install_local ; then
		return 1 # with error status
	fi

	# ******************************************************************************* 
	#                                Post-install stage 
	# ******************************************************************************* 

	# We don't need special option for BTRFSOPTION. 
	export BTRFSOPTION=""

	# Distribution dependent finalizing. Embedd encryption key into the ramfs image. 
	# The script is parameterized by env-variable to fit to the distribution 
	post_install

	# Free LUKS volume as swap volume.
	swapoff -a

	# Normal end
	return 0

}	# End of main()


# ******************************************************************************* 
# Void Linux dependent post-installation process
function para_install_local() {
	# Show common message to let the operator focus on the critical part
	para_install_msg

	# Distrobution dependent message
	cat <<- HEREDOC

	************************ CAUTION! CAUTION! CAUTION! ****************************
	
	Make sure to click "NO", if the void-installer ask you to reboot.
	Just exit the installer without rebooting. Other wise, your system
	is unable to boot. 

	Type return key to start void-installer.
	HEREDOC

	# waiting for a console input
	read -r

	# Start the background target/etc/default/grub cheker.
	# The definition of this function is down below.
	grub_check_and_modify_local &

	# Record the PID of the background checker. 
	grub_check_and_modify_id=$!

	# Start void-installer 
	void-installer 
	
	# Check if background checker still exist
	if ps $grub_check_and_modify_id  > /dev/null ; then	# If exists
		# If exist, the grub was not modifyed -> void-installer termianted unexpectedly
		# Delete the nwe volume if overwrite install, and close all
		on_unexpected_installer_quit
		echo "...restoring modified /etc/default/grub."
		sed -i "s#loglevel=4 ${GRUB_ADDITIONAL_PARAMETERS}#loglevel=4#" /etc/default/grub
		return 1 # with error status
	fi

	return 0
}



# ******************************************************************************* 
# This function will be executed in the background context, to watch the TUI installer. 
function grub_check_and_modify_local() {

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

} # grub_check_and_modify_local()

# ******************************************************************************* 
# Execute
main