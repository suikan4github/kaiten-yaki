#!/bin/bash -u

	# shellcheck disable=SC1091
	# Load configuration parameter
	source ./config01.sh

# ******************************************************************************* 
#              Deactivate all LV in the VG and close LUKS volume
# ******************************************************************************* 

function util_deactivate_and_close(){
	echo "...Deactivating all logical volumes in volume group \"${VGNAME}\"."
	vgchange -a n "${VGNAME}"
	echo "...Closing LUKS volume \"${CRYPTPARTNAME}\"."
	cryptsetup close  "${CRYPTPARTNAME}"
	cat <<- HEREDOC 

	...Installation process terminated..
	HEREDOC

}

util_deactivate_and_close
