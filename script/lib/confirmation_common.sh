#!/bin/bash -u
# ******************************************************************************* 
#                        Confirmation and Passphrase setting 
# ******************************************************************************* 

function confirmation_common(){

	# Consistency check for the OVERWRITEINSTALL and ERASEALL
	if [ "${ERASEALL}" -ne 0 ] && [ "${OVERWRITEINSTALL}" -ne 0 ] ; then 
		cat <<- HEREDOC 
		***** ERROR : Confliction between ERASEALL and OVERWRITEINSTALL *****
		...ERASEALL = ${ERASEALL}
		...OVERWRITEINSTALL = ${OVERWRITEINSTALL}
		...Check configuration in your config.sh

		...Installation process terminated..
		HEREDOC
		return 1 # with error status
	fi

	# Sanity check for volume group name
	if echo "${VGNAME}" | grep "-" -i > /dev/null ; then	# "-" is found in the volume group name.
		cat <<- HEREDOC 
		***** ERROR : VGNAME is "${VGNAME}" *****
		..."-" is not allowed in the volume name. 
		...Check configuration in your config.sh

		...Installation process terminated..
		HEREDOC
		return 1 # with error status
	fi # "-" is found in the volume group name.

	# Sanity check for root volume name
	if echo "${LVROOTNAME}" | grep "-" -i > /dev/null ; then	# "-" is found in the volume name.
		cat <<- HEREDOC 
		***** ERROR : LVROOTNAME is "${LVROOTNAME}" *****
		..."-" is not allowed in the volume name. 
		...Check configuration in your config.sh

		...Installation process terminated..
		HEREDOC
		return 1 # with error status
	fi # "-" is found in the volume name.

	# Sanity check for swap volume name
	if echo "${LVSWAPNAME}" | grep "-" -i > /dev/null ; then	# "-" is found in the volume name.
		cat <<- HEREDOC 
		***** ERROR : LVSWAPNAME is "${LVSWAPNAME}" *****
		..."-" is not allowed in the volume name. 
		...Check configuration in your config.sh

		...Installation process terminated..
		HEREDOC
		return 1 # with error status
	fi # "-" is found in the volume name.

	# For surre ask the your config.sh is edited
	cat <<- HEREDOC

	The destination logical volume label is "${LVROOTNAME}"
	"${LVROOTNAME}" uses ${LVROOTSIZE} of the LVM volume group.
	Are you sure to install? [Y/N]
	HEREDOC
	read -r YESNO
	if [ "${YESNO}" != "Y" ] && [ "${YESNO}" != "y" ] ; then
		cat <<- HEREDOC 

		...Installation process terminated..
		HEREDOC
		return 1 # with error status
	fi	# if YES

	# For sure ask to be sure to erase. 
	if [ "${ERASEALL}" -ne 0 ] ; then
		echo "Are you sure you want to erase entire ${DEV}? [Y/N]"
		read -r YESNO
		if [ "${YESNO}" != "Y" ] && [ "${YESNO}" != "y" ] ; then
			cat <<-HEREDOC 
		...Check your config.sh. The variable ERASEALL is ${ERASEALL}.

		...Installation process terminated..
		HEREDOC
		return 1 # with error status
		fi	# if YES
	fi	# if erase all

	# ----- Set Passphrase -----
	# Input passphrase
	echo ""
	echo "Type passphrase for the disk encryption."
	read -sr PASSPHRASE
	export PASSPHRASE

	echo "Type passphrase again, to confirm."
	read -sr PASSPHRASE_C

	# Validate whether both are indentical or not
	if [ "${PASSPHRASE}" != "${PASSPHRASE_C}" ] ; then
		cat <<-HEREDOC 
		***** ERROR : Passphrase doesn't match *****

		...Installation process terminated..
		HEREDOC
		return 1 # with error status
	fi	# passphrase validation

	# succesfull return
	return 0
}
