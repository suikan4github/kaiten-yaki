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
			The installer terminated unexpectedly. 

			Installation process terminated.
			HEREDOC
			return 1
		fi
	done # while

	# Perhaps, too neuvous. Wait 1 more sectond to avoid the rece condition.
	sleep 1 # 1sec.

	# Make target GRUB aware to the crypt partition
	# This must do it after start of the file copy by installer, but before the end of the file copy.
	# If the environment is not GUI, keep quiet not to bother the TUI installer. 
	if [ ${PARAINSTMSG} -eq 1 ]; then
		echo "...Add GRUB_ENABLE_CRYPTODISK entry to ${TARGETMOUNTPOINT}/etc/default/grub "
	fi
	echo "GRUB_ENABLE_CRYPTODISK=y" >> ${TARGETMOUNTPOINT}/etc/default/grub


	# And then, wait for the end of installer process
	# If the environment is not GUI, keep quiet not to bother the TUI installer. 
	if [ ${PARAINSTMSG} -eq 1 ]; then
		echo "...Waiting for the end of GUI/TUI installer."
	fi
	wait $installer_pid

	# succesfull return
	return 0

} # para install
