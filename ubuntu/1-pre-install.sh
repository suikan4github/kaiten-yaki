#!/bin/bash

# Varidate whether script is executed as sourced or not
(return 0 2>/dev/null) && sourced=1 || sourced=0
if [ $sourced -eq 0 ] ; then
	cat <<HEREDOC 1>&2
***** ERROR : Must execute as source *****
Execute as following : 
source 1-pre-install.sh

Installation terminates.
HEREDOC
	exit
fi


# ----- Set Passphrase -----
# Input passphrase
echo "Type passphrase for the disk encryption."
read -sr PASSPHRASE

echo "Type passphrase again, to confirm."
read -sr PASSPHRASE_C

# Validate whether both are indentical or not
if [ ${PASSPHRASE} = ${PASSPHRASE_C} ] ; then
	export PASSPHRASE
else
	cat <<HEREDOC 1>&2
***** ERROR : Passphrase doesn't match *****
Installation terminates.
HEREDOC
	return
fi

# ----- Configuration Parameter -----
# Load the configuration parameter
source config.sh

# ----- Format the disk and encrypt the LUKS partition -----
if [ ${ERASEALL} -eq 1 ] ; then
# Optional : Create partitions for in the physical disk. 
# Assign specified space and rest of disk to the EFI and LUKS partition, respectively.
	if [  ${ISEFI} -eq 1 ] ; then
		# Zap existing partition table and create new GPT
		sgdisk --zap-all "${DEV}"
		# Create EFI partition and format it
		sgdisk --new=${EFIPARTITION}:0:+${EFISIZE} --change-name=${EFIPARTITION}:"EFI System"  --typecode=${EFIPARTITION}:ef00 "${DEV}"  
		mkfs.vfat -F 32 -n EFI-SP "${DEV}${EFIPARTITION}"
		# Create Linux partition
		sgdisk --new=${CRYPTPARTITION}:0:0    --change-name=${CRYPTPARTITION}:"Linux LUKS" --typecode=${CRYPTPARTITION}:8309 "${DEV}"
		# Then print them
		sgdisk --print "${DEV}"
	else
		# Zap existing partition table
		dd if=/dev/zero of=${DEV} bs=512 count=1
		# Create MBR and allocate max storage for Linux partition
		sfdisk ${DEV} <<HEREDOC
2M,,L
HEREDOC
	fi
	# if EFI firmware

	# Encrypt the partition to install Linux
	printf %s "${PASSPHRASE}" | cryptsetup luksFormat --type=luks1 --key-file - --batch-mode "${DEV}${CRYPTPARTITION}"

fi
# if erase all

# ----- Open the LUKS partition -----
# Open the created crypt partition. 
printf %s "${PASSPHRASE}" | cryptsetup open -d - "${DEV}${CRYPTPARTITION}" ${CRYPTPARTNAME}

# Check whether successful open. If mapped, it is successful. 
if [ ! -d /dev/mapper/${CRYPTPARTNAME} ] ; then 
	cat <<HEREDOC 1>&2
***** ERROR : Cannot open LUKS volume ${CRYPTPARTNAME} on ${DEV}${CRYPTPARTITION}. *****
Check the passphrase

Installation terminates.
HEREDOC
	return
fi

# ----- Configure the LVM in LUKS volume -----
# The swap volume and / volume is created here, based on the given parameters. 
# Create a Physical Volume and Volume Group. 
pvcreate /dev/mapper/${CRYPTPARTNAME}
vgcreate ${VGNAME} /dev/mapper/${CRYPTPARTNAME}

# Create a SWAP Logical Volume on VG, if it doesn't exist
if [ ! -d /dev/mapper/${VGNAME}-${LVSWAPNAME} ] ; then 
	lvcreate -L ${LVSWAPSIZE} -n ${LVSWAPNAME} ${VGNAME} 
else
	echo "Swap volume already exist. Skipped to create" 1>&2
fi

# Create a ROOT Logical Volume on VG. 
if [ ! -d /dev/mapper/${VGNAME}-${LVROOTNAME} ] ; then 
	lvcreate -l ${LVROOTSIZE} -n ${LVROOTNAME} ${VGNAME}
else
	cat <<HEREDOC 1>&2
***** ERROR : Logical volume ${VGNAME}-${LVROOTNAME} already exists. *****
Check LVROOTNAME environment variable.

Installation terminates.
HEREDOC
	return
fi


