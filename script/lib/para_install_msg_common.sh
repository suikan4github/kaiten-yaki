#!/bin/bash -u

function para_install_msg_common() {

	cat <<- HEREDOC
	******************************************************************************
	The pre-install process is done. We are ready to install the Linux to the 
	target storage device. By pressing return key, GUI/TUI installer starts.

	Please pay attention to the partition/logical volume mapping configuration. 
	In this installation, you have to map the previously created partitions/logical
	volumes to the appropriate directories of the target system as followings :

	HEREDOC

	# In the EFI system, add this mapping
	if [  "${ISEFI}" -eq 1 ] ; then
		echo "/boot/efi        : ${DEV}${EFIPARTITION}"
	fi

	# Root volume mapping
	echo "/                : /dev/mapper/${VGNAME}-${LVROOTNAME}"

	# In case of erased storage, add this mapping
	if [ "${ERASEALL}" -eq 1 ] ; then
		echo "swap             : /dev/mapper/${VGNAME}-${LVSWAPNAME}"
	fi

	return 0
}