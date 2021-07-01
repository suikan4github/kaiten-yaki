# Configuration parameters for YaFDE 

# Storage device to install the linux.  
export DEV="/dev/sda"

# Whether you want to erase all contents of the storage device or not.
# 1 : Yes, I want to erase all.
# 0 : No, I don't. I want to add to the existing LUKS volume. 
export ERASEALL=1

# Logical Volume name for your Linux installation. Keep it unique from other distribution.
export LVROOTNAME="anko"

# Logical volume size of the Linux installation.
# 30% mean, new logical volume will use 30% of the free space in the LVM volume group.
# For example, assume the free space is 100GB, and LVROOTSIZE is 30%FREE. Script will create 30GB logical volume.  
export LVROOTSIZE="50%FREE"

# Set the size of EFI partition and swap partition. The unit is Byte. you can use M,G... notation.
export EFISIZE="200M"
export LVSWAPSIZE="8G"

# Usually, these names can be left untouched. 
# If you change, keep them consistent through all instllation in your system.
export CRYPTPARTNAME="luks_volume"
export VGNAME="vg1"
export LVSWAPNAME="swap"

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
if [  ${ISEFI} -eq 1  ] ; then 
# EFI firmware
export EFIPARTITION=1
export CRYPTPARTITION=2
else
# BIOS firmware
export CRYPTPARTITION=1
fi  # EFI firmware

# Void Linux only. Ignored in Ubuntu.
# Detect the GUI environment
if env | grep XDG_SESSION_TYPE > /dev/null ; then
    export GUIENV=1    # set 1 if GUI env.
else
    export GUIENV=0    # set 0 if not GUI env.
fi