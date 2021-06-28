#!/bin/bash

# Varidate whether script is executed as sourced or not
(return 0 2>/dev/null) && sourced=1 || sourced=0
if [ $sourced -eq 0 ] ; then
	cat <<HEREDOC 1>&2
***** ERROR : Must execute as source *****
Execute as following : 
source 1-pre-install.sh

Installation terminated.
HEREDOC
	exit    # use "exit" instead of "return", if not "sourced" execusion
fi # "sourced" validation

# ----- Configuration Parameter -----
# Load the configuration parameter
source config.sh

# For surre ask the config.sh is edited
echo "Did you edit config.sys? Are you ready to install? [Y/N]"
read YESNO
if [ ${YESNO} != "Y" -a ${YESNO} != "y" ] ; then
	cat <<HEREDOC 1>&2

Installation terminated.
HEREDOC
	return
fi	# if YES


# For sure ask ready to erase. 
if [ ${ERASEALL} -eq 1 ] ; then
	echo "Are you sure you want to erase entire ${DEV}? [Y/N]"
	read YESNO
	if [ ${YESNO} != "Y" -a ${YESNO} != "y" ] ; then
		cat <<HEREDOC 1>&2
Check config.sh. The ERASEALL is ${ERASEALL}.

Installation terminated.
HEREDOC
		return
	fi	# if YES
fi	# if erase all

# ----- Set Passphrase -----
# Input passphrase
echo "Type passphrase for the disk encryption."
read -sr PASSPHRASE
export PASSPHRASE

echo "Type passphrase again, to confirm."
read -sr PASSPHRASE_C

# Validate whether both are indentical or not
if [ ${PASSPHRASE} != ${PASSPHRASE_C} ] ; then
	cat <<HEREDOC 1>&2
***** ERROR : Passphrase doesn't match *****
Installation terminated.
HEREDOC
	return
fi	# passphrase validation

# ----- Erase entire disk, create partitions, format them  and encrypt the LUKS partition -----
if [ ${ERASEALL} -eq 1 ] ; then

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
	fi	# if EFI firmware

	# Encrypt the partition to install Linux
	printf %s "${PASSPHRASE}" | cryptsetup luksFormat --type=luks1 --key-file - --batch-mode "${DEV}${CRYPTPARTITION}"

fi	# if erase all

# ----- Open the LUKS partition -----
# Open the crypt partition. 
printf %s "${PASSPHRASE}" | cryptsetup open -e - "${DEV}${CRYPTPARTITION}" ${CRYPTPARTNAME}

# Check whether successful open. If mapped, it is successful. 
if [ ! -e /dev/mapper/${CRYPTPARTNAME} ] ; then 
	cat <<HEREDOC 1>&2
***** ERROR : Cannot open LUKS volume ${CRYPTPARTNAME} on ${DEV}${CRYPTPARTITION}. *****
Check passphrase and config.txt

Installation terminated.
HEREDOC
	return
fi	# if crypt volume is unable to open

# ----- Configure the LVM in LUKS volume -----
# Create a Physical Volume and Volume Group, if first time
if [ ! -e /dev/${VGNAME} ]; then
	pvcreate /dev/mapper/${CRYPTPARTNAME}
	vgcreate ${VGNAME} /dev/mapper/${CRYPTPARTNAME}
fi # if /dev/volume-groupt not exist

# Create a SWAP Logical Volume on VG, if it doesn't exist
if [ -e /dev/mapper/${VGNAME}-${LVSWAPNAME} ] ; then 
	echo "Swap volume already exist. Skipped to create" 1>&2
else
	lvcreate -L ${LVSWAPSIZE} -n ${LVSWAPNAME} ${VGNAME} 
fi	# if /dev/mapper/swap volume already exit. 

# Create a ROOT Logical Volume on VG. 
if [ -e /dev/mapper/${VGNAME}-${LVROOTNAME} ] ; then 
	cat <<HEREDOC 1>&2
***** ERROR : Logical volume ${VGNAME}-${LVROOTNAME} already exists. *****
Check LVROOTNAME environment variable in config.txt.

Installation terminated.
HEREDOC
	return
else
	lvcreate -l ${LVROOTSIZE} -n ${LVROOTNAME} ${VGNAME}
fi	# if the root volun already exist

# Finishing message
cat <<HEREDOC

1-pre-install.sh : Done. Next, run the Ubiquity installer.

HEREDOC

