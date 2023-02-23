#!/bin/bash -u

	# shellcheck disable=SC1091
	# Load configuration parameter
	source ./config.sh

	# Load common functions
	source ./lib/common.sh

function main() {

	# This is the mount point of the install target. 
	export TARGETMOUNTPOINT="/target"

	# ******************************************************************************* 
	#                                Confirmation before installation 
	# ******************************************************************************* 

	# parameters for distribution check
	export DISTRIBUTIONSIGNATURE="ubuntu"
	export DISTRIBUTIONNAME="Ubuntu"

	# Check whether given signature exist or not
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

	# Common part of the pre-install stage
	if ! pre_install ; then
		return 1 # with error status
	fi


	# ******************************************************************************* 
	#                                Para-install stage 
	# ******************************************************************************* 

	# Start the GUI installer and modify the target /etc/default/grub in parallel
	if ! para_install_local ; then
		return 1 # with error status
	fi

	# ******************************************************************************* 
	#                                Post-install stage 
	# ******************************************************************************* 

	# If the target volume is formated by btrfs, Ubiquity install the root into the
	# @ sub-volume. Thus, mount command inside post_install have to use special option
	# to specify @ as mount target. 
	if lsblk -o NAME,FSTYPE | grep -i "${VGNAME}-${LVROOTNAME}" | grep -i "btrfs" > /dev/null ; then 
		export BTRFSOPTION="-o subvol=@"
	else
		export BTRFSOPTION=""
	fi

	# Distribution dependent finalizing. Embed encryption key into the ramfs image.
	# The script is parameterized by env-variable to fit to the distribution 
	post_install

	# Normal end
	return 0

}	# End of main()


# ******************************************************************************* 
# Ubuntu dependent para-installation process
function para_install_local() {
	# Show common message to let the operator focus on the critical part
	para_install_msg

	# Distribution dependent message
	cat <<- HEREDOC

	**************** CAUTION! CAUTION! CAUTION! ********************
	[Kaiten-Yaki] 
	[Kaiten-Yaki] Make sure to click "Continue Testing",  at the end of  
	[Kaiten-Yaki] the Ubiquity installer. Just exit the installer without  
	[Kaiten-Yaki] rebooting. Otherwise, your system becomes unable to boot. 
	[Kaiten-Yaki] 
	[Kaiten-Yaki] Type return key to start Ubiquity.
	HEREDOC

	# Waiting for a console input
	read -r

	# Start Ubiquity installer 
	ubiquity &

	# Record the PID of the installer. 
	export INSTALLER_PID=$!


	# Record the install PID, modify the /etc/default/grub of the target, 
	# and then, wait for the end of the intaller. 
	if ! grub_check_and_modify_local ; then
		return 1 # with error status
	fi

	return 0
}



# ******************************************************************************* 
# This function will be executed in the foreground context, to watch the GUI installer. 
function grub_check_and_modify_local() {

	# While the /etc/default/grub in the install target is NOT existing, keep sleeping.
	# If installer terminated without file copy, this script also terminates.
	while [ ! -e ${TARGETMOUNTPOINT}/etc/default/grub ]
	do
		sleep 1 # 1sec.

		# Check if installer quit unexpectedly
		if ! ps $INSTALLER_PID  > /dev/null ; then	# If not exists
			# Delete the new volume if overwrite install, and close all
			on_unexpected_installer_quit
			return 1 # with error status
		fi
	done # while

	# Perhaps, too nervous. Wait 1 more second to avoid the rece condition.
	sleep 1 # 1sec.

	# Make target GRUB aware of the crypt partition
	# This must do it after start of the file copy by installer, but before the end of the file copy.
	echo "[Kaiten-Yaki] Adding GRUB_ENABLE_CRYPTODISK entry to ${TARGETMOUNTPOINT}/etc/default/grub "
	echo "GRUB_ENABLE_CRYPTODISK=y" >> ${TARGETMOUNTPOINT}/etc/default/grub

	# And then, wait for the end of installer process
	echo "[Kaiten-Yaki] Waiting for the end of GUI/TUI installer."
	echo "[Kaiten-Yaki] Again, DO NOT reboot/restart here. Just exit the GUI/TUI installer."
	wait $INSTALLER_PID

	# succesfull return
	return 0

} # grub_check_and_modify_local()

# ******************************************************************************* 
# Execute
main
