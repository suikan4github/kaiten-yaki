# AN04 How to make LUKS volume to the favorite partition
Kaiten-yaki creates the LUKS volume on the 1st partition for the BIOS system ( 2nd partition for the UEFI system ) by default. Also, Kaiten-yaki assigns all space for the  LUKS volume, except the space for the EFI partition. 

This application note explains how to use the favorite partition with favorite size for LUKS volume. 

## Step 1: Making partitions
To use custom partitioning, the user must create all partitions by themselves. The user can do it with the popular partitioning tool like gparted. It is recommended to set the partition table as  MBR and GPT for BIOS and UEFI systems, respectively. 

In this documentation, we assume the user wants to use /dev/sdb3 as LUKS partition to install Ubuntu. 
## Step 2: Configuration
Next user must configure the config.sh. 

The first parameter to edit is **DEV** parameter which represents the target device. In this example, it must be set as /dev/sdb.
```sh
export DEV="/dev/sdb"
```
The second parameter to edit is **CRYPTPARTITION**. By default, this parameter is set automatically according to the firmware type. The EFIPARTITION parameter can be left untouched. This parameter is not used. 
```sh
if [  ${ISEFI} -ne 0  ] ; then 
# EFI firmware
export EFIPARTITION=1
export CRYPTPARTITION=3
else
# BIOS firmware
export CRYPTPARTITION=3
fi  # EFI firmware
```
Makes sure the **ERASEALL** and **OVERWRITEINSTALL** are 0.
## Step 3: Make LUKS partition
After saving the customer config.sh, run the following command to set the environment variable. 
```sh
source config.sh
```
Then, run the following command to create a LUKS volume. 
```sh
cryptsetup luksFormat --iter-time "${ITERTIME}" --type=luks1 --key-file "${DEV}${CRYPTPARTITION}"
```
This command sets up the LUKS volume on the specified partition. This command also asks for the passphrase of this LUKS volume. 
## Step 4: Run Kaiten-yaki
Now, it's a time to run Kaiten-yaki
```sh
kaiten-yaki-ubuntu
```