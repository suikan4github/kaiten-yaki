#!/bin/bash -u
# ******************************************************************************* 
#                                Pre-install stage 
# ******************************************************************************* 

function pre_install() {


	# ----- Erase entire disk, create partitions, format them  and encrypt the LUKS partition -----
	if [ ${ERASEALL} -eq 1 ] ; then

		# Assign specified space and rest of disk to the EFI and LUKS partition, respectively.
		if [  ${ISEFI} -eq 1 ] ; then
			# Zap existing partition table and create new GPT
			echo "...Initializing ${DEV} with GPT."
			sgdisk --zap-all "${DEV}"
			# Create EFI partition and format it
			echo "...Creating an EFI partition on ${DEV}."
			sgdisk --new=${EFIPARTITION}:0:+${EFISIZE} --change-name=${EFIPARTITION}:"EFI System"  --typecode=${EFIPARTITION}:ef00 "${DEV}"  
			echo "...Formatting the EFI parttion."
			mkfs.vfat -F 32 -n EFI-SP "${DEV}${EFIPARTITION}"
			# Create Linux partition
			echo "...Creating a Linux partition on ${DEV}."
			sgdisk --new=${CRYPTPARTITION}:0:0    --change-name=${CRYPTPARTITION}:"Linux LUKS" --typecode=${CRYPTPARTITION}:8309 "${DEV}"
			# Then print them
			sgdisk --print "${DEV}"
		else
			# Zap existing partition table
			echo "...Erasing partition table of ${DEV}."
			dd if=/dev/zero of=${DEV} bs=512 count=1
			# Create MBR and allocate max storage for Linux partition
			echo "...Creating a Linux partition on ${DEV} with MBR."
			sfdisk ${DEV} <<- HEREDOC
			2M,,L
			HEREDOC
		fi	# if EFI firmware

		# Encrypt the partition to install Linux
		echo "...Initializing ${DEV}${CRYPTPARTITION} as crypt partition"
		printf %s "${PASSPHRASE}" | cryptsetup luksFormat --type=luks1 --key-file - --batch-mode "${DEV}${CRYPTPARTITION}"

	fi	# if erase all

	# ----- Open the LUKS partition -----
	# Open the crypt partition. 
	echo "...Opening a crypt partition ${DEV}${CRYPTPARTITION} as \"${CRYPTPARTNAME}\""
	printf %s "${PASSPHRASE}" | cryptsetup open -d - "${DEV}${CRYPTPARTITION}" ${CRYPTPARTNAME}

	# Check whether successful open. If mapped, it is successful. 
	if [ ! -e /dev/mapper/${CRYPTPARTNAME} ] ; then 
		cat <<- HEREDOC 1>&2
		***** ERROR : Cannot open LUKS volume "${CRYPTPARTNAME}" on ${DEV}${CRYPTPARTITION}. *****
		...Check passphrase and your config.txt

		...Installation process terminated..
		HEREDOC
		return 1 # with error status
	fi	# if crypt volume is unable to open

	# ----- Configure the LVM in LUKS volume -----
	# Check volume group ${VGNAME} exist or not
	if  vgdisplay -s ${VGNAME} &> /dev/null ; then		# if exist
		echo "...Volume group ${VGNAME} already exist. Skipped to create. No problem."
		echo "...Activating all logical volumes in volume group \"${VGNAME}\"."
		vgchange -ay
	else
		echo "...Initializing a physical volume on \"${CRYPTPARTNAME}\""
		pvcreate /dev/mapper/${CRYPTPARTNAME}
		echo "...And then creating Volume group \"${VGNAME}\"."
		vgcreate ${VGNAME} /dev/mapper/${CRYPTPARTNAME}
	fi # if /dev/volume-groupt exist

	# Create a SWAP Logical Volume on VG, if it doesn't exist
	if [ -e /dev/mapper/${VGNAME}-${LVSWAPNAME} ] ; then 
		echo "...Swap volume already exist. Skipped to create. No problem."
	else
		echo "...Creating logical volume \"${LVSWAPNAME}\" on \"${VGNAME}\"."
		lvcreate -L ${LVSWAPSIZE} -n ${LVSWAPNAME} ${VGNAME} 
	fi	# if /dev/mapper/swap volume already exit. 

	# Create a ROOT Logical Volume on VG. 
	if [ -e /dev/mapper/${VGNAME}-${LVROOTNAME} ] ; then # exist
		if [ ${OVERWRITEINSTALL} -eq 1 ] ; then # exist and overwrite install
			echo "...Logical volume "${VGNAME}-${LVROOTNAME}" already exists. OK."
		else	# exist and not overwriteinstall
			cat <<- HEREDOC 1>&2
			***** ERROR : Logical volume "${VGNAME}-${LVROOTNAME}" already exists. *****
			...Check LVROOTNAME environment variable in your config.txt.
			HEREDOC
			echo "...Deactivating all logical volumes in volume group \"${VGNAME}\"."
			vgchange -a n ${VGNAME}
			echo "...Closing LUKS volume \"${CRYPTPARTNAME}\"."
			cryptsetup close  ${CRYPTPARTNAME}
			cat <<- HEREDOC 1>&2

			...Installation process terminated..
			HEREDOC
			return 1 # with error status
		fi
	else	# not exsit
		if [ ${OVERWRITEINSTALL} -eq 1 ] ; then
			cat <<- HEREDOC 1>&2
			***** ERROR : Logical volume "${VGNAME}-${LVROOTNAME}" doesn't exist while overwrite install. *****
			...Check consistency of your config.txt.
			HEREDOC
			echo "...Deactivate all logical volumes in volume group \"${VGNAME}\"."
			vgchange -a n ${VGNAME}
			echo "...Closing LUKS volume \"${CRYPTPARTNAME}\"."
			cryptsetup close  ${CRYPTPARTNAME}
			cat <<- HEREDOC 1>&2

			...Installation process terminated..
			HEREDOC
			return 1 # with error status
		else # not exist and not overwrite install
			echo "...Creating logical volume \"${LVROOTNAME}\" on \"${VGNAME}\"."
			lvcreate -l ${LVROOTSIZE} -n ${LVROOTNAME} ${VGNAME}
		fi
	fi


	# successful return
	return 0
}
