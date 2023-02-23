#!/bin/bash -u
# ******************************************************************************* 
#                        Confirmation and Passphrase setting 
# ******************************************************************************* 

function confirmation(){

	# Consistency check for the OVERWRITEINSTALL and ERASEALL
	if [ "${ERASEALL}" -ne 0 ] && [ "${OVERWRITEINSTALL}" -ne 0 ] ; then 
		cat <<- HEREDOC 
		***** ERROR : Confliction between ERASEALL and OVERWRITEINSTALL *****
		[Kaiten-Yaki] ERASEALL = ${ERASEALL}
		[Kaiten-Yaki] OVERWRITEINSTALL = ${OVERWRITEINSTALL}
		[Kaiten-Yaki] Check configuration in your config.sh

		[Kaiten-Yaki] Installation process terminated..
		HEREDOC
		return 1 # with error status
	fi

	# Sanity check for volume group name
	if echo "${VGNAME}" | grep "-" -i > /dev/null ; then	# "-" is found in the volume group name.
		cat <<- HEREDOC 
		***** ERROR : VGNAME is "${VGNAME}" *****
		[Kaiten-Yaki] "-" is not allowed in the volume name. 
		[Kaiten-Yaki] Check configuration in your config.sh

		[Kaiten-Yaki] Installation process terminated..
		HEREDOC
		return 1 # with error status
	fi # "-" is found in the volume group name.

	# Sanity check for root volume name
	if echo "${LVROOTNAME}" | grep "-" -i > /dev/null ; then	# "-" is found in the volume name.
		cat <<- HEREDOC 
		***** ERROR : LVROOTNAME is "${LVROOTNAME}" *****
		[Kaiten-Yaki] "-" is not allowed in the volume name. 
		[Kaiten-Yaki] Check configuration in your config.sh

		[Kaiten-Yaki] Installation process terminated..
		HEREDOC
		return 1 # with error status
	fi # "-" is found in the volume name.

	# Sanity check for lvext1 volume suffix
	if [ "${USELVEXT1}" -ne 0 ] ; then
		if echo "${LVEXT1SUFFIX}" | grep "-" -i > /dev/null ; then	# "-" is found in the volume name.
			cat <<- HEREDOC 
			***** ERROR : LVEXT1SUFFIX is "${LVEXT1SUFFIX}" *****
			[Kaiten-Yaki] "-" is not allowed in the volume name. 
			[Kaiten-Yaki] Check configuration in your config.sh

			[Kaiten-Yaki] Installation process terminated..
			HEREDOC
			return 1 # with error status
		fi # "-" is found in the volume suffix.
	fi # USELVEXT1

	# Sanity check for lvext2 volume suffix
	if [ "${USELVEXT2}" -ne 0 ] ; then
		if echo "${LVEXT2SUFFIX}" | grep "-" -i > /dev/null ; then	# "-" is found in the volume name.
			cat <<- HEREDOC 
			***** ERROR : LVEXT2SUFFIX is "${LVEXT2SUFFIX}" *****
			[Kaiten-Yaki] "-" is not allowed in the volume name. 
			[Kaiten-Yaki] Check configuration in your config.sh

			[Kaiten-Yaki] Installation process terminated..
			HEREDOC
			return 1 # with error status
		fi # "-" is found in the volume suffix.
	fi # USELVEXT2

	# Sanity check for swap volume name
	if echo "${LVSWAPNAME}" | grep "-" -i > /dev/null ; then	# "-" is found in the volume name.
		cat <<- HEREDOC 
		***** ERROR : LVSWAPNAME is "${LVSWAPNAME}" *****
		[Kaiten-Yaki] "-" is not allowed in the volume name. 
		[Kaiten-Yaki] Check configuration in your config.sh

		[Kaiten-Yaki] Installation process terminated..
		HEREDOC
		return 1 # with error status
	fi # "-" is found in the volume name.

	# Make sure config.sh is edited
	cat <<- HEREDOC

	LUKS volume partition : ${DEV}${CRYPTPARTITION} 
	LUKS volume name      : "${CRYPTPARTNAME}" 
	Volume group name     : "${VGNAME}"
	Root volume name      : "${VGNAME}-${LVROOTNAME}"
	Root volume size      : "${LVROOTSIZE}"
	HEREDOC

	if [ "${USELVEXT1}" -ne 0 ] ; then
		cat <<- HEREDOC
		Extra volume name 1   : "${VGNAME}-${LVROOTNAME}${LVEXT1SUFFIX}"
		Extra volume size 1   : "${LVEXT1SIZE}"
		HEREDOC
	fi	# USELVEXT1

	if [ "${USELVEXT2}" -ne 0 ] ; then
		cat <<- HEREDOC
		Extra volume name 2   : "${VGNAME}-${LVROOTNAME}${LVEXT2SUFFIX}"
		Extra volume size 2   : "${LVEXT2SIZE}"
		HEREDOC
	fi	# USELVEXT2

	cat <<- HEREDOC
	Swap volume name      : "${VGNAME}-${LVSWAPNAME}"
	Swap volume size      : "${LVSWAPSIZE}"
	--iter-time parameter : ${ITERTIME}
	HEREDOC

	if [ "${ERASEALL}" -ne 0 ] ; then
		echo "[Kaiten-Yaki] Going to erase entire disk ${DEV}."
	elif [ "${OVERWRITEINSTALL}" -ne 0 ] ; then
		echo "[Kaiten-Yaki] Going to overwrite the logical volume \"${VGNAME}-${LVROOTNAME}\"."
	else
		echo "[Kaiten-Yaki] Going to create a new logical volume \"${VGNAME}-${LVROOTNAME}\"."
	fi


	# ----- Set Passphrase -----
	# Input passphrase
	echo ""
	echo "[Kaiten-Yaki] Type passphrase for the disk encryption."
	read -sr PASSPHRASE
	export PASSPHRASE

	echo "[Kaiten-Yaki] Type passphrase again, to confirm."
	read -sr PASSPHRASE_C

	# Validate whether both are indentical or not
	if [ "${PASSPHRASE}" != "${PASSPHRASE_C}" ] ; then
		cat <<-HEREDOC 
		***** ERROR : Passphrase doesn't match *****

		[Kaiten-Yaki] Installation process terminated..
		HEREDOC
		return 1 # with error status
	else
		# Clear the PASSPHRASE for checking because we don't use it anymore. 
		PASSPHRASE_C=""
	fi	# passphrase validation

	
	# Add -l or -L parameter to the size. The lvcreate command have two size parameter. 
	# -l ###%[FREE|VG|PVS|ORIGIN] : Size by relative value. 
	# -L ###[M|G|T|m|g|t] : Size by absolute value. 
	# Too preven the duplicated match, awk exists the process after it match the /%/ pattern. 
	# If the unit is not specified, installation will fail. 

	LVSWAPSIZE=$(echo "${LVSWAPSIZE}" | awk '/%/{print "-l", $0; exit} /M|G|T|m|g|t/{print "-L", $0}')
	export LVSWAPSIZE	
	
	LVROOTSIZE=$(echo "${LVROOTSIZE}" | awk '/%/{print "-l", $0; exit} /M|G|T|m|g|t/{print "-L", $0}')
	export LVROOTSIZE

	LVEXT1SIZE=$(echo "${LVEXT1SIZE}" | awk '/%/{print "-l", $0; exit} /M|G|T|m|g|t/{print "-L", $0}')
	export LVEXT1SIZE

	LVEXT2SIZE=$(echo "${LVEXT2SIZE}" | awk '/%/{print "-l", $0; exit} /M|G|T|m|g|t/{print "-L", $0}')
	export LVEXT2SIZE

	# succesfull return
	return 0
}


# ******************************************************************************* 
#                           Common Pre-install stage 
# ******************************************************************************* 

function pre_install() {

	# Internal variables.
	# These variables displays whether the volumes are created in this installation. 
	IS_ROOT_CREATED=0
	IS_LVEXT1_CREATED=0
	IS_LVEXT2_CREATED=0

	# ----- Erase entire disk, create partitions, format them and encrypt the LUKS partition -----
	if [ "${ERASEALL}" -ne 0 ] ; then

		# Assign specified space and rest of disk to the EFI and LUKS partition, respectively.
		if [  "${ISEFI}" -ne 0 ] ; then # EFI
			# Zap existing partition table and create new GPT
			echo "[Kaiten-Yaki] Initializing \"${DEV}\" with GPT."
			sgdisk --zap-all "${DEV}"
			if is_error ; then return 1 ; fi; 	# If error, terminate
			# Create EFI partition and format it
			echo "[Kaiten-Yaki] Creating an EFI partition on \"${DEV}\"."
			# shellcheck disable=SC2140
			sgdisk --new="${EFIPARTITION}":0:+"${EFISIZE}" --change-name="${EFIPARTITION}":"EFI System"  --typecode="${EFIPARTITION}":ef00 "${DEV}"  
			if is_error ; then return 1 ; fi; 	# If error, terminate
			echo "[Kaiten-Yaki] Formatting the EFI parttion."
			mkfs.vfat -F 32 -n EFI-SP "${DEV}${EFIPARTITION}"
			if is_error ; then return 1 ; fi; 	# If error, terminate
			# Create Linux partition
			echo "[Kaiten-Yaki] Creating a Linux partition on ${DEV}."
			# shellcheck disable=SC2140
			sgdisk --new="${CRYPTPARTITION}":0:0    --change-name="${CRYPTPARTITION}":"Linux LUKS" --typecode="${CRYPTPARTITION}":8309 "${DEV}"
			if is_error ; then return 1 ; fi; 	# If error, terminate
			# Then print them
			sgdisk --print "${DEV}"
		else # BIOS
			# Zap existing partition table
			echo "[Kaiten-Yaki] Erasing partition table of \"${DEV}\"."
			dd if=/dev/zero of="${DEV}" bs=512 count=1
			if is_error ; then return 1 ; fi; 	# If error, terminate
			# Create MBR and allocate max storage for Linux partition
			echo "[Kaiten-Yaki] Creating a Linux partition on ${DEV} with MBR."
			sfdisk "${DEV}" <<- HEREDOC
			2M,,L
			HEREDOC
			if is_error ; then return 1 ; fi; 	# If error, terminate
		fi	# if EFI firmware

		# Encrypt the partition to install Linux
		echo "[Kaiten-Yaki] Initializing \"${DEV}${CRYPTPARTITION}\" as crypt partition"
		printf %s "${PASSPHRASE}" | cryptsetup luksFormat --iter-time "${ITERTIME}" --type=luks1 --key-file - --batch-mode "${DEV}${CRYPTPARTITION}"

	fi	# if erase all

	# ----- Open the LUKS partition -----
	# Open the crypt partition. 
	echo "[Kaiten-Yaki] Opening a crypt partition \"${DEV}${CRYPTPARTITION}\" as \"${CRYPTPARTNAME}\""
	printf %s "${PASSPHRASE}" | cryptsetup open -d - "${DEV}${CRYPTPARTITION}" "${CRYPTPARTNAME}"

	# Check whether it successfully opens. If mapped, it is successful. 
	if [ ! -e /dev/mapper/"${CRYPTPARTNAME}" ] ; then 
		cat <<- HEREDOC 
		***** ERROR : Cannot open LUKS volume "${CRYPTPARTNAME}" on "${DEV}${CRYPTPARTITION}". *****
		[Kaiten-Yaki] Check passphrase and your config.txt

		[Kaiten-Yaki] Installation process terminated..
		HEREDOC
		return 1 # with error status
	fi	# if crypt volume is unable to open

	# ----- Configure the LVM in LUKS volume -----
	# Check if volume group ${VGNAME} exist or not
	if  vgdisplay -s "${VGNAME}" &> /dev/null ; then		# if exist
		echo "[Kaiten-Yaki] Volume group \"${VGNAME}\" already exist. Skipped to create. No problem."
		echo "[Kaiten-Yaki] Activating all logical volumes in volume group \"${VGNAME}\"."
		vgchange -ay
		echo "[Kaiten-Yaki] Scanning all logical volumes."
		lvscan
	else
		echo "[Kaiten-Yaki] Initializing a physical volume on \"${CRYPTPARTNAME}\""
		pvcreate /dev/mapper/"${CRYPTPARTNAME}"
		if [ $? -ne 0 ] ; then deactivate_and_close; return 1 ; fi;
		echo "[Kaiten-Yaki] And then creating Volume group \"${VGNAME}\"."
		vgcreate "${VGNAME}" /dev/mapper/"${CRYPTPARTNAME}"
		if [ $? -ne 0 ] ; then deactivate_and_close; return 1 ; fi;
	fi # if /dev/volume-groupt exist

	# Create a SWAP Logical Volume on VG, if it doesn't exist
	if [ -e /dev/mapper/"${VGNAME}"-"${LVSWAPNAME}" ] ; then 
		echo "[Kaiten-Yaki] Swap volume already exist. Skipped to create. No problem."
	else
		echo "[Kaiten-Yaki] Creating logical volume \"${LVSWAPNAME}\" on \"${VGNAME}\"."
		# Too use the bash IFS, first parameter is not quoted.  
		lvcreate ${LVSWAPSIZE} -n "${LVSWAPNAME}" "${VGNAME}" 
		if [ $? -ne 0 ] ; then deactivate_and_close; return 1 ; fi;
	fi	# if /dev/mapper/swap volume already exit. 

	# Create a ROOT Logical Volume on VG. 
	if [ -e /dev/mapper/"${VGNAME}"-"${LVROOTNAME}" ] ; then # exist
		if [ "${OVERWRITEINSTALL}" -ne 0 ] ; then # exist and overwrite install
			echo "[Kaiten-Yaki] Logical volume \"${VGNAME}-${LVROOTNAME}\" already exists. OK."

			# Create extended volumes if needed
			create_ext_lv
			if [ $? -ne 0 ] ; then deactivate_and_close; return 1 ; fi;

		else	# exist and not overwrite install
			cat <<- HEREDOC 
			***** ERROR : Logical volume "${VGNAME}-${LVROOTNAME}" already exists. *****
			[Kaiten-Yaki] Check LVROOTNAME environment variable in your config.txt.
			HEREDOC
			# Deactivate all lg and close the LUKS volume
			deactivate_and_close
			return 1 # with error status
		fi
	else	# not exsit
		if [ "${OVERWRITEINSTALL}" -ne 0 ] ; then # not exist and overwrite install
			cat <<- HEREDOC 
			***** ERROR : Logical volume "${VGNAME}-${LVROOTNAME}" doesn't exist while overwrite install. *****
			[Kaiten-Yaki] Check consistency of your config.txt.
			HEREDOC
			# Deactivate all lg and close the LUKS volume
			deactivate_and_close
			return 1 # with error status
		else # not exist and not overwrite install
			echo "[Kaiten-Yaki] Creating logical volume \"${LVROOTNAME}\" on \"${VGNAME}\"."
			# Too use the bash IFS, first parameter is not quoted.  
			lvcreate ${LVROOTSIZE} -n "${LVROOTNAME}" "${VGNAME}"
			if [ $? -ne 0 ] ; then deactivate_and_close; return 1 ; fi;
			IS_ROOT_CREATED=1

			# Create extended volumes if needed
			create_ext_lv
			if [ $? -ne 0 ] ; then deactivate_and_close; return 1 ; fi;

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

	# If USELVEXT1 exist.
	if [ "${USELVEXT1}" -ne 0 ] ; then
		echo "LVEXT1           : /dev/mapper/${VGNAME}-${LVROOTNAME}${LVEXT1SUFFIX}"
	fi

	# If USELVEXT2 exist.
	if [ "${USELVEXT2}" -ne 0 ] ; then
		echo "LVEXT2           : /dev/mapper/${VGNAME}-${LVROOTNAME}${LVEXT2SUFFIX}"
	fi

	# In case of erased storage, add this mapping
	if [ "${ERASEALL}" -ne 0 ] ; then
		echo "swap             : /dev/mapper/${VGNAME}-${LVSWAPNAME}"
	fi

	return 0
}


# ******************************************************************************* 
#                  Common post-install stage
# ******************************************************************************* 
# Inside this script, the chrooted job is parameterized as by evn variable TARGETCHROOTEDJOB
function post_install() {
	## Mount the target file system
	# ${TARGETMOUNTPOINT} is created by the GUI/TUI installer.
	# ${BTRFSOPTION} is defined by the caller of this function for BTRFS formated volume.
	# ${BTRFSOPTION} have to be NOT quoted. Otherwise, mount will receive an empty.
	# string as first option, when the veraible is empty. 
	echo "[Kaiten-Yaki] Mounting /dev/mapper/${VGNAME}-${LVROOTNAME} on ${TARGETMOUNTPOINT}."
	mount ${BTRFSOPTION} /dev/mapper/"${VGNAME}"-"${LVROOTNAME}" "${TARGETMOUNTPOINT}"

	# And mount other directories.
	echo "[Kaiten-Yaki] Mounting all other dirs."
	for n in proc sys dev tmp etc/resolv.conf; do mount --rbind "/$n" "${TARGETMOUNTPOINT}/$n"; done

	# Copy all scripts to the target /tmp for using in chroot session. 
	echo "[Kaiten-Yaki] Copying files in current dir to ${TARGETMOUNTPOINT}/tmp."
	mkdir "${TARGETMOUNTPOINT}/tmp/kaiten-yaki"
	cp -r ./* -t "${TARGETMOUNTPOINT}/tmp/kaiten-yaki"

	# Change root and create the keyfile and ramfs image for Linux kernel. 
	# The here-document is script executed under chroot. At here we call 
	# the distribution dependent script "lib/chrooted_job_${DISTRIBUTIONSIGNATURE}.sh",
	# which was copied to /temp at previous code.
	echo "[Kaiten-Yaki] Chroot to ${TARGETMOUNTPOINT}. and execute chrooted_job_${DISTRIBUTIONSIGNATURE}.sh"
	# shellcheck disable=SC2086
	cat <<- HEREDOC | chroot "${TARGETMOUNTPOINT}" /bin/bash
		cd /tmp/kaiten-yaki
		# Execute copied script
		source "lib/chrooted_job_${DISTRIBUTIONSIGNATURE}.sh"
	HEREDOC

	# Unmount all. -l ( lazy ) option is added to supress the busy error. 
	echo "[Kaiten-Yaki] Unmounting all."
	umount -R -l "${TARGETMOUNTPOINT}"

	echo "[Kaiten-Yaki] Post install process finished."

	# Free LUKS volume as swap volume.
	echo "[Kaiten-Yaki] Disabling swap to release the LUKS volume."
	swapoff -a

	# Close LUKS.
	echo "[Kaiten-Yaki] Deactivating all logical volumes in volume group \"${VGNAME}\"."
	vgchange -a n "${VGNAME}"
	echo "[Kaiten-Yaki] Closing LUKS volume \"${CRYPTPARTNAME}\"."
	cryptsetup close  "${CRYPTPARTNAME}"

	# Deleting the passphrase information. 
	echo "[Kaiten-Yaki] Deleting passphrase information."
	PASSPHRASE=""
	export PASSPHRASE

	# Finishing message.
	cat <<- HEREDOC
	****************** Install process finished ******************

	[Kaiten-Yaki] Ready to reboot.
	HEREDOC

	return 0
	
} # End of post_install_local()


# ******************************************************************************* 
#              Deactivate all LV in the VG and close LUKS volume
# ******************************************************************************* 

function deactivate_and_close(){


	if [ "${IS_ROOT_CREATED}" -ne 0 ] ; then	# if extra volume 1 created
		# Remove newly created root volume
		echo "[Kaiten-Yaki] Deleting the new logical volume \"${VGNAME}-${LVROOTNAME}\"."
		lvremove -f /dev/mapper/"${VGNAME}"-"${LVROOTNAME}" 
	fi


	if [ "${IS_LVEXT1_CREATED}" -ne 0 ] ; then	# if extra volume 1 created
		# Remove newly created extra volume 1
		echo "[Kaiten-Yaki] Deleting the new logical volume \"${VGNAME}-${LVROOTNAME}${LVEXT1SUFFIX}\"."
		lvremove -f /dev/mapper/"${VGNAME}"-"${LVROOTNAME}${LVEXT1SUFFIX}" 					
	fi

	if [ "${IS_LVEXT2_CREATED}" -ne 0 ] ; then	# if extra volume 2 created
		# Remove newly created extra volume 2
		echo "[Kaiten-Yaki] Deleting the new logical volume \"${VGNAME}-${LVROOTNAME}${LVEXT2SUFFIX}\"."
		lvremove -f /dev/mapper/"${VGNAME}"-"${LVROOTNAME}${LVEXT2SUFFIX}" 					
	fi



	echo "[Kaiten-Yaki] Deactivating all logical volumes in volume group \"${VGNAME}\"."
	vgchange -a n "${VGNAME}"
	echo "[Kaiten-Yaki] Closing LUKS volume \"${CRYPTPARTNAME}\"."
	cryptsetup close  "${CRYPTPARTNAME}"
	cat <<- HEREDOC 

	[Kaiten-Yaki] Installation process terminated..
	HEREDOC

}

# ******************************************************************************* 
#              Delete the new volume if overwrite install, and close all
# ******************************************************************************* 
function on_unexpected_installer_quit(){
	echo "***** ERROR : The GUI/TUI installer terminated unexpectedly. *****" 
	if [ "${OVERWRITEINSTALL}" -ne 0 ] ; then	# If overwrite install, keep the volume
		echo "[Kaiten-Yaki] Keep logical volume \"${VGNAME}-${LVROOTNAME}\" untouched."
	fi
	# Deactivate all lg and close the LUKS volume
	deactivate_and_close
	echo "[Kaiten-Yaki] You can retry Kaiten-yaki again." 
}


# ******************************************************************************* 
#              Check whether given signature is in the system information
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

			[Kaiten-Yaki] Installation process terminated..
			HEREDOC
			return 1 # with error status
		fi	# if YES

	fi # Distribution check

	# no error
	return 0
}

# ******************************************************************************* 
#              Create extended volume, if needed.
# ******************************************************************************* 


function create_ext_lv() {
	if [ "${USELVEXT1}" -ne 0 ] ; then	# if using extra volume 1
		if [ -e /dev/mapper/"${VGNAME}-${LVROOTNAME}${LVEXT1SUFFIX}" ] ; then # if extra volume 1 exist
			echo "[Kaiten-Yaki] Logical volume \"${VGNAME}-${LVROOTNAME}${LVEXT1SUFFIX}\" already exists. OK."
		else
			echo "[Kaiten-Yaki] Creating logical volume \"${LVROOTNAME}${LVEXT1SUFFIX}\" on \"${VGNAME}\"."
			# Too use the bash IFS, first parameter is not quoted.  
			lvcreate  ${LVEXT1SIZE} -n "${LVROOTNAME}${LVEXT1SUFFIX}" "${VGNAME}"
			if [ $? -ne 0 ] ; then 	# if fail
				echo "***** ERROR : failed to create "${VGNAME}-${LVROOTNAME}${LVEXT1SUFFIX}" . *****"
				return 1 ; 
			else					# if success
				IS_LVEXT1_CREATED=1	# Mark this volume is created 
			fi;
		fi
	fi

	if [ "${USELVEXT2}" -ne 0 ] ; then	# if using extra volume 2
		if [ -e /dev/mapper/"${VGNAME}-${LVROOTNAME}${LVEXT2SUFFIX}" ] ; then # if extra volume 2 exist
			echo "[Kaiten-Yaki] Logical volume \"${VGNAME}-${LVROOTNAME}${LVEXT2SUFFIX}\" already exists. OK."
		else
			echo "[Kaiten-Yaki] Creating logical volume \"${LVROOTNAME}${LVEXT2SUFFIX}\" on \"${VGNAME}\"."
			# Too use the bash IFS, first parameter is not quoted.  
			lvcreate ${LVEXT2SIZE} -n "${LVROOTNAME}${LVEXT2SUFFIX}" "${VGNAME}"
			if [ $? -ne 0 ] ; then 	# if fail
				echo "***** ERROR : failed to create "${VGNAME}-${LVROOTNAME}${LVEXT1SUFFIX}" . *****"
				return 1 ; 
			else					# if success
				IS_LVEXT2_CREATED=1	# Mark this volume as created
			fi;
		fi
	fi

	# no error
	return 0


}

# ******************************************************************************* 
#              Error report and return revsers status.  
# ******************************************************************************* 
function is_error() {
	if [ $? -eq 0 ] ; then # Is previous job OK? 
		return 1	# If OK, return error ( because it was not error )
	else
		cat <<- HEREDOC
		**** ERROR ! ****

		Installation process terminated. 
		HEREDOC
		return 0	# If error, return OK ( because it was error )
	fi;
}
