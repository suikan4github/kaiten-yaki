#!/bin/bash -u
# ******************************************************************************* 
#                        Common part of para-install 
# ******************************************************************************* 

function parainstall() {

	# While the /etc/default/grub in the install target is NOT existing, keep sleeping.
	# If installer terminated without file copy, this script also terminates.
	while [ ! -e ${TARGETMOUNTPOINT}/etc/default/grub ]
	do
		sleep 1 # 1sec.

		# Check if installer still exist
		if ! ps $INSTALLER_PID  > /dev/null ; then	# If not exists
			cat <<-HEREDOC 1>&2
			***** ERROR : The GUI/TUI installer terminated unexpectedly. ***** 
			...Delete the new logical volume "${VGNAME}-${LVROOTNAME}".
			HEREDOC
			lvremove -f /dev/mapper/${VGNAME}-${LVROOTNAME} 
			echo "...Deactivate all logical volumes in volume group \"${VGNAME}\"."
			vgchange -a n ${VGNAME}
			echo "...Close LUKS volume \"${CRYPTPARTNAME}\"."
			cryptsetup close  ${CRYPTPARTNAME}
			cat <<-HEREDOC 1>&2

			...The new logical volume is deleted. You can start Kaiten-yaki again. 
			...Installation process terminated.
			HEREDOC
			return 1 # with error status
		fi
	done # while

	# Perhaps, too neuvous. Wait 1 more sectond to avoid the rece condition.
	sleep 1 # 1sec.

	# Make target GRUB aware to the crypt partition
	# This must do it after start of the file copy by installer, but before the end of the file copy.
	echo "...Add GRUB_ENABLE_CRYPTODISK entry to ${TARGETMOUNTPOINT}/etc/default/grub "
	echo "GRUB_ENABLE_CRYPTODISK=y" >> ${TARGETMOUNTPOINT}/etc/default/grub

	# And then, wait for the end of installer process
	echo "...Waiting for the end of GUI/TUI installer."
	echo "...Again, DO NOT reboot/restart here. Just exit the GUI/TUI installer."
	wait $INSTALLER_PID

	# succesfull return
	return 0

} # para install
