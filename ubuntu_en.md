# Ubuntu 20.04LTS installation into the LVM on the LUKS volume. 

```bash
# ------------------  Create the partitions  ------------------
# Promote to the root user
sudo -i

```
```bash

# Setup the passphrase of the crypt partition
read -sr PASSPHRASE

```
```bash

# ------------------  Parameter setting  ------------------
# export to share with entire script
export PASSPHRASE

# Device and partition setting. If you wan to MAKE /dev/sda2 as linux root partition,
# set the DEV and ROOTPARTITION to /dev/sda and 2, respectively.
# EFI partition is usualy fixed as partition 1. 
export DEV="/dev/sda"
export EFIPARTITION=1
export ROOTPARTITION=2

# Usually, following names are left unchanged unless existing volumes uses them.
export CRYPTPARTITION="luks_volume"
export VGNAME="vg1"
export LVSWAP="swap"
export LVROOT="ubuntu"

# ROOTSIZE is percentage to the free spage in the volume group. 
# 50% mean, new partition will use 50% of the free space in the LVM volume group. 
export SWAPSIZE="8G"
export ROOTSIZE="50%FREE"


# ------------------  Create the partitions  ------------------

# Optional : Create partitions for in the physical disk. 
# Assign 100MB and rest of disk to the EFI and LUKS partition, respectively.
sgdisk --zap-all "${DEV}"
sgdisk --new=${EFIPARTITION}:0:+100M --change-name=${EFIPARTITION}:"EFI System" --typecode=${EFIPARTITION}:ef00 "${DEV}"
sgdisk --new=${ROOTPARTITION}:0:0     --change-name=${ROOTPARTITION}:"Linux LUKS" --typecode=${ROOTPARTITION}:8309 "${DEV}"
sgdisk --print "${DEV}"

# Format the EFI partition by FAT32. 
mkfs.vfat -F 32 -n EFI-SP "${DEV}${EFIPARTITION}"

```
```bash
# ------------------  Encrypt the volume to install and test  ------------------

# Encrypt the partition to install the linux
printf %s "${PASSPHRASE}" | cryptsetup luksFormat --type=luks1 --key-file - --batch-mode "${DEV}${ROOTPARTITION}"

# Open the created crypt partition. To be sure, input the passphrase manually
cryptsetup open  "${DEV}${ROOTPARTITION}" ${CRYPTPARTITION}

# Check whether successful open. If mapped, it is successful. 
ls -l /dev/mapper

```
```bash
# ------------------  LVM configuration  ------------------

# Create the Physical Volume and Volume Group. 
pvcreate /dev/mapper/${CRYPTPARTITION}
vgcreate ${VGNAME} /dev/mapper/${CRYPTPARTITION}

# Optional : Create the SWAP Logical Volume on VG, if volume size is not 0.
if [  $SIZE != "0"  -a  $SIZE != "0G"  ] ; then lvcreate -L SWAPSIZE -n ${LVSWAP} ${VGNAME} ; fi

# Create the ROOT Logical Volume on VG. 
lvcreate -l ROOTSIZE -n ${LVROOT} ${VGNAME}

```
```bash
# ------------------  Run the ubiquity installer here ------------------

# ------------------  Configuratte the target GRUB during the Ubiquity runs ------------------
# Make target GRUB aware to the crypt partition
echo "GRUB_ENABLE_CRYPTODISK=y" >> /target/etc/default/grub

```
```bash
# ------------------  Wait the end of Ubiquity ------------------
# ------------------  Mount the targets ------------------
# Mount the volume and change root
# /target is created by the Ubiquity installer
mount /dev/mapper/${VGNAME}-${LVROOT} /target
for n in proc sys dev etc/resolv.conf; do mount --rbind "/$n" "/target/$n"; done
chroot /target /bin/bash
```
```bash

# ------------------ Add auto decryption to the target kernel -----------------
# Mount the rest of partitions by target /etc/fstab
mount -a

# Set up the kernel hook of encryption
apt install -y cryptsetup-initramfs
echo "KEYFILE_PATTERN=/etc/luks/*.keyfile" >> /etc/cryptsetup-initramfs/conf-hook
echo "UMASK=0077" >> /etc/initramfs-tools/initramfs.conf

# Prepare the key file for auto decryption
mkdir /etc/luks
dd if=/dev/urandom of=/etc/luks/boot_os.keyfile bs=4096 count=1
chmod u=rx,go-rwx /etc/luks
chmod u=r,go-rwx /etc/luks/boot_os.keyfile

# Make the keyfile
printf %s "${PASSPHRASE}" | cryptsetup luksAddKey -d - "${DEV}${ROOTPARTITION}" /etc/luks/boot_os.keyfile

# Add the LUKS partition to /etc/crypttab to decrypt automatically 
echo "${CRYPTPARTITION} UUID=$(blkid -s UUID -o value ${DEV}${ROOTPARTITION}) /etc/luks/boot_os.keyfile luks,discard" >> /etc/crypttab

# Finally, update the ramfs initial image with the key file. 
update-initramfs -uk all

```
```bash
#  ------------------ Finishing installation -----------------
exit
reboot

```