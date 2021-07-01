#!/bin/bash

# Varidate whether script is executed as sourced or not
(return 0 2>/dev/null) && sourced=1 || sourced=0
if [ $sourced -eq 0 ] ; then
	cat <<HEREDOC 1>&2
***** ERROR : Must execute as source *****
Execute as following : 
source ubuntu-kaiten-yaki.sh

Installation terminated.
HEREDOC
	exit    # use "exit" instead of "return", if not "sourced" execusion
fi # "sourced" validation

# Load configuration parameter
source config.sh

# ******************************************************************************* 
#                        Confirmation and Passphrase setting 
# ******************************************************************************* 

# Distribution check
if ! uname -a | grep ubuntu -i > /dev/null  ; then	# "Ubuntu" is not found in the OS name.
	echo "*******************************************************************************"
	uname -a
	cat <<HEREDOC 
*******************************************************************************
This system seems to be not Ubuntu, while this script is dediated to the Ubuntu.
Are you sure you want to run this script? [Y/N]
HEREDOC
	read YESNO
	if [ ${YESNO} != "Y" -a ${YESNO} != "y" ] ; then
		cat <<HEREDOC 1>&2

Installation terminated.
HEREDOC
		return
	fi	# if YES

fi # "Ubuntu" is not found in the OS name.

# Sanity check for volume group name

if echo ${VGNAME} | grep "-" -i > /dev/null ; then	# "-" is found in the volume group name.
	cat <<HEREDOC 1>&2
***** ERROR : VGNAME is "${VGNAME}" *****
THe "-" is not allowed in the volume name. 
Check passphrase and config.txt

Installation terminated.
HEREDOC
		return
fi # "-" is found in the volume group name.

# Sanity check for root volume name

if echo ${LVROOTNAME} | grep "-" -i > /dev/null ; then	# "-" is found in the volume name.
	cat <<HEREDOC 1>&2
***** ERROR : LVROOTNAME is "${LVROOTNAME}" *****
THe "-" is not allowed in the volume name. 
Check passphrase and config.txt

Installation terminated.
HEREDOC
		return
fi # "-" is found in the volume name.

# Sanity check for swap volume name
if echo ${LVSWAPNAME} | grep "-" -i > /dev/null ; then	# "-" is found in the volume name.
	cat <<HEREDOC 1>&2
***** ERROR : LVSWAPNAME is "${LVSWAPNAME}" *****
THe "-" is not allowed in the volume name. 
Check passphrase and config.txt

Installation terminated.
HEREDOC
		return
fi # "-" is found in the volume name.

# For surre ask the config.sh is edited
cat <<HEREDOC

The destination logical volume label is "${LVROOTNAME}"
"${LVROOTNAME}" uses ${LVROOTSIZE} of the LVM volume group.
Are you ready to install? [Y/N]
HEREDOC
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
Check config.sh. The variable ERASEALL is ${ERASEALL}.

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


# ******************************************************************************* 
#                                Pre-install stage 
# ******************************************************************************* 


# ----- Erase entire disk, create partitions, format them  and encrypt the LUKS partition -----
if [ ${ERASEALL} -eq 1 ] ; then

	# Assign specified space and rest of disk to the EFI and LUKS partition, respectively.
	if [  ${ISEFI} -eq 1 ] ; then
		# Zap existing partition table and create new GPT
		echo "...Initialize ${DEV} with GPT."
		sgdisk --zap-all "${DEV}"
		# Create EFI partition and format it
		echo "...Create an EFI partition on ${DEV}."
		sgdisk --new=${EFIPARTITION}:0:+${EFISIZE} --change-name=${EFIPARTITION}:"EFI System"  --typecode=${EFIPARTITION}:ef00 "${DEV}"  
		echo "...Format the EFI parttion."
		mkfs.vfat -F 32 -n EFI-SP "${DEV}${EFIPARTITION}"
		# Create Linux partition
		echo "...Create a Linux partition on ${DEV}."
		sgdisk --new=${CRYPTPARTITION}:0:0    --change-name=${CRYPTPARTITION}:"Linux LUKS" --typecode=${CRYPTPARTITION}:8309 "${DEV}"
		# Then print them
		sgdisk --print "${DEV}"
	else
		# Zap existing partition table
		echo "...Erase partition table of ${DEV}."
		dd if=/dev/zero of=${DEV} bs=512 count=1
		# Create MBR and allocate max storage for Linux partition
		echo "...Create a Linux partition on ${DEV} with MBR."
		sfdisk ${DEV} <<HEREDOC
2M,,L
HEREDOC
	fi	# if EFI firmware

	# Encrypt the partition to install Linux
	echo "...Initialize ${DEV}${CRYPTPARTITION} as crypt partition"
	printf %s "${PASSPHRASE}" | cryptsetup luksFormat --type=luks1 --key-file - --batch-mode "${DEV}${CRYPTPARTITION}"

fi	# if erase all

# ----- Open the LUKS partition -----
# Open the crypt partition. 
echo "...Open a crypt partition ${DEV}${CRYPTPARTITION} as \"${CRYPTPARTNAME}\""
printf %s "${PASSPHRASE}" | cryptsetup open -d - "${DEV}${CRYPTPARTITION}" ${CRYPTPARTNAME}

# Check whether successful open. If mapped, it is successful. 
if [ ! -e /dev/mapper/${CRYPTPARTNAME} ] ; then 
	cat <<HEREDOC 1>&2
***** ERROR : Cannot open LUKS volume "${CRYPTPARTNAME}" on ${DEV}${CRYPTPARTITION}. *****
Check passphrase and config.txt

Installation terminated.
HEREDOC
	return
fi	# if crypt volume is unable to open

# ----- Configure the LVM in LUKS volume -----
# Check volume group ${VGNAME} exist or not
if  vgdisplay -s ${VGNAME} &> /dev/null ; then		#  exist ?
	echo "...Volume group ${VGNAME} already exist. Skipped to create. No problem."
else
	echo "...Initialize a physical volume on \"${CRYPTPARTNAME}\""
	pvcreate /dev/mapper/${CRYPTPARTNAME}
	echo "...And then create Volume group \"${VGNAME}\"."
	vgcreate ${VGNAME} /dev/mapper/${CRYPTPARTNAME}
fi # if /dev/volume-groupt exist

# Create a SWAP Logical Volume on VG, if it doesn't exist
if [ -e /dev/mapper/${VGNAME}-${LVSWAPNAME} ] ; then 
	echo "...Swap volume already exist. Skipped to create. No problem."
else
	echo "...Create logical volume \"${LVSWAPNAME}\" on \"${VGNAME}\"."
	lvcreate -L ${LVSWAPSIZE} -n ${LVSWAPNAME} ${VGNAME} 
fi	# if /dev/mapper/swap volume already exit. 

# Create a ROOT Logical Volume on VG. 
if [ -e /dev/mapper/${VGNAME}-${LVROOTNAME} ] ; then 
	cat <<HEREDOC 1>&2
***** ERROR : Logical volume "${VGNAME}-${LVROOTNAME}" already exists. *****
Check LVROOTNAME environment variable in config.txt.

Installation terminated.
HEREDOC
	return
else
	echo "...Create logical volume \"${LVROOTNAME}\" on \"${VGNAME}\"."
	lvcreate -l ${LVROOTSIZE} -n ${LVROOTNAME} ${VGNAME}
fi	# if the root volun already exist

# ******************************************************************************* 
#                                Para-install stage 
# ******************************************************************************* 
cat <<HEREDOC
******************************************************************************
The pre-install process is done. We are ready to install the Linux to the 
target storage device. By pressing return key, Ubuntu Ubiquity installer 
starts.

Please pay attention to the partition/logical volume mapping configuration. 
In this installation, you have to map the previously created partitions/logical
volumes to the appropriate directories of the target system as followings :

HEREDOC

# In the EFI system, add this mapping
if [  ${ISEFI} -eq 1 ] ; then
	echo "/boot/efi        : ${DEV}${EFIPARTITION}"
fi

# Root volume mapping
echo "/                : /dev/mapper/${VGNAME}-${LVROOTNAME}"

# In case of erased storage, add this mapping
if [ ${ERASEALL} -eq 1 ] ; then
	echo "swap             : /dev/mapper/${VGNAME}-${LVSWAPNAME}"
fi

cat <<HEREDOC

************************ CAUTION! CAUTION! CAUTION! ****************************
 
Make sure to click "Continue Testing",  at the end of the Ubiquity installer.
Just exit the installer without rebooting.

Type return key to start Ubiquity.
HEREDOC

# waitfor a console input
read dummy_var

# Start GUI installer 
ubiquity &
# Record the PID
ubiquity_pid=$!

# While the /etc/default/grub in the install target is NOT existing, keep sleeping.
# If ubiquity terminated without file copy, this script also terminates.
while [ ! -e /target/etc/default/grub ]
do
	sleep 1 # 1sec.

	 # Check if installer still exist
	if ! ps $ubiquity_pid  > /dev/null ; then	# If not exists
	cat <<HEREDOC 1>&2
The ubiquity installer terminated unexpectedly. 

Installation process terminated.
HEREDOC
	return

	fi
done # while

# Perhaps, too neuvous. Wait 1 more sectond to avoid the rece condition.
sleep 1 # 1sec.

# Make target GRUB aware to the crypt partition
# This must do it after start of the file copy by ubiquity, but before the end of the file copy.
echo "...Add GRUB_ENABLE_CRYPTODISK entry to /target/etc/default/grub "
echo "GRUB_ENABLE_CRYPTODISK=y" >> /target/etc/default/grub


# And then, wait for the end of Ubiquity process
echo "...Waiting for the end of Ubiquity installer."
wait $ubiquity_pid

# ******************************************************************************* 
#                                Post-install stage 
# ******************************************************************************* 

## Mount the target file system
# /target is created by the Ubiquity installer
echo "...Mount /dev/mapper/${VGNAME}-${LVROOTNAME} on /target."
mount /dev/mapper/${VGNAME}-${LVROOTNAME} /target

# And mount other directories
echo "...Mount all other dirs."
for n in proc sys dev etc/resolv.conf; do mount --rbind "/$n" "/target/$n"; done

# Change root and create the keyfile and ramfs image for Linux kernel. 
echo "...Chroot to /target."
cat <<HEREDOC | chroot /target /bin/bash
# Mount the rest of partitions by target /etc/fstab
mount -a

# Set up the kernel hook of encryption
echo "...Install cryptsetup-initramfs package."
apt -qq install -y cryptsetup-initramfs
echo "...Register key file to the ramfs"
echo "KEYFILE_PATTERN=/etc/luks/*.keyfile" >> /etc/cryptsetup-initramfs/conf-hook
echo "UMASK=0077" >> /etc/initramfs-tools/initramfs.conf

# Prepare a key file to embed in to the ramfs.
echo "...Prepair key file."
mkdir /etc/luks
dd if=/dev/urandom of=/etc/luks/boot_os.keyfile bs=4096 count=1 status=none
chmod u=rx,go-rwx /etc/luks
chmod u=r,go-rwx /etc/luks/boot_os.keyfile

# Add a key to the key file. Use the passphrase in the environment variable. 
echo "...Add a key to the key file."
printf %s "${PASSPHRASE}" | cryptsetup luksAddKey -d - "${DEV}${CRYPTPARTITION}" /etc/luks/boot_os.keyfile

# Add the LUKS volume information to /etc/crypttab to decrypt by kernel.  
echo "...Add LUKS volume info to /etc/crypttab."
echo "${CRYPTPARTNAME} UUID=$(blkid -s UUID -o value ${DEV}${CRYPTPARTITION}) /etc/luks/boot_os.keyfile luks,discard" >> /etc/crypttab

# Finally, update the ramfs initial image with the key file. 
echo "...Upadte initramfs."
update-initramfs -uk all

# Leave chroot
HEREDOC

# Unmount all
echo "...Unmount all."
umount -R /mnt/target

# Finishing message
cat <<HEREDOC
****************** Post-install process finished ******************

...Ready to reboot.
HEREDOC
