#!/bin/bash

# #####################################

# Test setup. 
# /dev/sdb/
# ERASEALL
# LVROOT 10%
# LVEXT1 90%
# LVEXT2 10%

# #####################################

# Configuration parameters for Kaiten-Yaki 

# Storage device to install the linux.  
export DEV="/dev/sdb"

# Whether you want to erase all contents of the storage device or not.
# 1 : Yes, I want to erase all.
# 0 : No, I don't. I want to add to the existing LUKS volume. 
export ERASEALL=1

# Logical Volume name for your Linux installation. 
# Keep it unique from other distribution.
export LVROOTNAME="anko"

# Suffix of the optional logical volumes. 
# If you want to have optional OVs, set USELVEXT# to 1. 
# Then, the suffix will be added to the LVROOTNAME. 
# For example, Assume you have setting below : 
# LVROOTNAME="anko"
# USELVEXT1=1
# LVEXT1SUFFIX="_home"
# USELVEXT2=0
# LVEXT2SUFFIX="_var"
# You will have
# anko
# anko_home
# You will not have anko_var because the USELVEXT2=0.
export USELVEXT1=1
export LVEXT1SUFFIX="_home"
export USELVEXT2=1
export LVEXT2SUFFIX="_var"

# Logical volume size of the Linux installation.
# 30% mean, new logical volume will use 30% of the free space 
# in the LVM volume group. For example, assume the free space is 100GB, 
# and LVROOTSIZE is 30%FREE. Script will create 30GB logical volume.  
# Note that the order of the volume creation is : 
# 1. EFI if needed
# 2. SWAP
# 3. LVROOT
# 4. LVEXT1 if needed
# 5. LVEXT2 if needed
export LVROOTSIZE="10%FREE"

# Logical volume size of the optional volumes. 
export LVEXT1SIZE="90%FREE"
export LVEXT2SIZE="100%FREE"

# Set the size of EFI partition and swap partition. 
# The unit is Byte. You can use M,G... notation.
export EFISIZE="200M"
export LVSWAPSIZE="8G"

# Usually, these names can be left untouched. 
# If you change, keep them consistent through all installation in your system.
export CRYPTPARTNAME="luks_test"
export VGNAME="vg_test"
export LVSWAPNAME="swap"

# Do not touch this parameter, unless you understand what you are doing.
# 1 : Overwrite the existing logical volume as root volume. 
# 0 : Create new logical volume as root volume. 
export OVERWRITEINSTALL=0

# Do not touch this parameter, unless you understand what you are doing.
# This is a paameter value of the --iter-time option for cyrptsetup command. 
# If you specify 1000, that means 1000mSec. 0 means compile default.  
export ITERTIME=0

# Void Linux only. Ignored in Ubuntu.
# The font size of the void-installer
export XTERMFONTSIZE=11

# !!!!!!!!!!!!!! DO NOT EDIT FOLLOWING LINES. !!!!!!!!!!!!!!

# Detect firmware type. 1 : EFI, 0 : BIOS
if [ -d /sys/firmware/efi ]; then
export ISEFI=1  # Yes, EFI
else
export ISEFI=0  # No, BIOS
fi # is EFI firmaare? 

# Set partition number based on the firmware type
if [  ${ISEFI} -ne 0  ] ; then 
# EFI firmware
export EFIPARTITION=1
export CRYPTPARTITION=2
else
# BIOS firmware
export CRYPTPARTITION=1
fi  # EFI firmware

# Detect the GUI environment
# This code is not efered. Just left because it is interestintg code. 
if env | grep -w -e XDG_SESSION_TYPE -e DISPLAY -e WAYLAND_DISPLAY > /dev/null ; then
    export GUIENV=1    # set 1 if GUI env.
else
    export GUIENV=0    # set 0 if not GUI env.
fi