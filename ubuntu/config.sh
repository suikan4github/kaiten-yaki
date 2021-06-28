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
export CRYPTPARTNAME="luks_volume"
export VGNAME="vg1"
export LVSWAPNAME="swap"

# DO NOT touch following lines. 

# export to share with entire script
export PASSPHRASE

# Detect firmware type. 1 : EFI, 0 : BIOS
if [ -d /sys/firmware/efi ]; then
export ISEFI=1
else
export ISEFI=0
fi

# Set partition number based on the firmware type
if [  ${ISEFI} -eq 1  ] ; then 
# EFI system
export EFIPARTITION=1
export CRYPTPARTITION=2
else
# BIOS system
export CRYPTPARTITION=1
fi
