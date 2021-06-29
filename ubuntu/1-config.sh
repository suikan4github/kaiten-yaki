#!/bin/bash

# Storage device to install the linux.  
export DEV="/dev/sda"

# Whether you want to erase all contents of the storage device or not.
# 1 : Yes, I want to erase all.
# 2 : No, I want to add to the existing Linux distributions. 
export ERASEALL=1

# Logical Volume name for your Linux installation. Keep it unique from other distribution.
export LVROOTNAME="ubuntu"

# Logical volume size of the Linux installation.
# 50% mean, new logical volume will use 50% of the free space in the LVM volume group. 
export LVROOTSIZE="50%FREE"

# Set the size of EFI partition and swap partition. The unit is Byte. you can use M,G... notation.
export EFISIZE="100M"
export LVSWAPSIZE="8G"

# Usually, these names can be left untouched. 
# If you change, keep them consistent through all distributions in your system.
export CRYPTPARTNAME="luks_volume"
export VGNAME="vg1"
export LVSWAPNAME="swap"

# DO NOT touch following lines. 


# Detect firmware type. 1 : EFI, 0 : BIOS
if [ -d /sys/firmware/efi ]; then
export ISEFI=1  # Yes, EFI
else
export ISEFI=0  # No, BIOS
fi # is EFI firmaare? 

# Set partition number based on the firmware type
if [  ${ISEFI} -eq 1  ] ; then 
# EFI firmware
export EFIPARTITION=1
export CRYPTPARTITION=2
else
# BIOS firmware
export CRYPTPARTITION=1
fi  # EFI firmware


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



# ----- Confirmations -----
# Distribution check
uname -a | grep ubuntu -i > /dev/null
if [ $? -eq 1  ] ; then	# "Ubuntu" is not found in the OS name.
	uname -a
	echo "This system seems to be netiher Ubuntu nor Ubuntu variants, while this script is dediated to the Ubuntu or its variants"
	echo "Are you sure you want to run this script for installation? [Y/N]"
	read YESNO
	if [ ${YESNO} != "Y" -a ${YESNO} != "y" ] ; then
		cat <<HEREDOC 1>&2

Installation terminated.
HEREDOC
		return
	fi	# if YES

fi # "Ubuntu" is not found in the OS name.

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

# Finishing message
cat <<HEREDOC

1-config.sh : Done. 

HEREDOC
