#!/bin/bash -u
# ******************************************************************************* 
#                        Confirmation and Passphrase setting 
# ******************************************************************************* 

function confirmation(){

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


# ******************************************************************************* 
#                                Pre-install stage 
# ******************************************************************************* 

function pre_install() {


	# ----- Erase entire disk, create partitions, format them  and encrypt the LUKS partition -----
	if [ "${ERASEALL}" -ne 0 ] ; then

		# Assign specified space and rest of disk to the EFI and LUKS partition, respectively.
		if [  "${ISEFI}" -ne 0 ] ; then # EFI
			# Zap existing partition table and create new GPT
			echo "...Initializing \"${DEV}\" with GPT."
			sgdisk --zap-all "${DEV}"
			# Create EFI partition and format it
			echo "...Creating an EFI partition on \"${DEV}\"."
			# shellcheck disable=SC2140
			sgdisk --new="${EFIPARTITION}":0:+"${EFISIZE}" --change-name="${EFIPARTITION}":"EFI System"  --typecode="${EFIPARTITION}":ef00 "${DEV}"  
			echo "...Formatting the EFI parttion."
			mkfs.vfat -F 32 -n EFI-SP "${DEV}${EFIPARTITION}"
			# Create Linux partition
			echo "...Creating a Linux partition on ${DEV}."
			# shellcheck disable=SC2140
			sgdisk --new="${CRYPTPARTITION}":0:0    --change-name="${CRYPTPARTITION}":"Linux LUKS" --typecode="${CRYPTPARTITION}":8309 "${DEV}"
			# Then print them
			sgdisk --print "${DEV}"
		else # BIOS
			# Zap existing partition table
			echo "...Erasing partition table of \"${DEV}\"."
			dd if=/dev/zero of="${DEV}" bs=512 count=1
			# Create MBR and allocate max storage for Linux partition
			echo "...Creating a Linux partition on ${DEV} with MBR."
			sfdisk "${DEV}" <<- HEREDOC
			2M,,L
			HEREDOC
		fi	# if EFI firmware

		# Encrypt the partition to install Linux
		echo "...Initializing \"${DEV}${CRYPTPARTITION}\" as crypt partition"
		printf %s "${PASSPHRASE}" | cryptsetup luksFormat --type=luks1 --key-file - --batch-mode "${DEV}${CRYPTPARTITION}"

	fi	# if erase all

	# ----- Open the LUKS partition -----
	# Open the crypt partition. 
	echo "...Opening a crypt partition \"${DEV}${CRYPTPARTITION}\" as \"${CRYPTPARTNAME}\""
	printf %s "${PASSPHRASE}" | cryptsetup open -d - "${DEV}${CRYPTPARTITION}" "${CRYPTPARTNAME}"

	# Check whether successful open. If mapped, it is successful. 
	if [ ! -e /dev/mapper/"${CRYPTPARTNAME}" ] ; then 
		cat <<- HEREDOC 
		***** ERROR : Cannot open LUKS volume "${CRYPTPARTNAME}" on "${DEV}${CRYPTPARTITION}". *****
		...Check passphrase and your config.txt

		...Installation process terminated..
		HEREDOC
		return 1 # with error status
	fi	# if crypt volume is unable to open

	# ----- Configure the LVM in LUKS volume -----
	# Check volume group ${VGNAME} exist or not
	if  vgdisplay -s "${VGNAME}" &> /dev/null ; then		# if exist
		echo "...Volume group \"${VGNAME}\" already exist. Skipped to create. No problem."
		echo "...Activating all logical volumes in volume group \"${VGNAME}\"."
		vgchange -ay
	else
		echo "...Initializing a physical volume on \"${CRYPTPARTNAME}\""
		pvcreate /dev/mapper/"${CRYPTPARTNAME}"
		echo "...And then creating Volume group \"${VGNAME}\"."
		vgcreate "${VGNAME}" /dev/mapper/"${CRYPTPARTNAME}"
	fi # if /dev/volume-groupt exist

	# Create a SWAP Logical Volume on VG, if it doesn't exist
	if [ -e /dev/mapper/"${VGNAME}"-"${LVSWAPNAME}" ] ; then 
		echo "...Swap volume already exist. Skipped to create. No problem."
	else
		echo "...Creating logical volume \"${LVSWAPNAME}\" on \"${VGNAME}\"."
		lvcreate -L "${LVSWAPSIZE}" -n "${LVSWAPNAME}" "${VGNAME}" 
	fi	# if /dev/mapper/swap volume already exit. 

	# Create a ROOT Logical Volume on VG. 
	if [ -e /dev/mapper/"${VGNAME}"-"${LVROOTNAME}" ] ; then # exist
		if [ "${OVERWRITEINSTALL}" -ne 0 ] ; then # exist and overwrite install
			echo "...Logical volume \"${VGNAME}-${LVROOTNAME}\" already exists. OK."
		else	# exist and not overwriteinstall
			cat <<- HEREDOC 
			***** ERROR : Logical volume "${VGNAME}-${LVROOTNAME}" already exists. *****
			...Check LVROOTNAME environment variable in your config.txt.
			HEREDOC
			# Deactivate all lg and close the LUKS volume
			deactivate_and_close
			return 1 # with error status
		fi
	else	# not exsit
		if [ "${OVERWRITEINSTALL}" -ne 0 ] ; then
			cat <<- HEREDOC 
			***** ERROR : Logical volume "${VGNAME}-${LVROOTNAME}" doesn't exist while overwrite install. *****
			...Check consistency of your config.txt.
			HEREDOC
			# Deactivate all lg and close the LUKS volume
			deactivate_and_close
			return 1 # with error status
		else # not exist and not overwrite install
			echo "...Creating logical volume \"${LVROOTNAME}\" on \"${VGNAME}\"."
			lvcreate -l "${LVROOTSIZE}" -n "${LVROOTNAME}" "${VGNAME}"
		fi
	fi


	# successful return
	return 0
}


# ******************************************************************************* 
#                  Common message in para-install stage
# ******************************************************************************* 

function para_install_msg() {

	cat <<- HEREDOC
	******************************************************************************
	The pre-install process is done. We are ready to install the Linux to the 
	target storage device. By pressing return key, GUI/TUI installer starts.

	Please pay attention to the partition/logical volume mapping configuration. 
	In this installation, you have to map the previously created partitions/logical
	volumes to the appropriate directories of the target system as followings :

	HEREDOC

	# In the EFI system, add this mapping
	if [  "${ISEFI}" -ne 0 ] ; then
		echo "/boot/efi        : ${DEV}${EFIPARTITION}"
	fi

	# Root volume mapping
	echo "/                : /dev/mapper/${VGNAME}-${LVROOTNAME}"

	# In case of erased storage, add this mapping
	if [ "${ERASEALL}" -ne 0 ] ; then
		echo "swap             : /dev/mapper/${VGNAME}-${LVSWAPNAME}"
	fi

	return 0
}

# ******************************************************************************* 
#              Deactivate all LV in the VG and close LUKS volume
# ******************************************************************************* 

function deactivate_and_close(){
	echo "...Deactivate all logical volumes in volume group \"${VGNAME}\"."
	vgchange -a n "${VGNAME}"
	echo "...Closing LUKS volume \"${CRYPTPARTNAME}\"."
	cryptsetup close  "${CRYPTPARTNAME}"
	cat <<- HEREDOC 

	...Installation process terminated..
	HEREDOC

}

# ******************************************************************************* 
#              Delete the nwe volume if overwrite install, and close all
# ******************************************************************************* 
function on_unexpected_installer_quit(){
	echo "***** ERROR : The GUI/TUI installer terminated unexpectedly. *****" 
	if [ "${OVERWRITEINSTALL}" -eq 0 ] ; then	# If not over install, volume is new. So delete it
		echo "...Deleting the new logical volume \"${VGNAME}-${LVROOTNAME}\"."
		lvremove -f /dev/mapper/"${VGNAME}"-"${LVROOTNAME}" 
	fi
	# Deactivate all lg and close the LUKS volume
	deactivate_and_close
	echo "...The new logical volume has been deleted. You can retry Kaiten-yaki again." 
}


# ******************************************************************************* 
#              Check whether given signaure is in the system information
# ******************************************************************************* 
function distribution_check(){
	if ! uname -a | grep "${DISTRIBUTIONSIGNATURE}" -i > /dev/null  ; then	#  Signature is not found in the OS name.
		echo "*******************************************************************************"
		uname -a
		cat <<- HEREDOC 
		*******************************************************************************
		This system seems to be not $DISTRIBUTIONNAME, while this script is dediated to the $DISTRIBUTIONNAME.
		Are you sure you want to run this script? [Y/N]
		HEREDOC
		read -r YESNO
		if [ "${YESNO}" != "Y" ] && [ "${YESNO}" != "y" ] ; then
			cat <<- HEREDOC 

			...Installation process terminated..
			HEREDOC
			return 1 # with error status
		fi	# if YES

	fi # Distribution check

	# no error
	return 0
}