# Ubuntu/Void-Linux installation into the LVM on the LUKS volume

Installation requires mainly 2 steps. 
 
- Configure the parameters in config.sh.
- Run the kaiten-yaki script

You can execute the install script without command line parameter. For example :
```shell
source ubuntu-kaiten-yaki.sh
```
The first stage of the script is preparation like : erasing disk, format partition, and encryption. This is most critical stage of the entire installation process. This part is controlled by the configuration parameter. Thus, you have to edit the config.txt carefully. 

In the second stage, the distribution dependent GUI/TUI installer is invoked from the running script. That is the Ubiquity/void-installer of Ubuntu/Void linux, respectively. 

The third stage is easy. There is nothing user can do. Everything is automatic. 
# Installation
Follow the steps below. 

## Shell preparation
First of all, promote the shell to root. Almost of the procedure requires root privilege. Note that the scripts requires Bash. 

In case of Ubuntu :
```bash
# Promote to the root user
sudo -i
```
In case of Void-Linux : 
```bash
sudo -i
bash
xbps-install -Su xbps nano
```
The nano is editor package to configure the config.txt. The editor choice is up to you. Kaiten-yaki script doesn't have dependency to nano editor.

Then, edit the config.txt. 

## Configuration parameters
This is very critical part of the installation. The configuration parameters are in the the config.sh. Edit these parameters before the installation. 

Followings are the set of the default settings of the parameters : 
- Install to  **/dev/sda** (DEV).
- Erase entire disk (ERASEALL).
- Overwrite install is disabled.
- In case of EFI firmware, 200MB is allocated to the EFI partition (EFISIZE).
- Create a logical volume group named "vg1" in the encrypted volume (VGNAME)
- Create a swap logical volume named "swap" in the "vg1". The size is 8GB (LVSWAPNAME,LVSWAPSIZE)
- Create a logical volume named **"anko"** for / in the "vg1". The size of the **50%** of the entire free space (LVROOTNAME, LVROOTSIZE).

```bash
# Configuration parameters for Kaiten-Yaki 

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

# Do not touch this parameter, unless you understand precisely what you are doing.
# 1 : Overwrite the existing logical volume as root vlume. 0 : Create new logical volume as root volume. 
export OVERWRITEINSTALL=0

# Void Linux only. Ignored in Ubuntu.
# The font size of the void-installer
export XTERMFONTSIZE=11
```

There are several restrictions : 
- For the first distribution installation, you must set ERASEALL to 1, to erase entire screen and create a LUKS partition. Kaiten-yaki script creates a maximum LUKS partition as possible. 
- The LVROOMNAME must be unique among all installations in a computer. Otherwise, Kaiten-yaki terminate at a middle. 
- The LVSWAPNAME must be unique among all installations in a computer. Otherwise, Kaiten-yaki creates an unnecessary logical volume. This is waste of storage resource. 
- The EFISIZE and the LVSWAPSIZE are refereed during the first distribution installation only. 
- The LVROOTSIZE is the size of a logical volume to create. This is a relative value to the existing free space in the volume group. If you want to install 3 distributions in a computer, you may want to set 33%FREE, 50%FREE, and 100%FREE for the first, second, and third distribution installation, respectively. 
- The name with "-" is not allowed for the VGNAME, LVROOTNAME, and LVSWAPNAME. I saw some installer doesn't work if "-" in in the name. 
## About the overwrite-install
The OVERWRITEINSTALL parameter allows you to use an existing logical volume as root volume of the new installation.
This is very danger because of the several aspect like destroying wrong volume and risk of security. But sometimes it is
very useful. 

For example, assume you are installing a distribution by Kaiten-yaki. If you reboot the system at the end of GUI/TUI installer by mistake, your system will never boot again. 
In this case, the overwrite-install can recycle this "bad" logical volume and let your system boot again. 

To use the overwrite-install, you have to set some parameters as following : 
- ERASEALL : 0
- OVERWRITEINSTALL : 1

And set following parameters as same as previous installation. 
- LVROOTNAME
- VGNAME
- CRYPTPARTNAME

So, Kaiten-yaki will leave the "bad" logical volume and allow you to overwrite it by GUI/TUI installer. 
## First stage : Setting up the volumes
After you set the configuration parameters correctly, execute the following command from the shell. Again, you have to be promoted as root user, and you have to use Bash.  

In case of Ubuntu :
```bash
source ubuntu-kaiten-yaki.sh
```

In case of Void Linux
```bash
source void-kaiten-yaki.sh
```
After the several interactive confirmations, Kaiten-yaki will ask you to input a passphrase. This passphrase will be applied to the encryption of the LUKS volume. Make sure you use identical passphrase between all installation of the distributions  in a computer. Otherwise, install process terminates with error.  

## Second stage : GUI/TUI installer
After the first script finishes, the GUI/TUI installer starts automatically. Configure it as usual and run it. Ensure you map the followings correctly.
Target Directory | Host Volume            | Comment
-----------------|------------------------|---------------------------------------------------------------
/boot/efi        | /dev/sda1              | BIOS system doesn't need this mapping
/                | /dev/mapper/vg1-ubuntu | Host volume name is up to your configuration parameter.
swap             | /dev/mapper/swap       | Only the first distribution installation requires this mapping.

During the GUI/TUI installer copying files, Kaiten-yaki modifies the /etc/default/grub of target system. This is pretty dirty way. But if we don't modify this file, GUI/TUI installer fails at last. 

![Ubuntu Partitioning](image/ubuntu_partitioning.png)
![Void Partitioning](image/void_partitioning.png)

## Do not reboot
At the end of the GUI/TUI installing, do not reboot the system. Click "Continue" and just exit the GUI/TUI installer without rebooting. Otherwise, we cannot finalize the entire installation process. 

![Ubuntu done](image/ubuntu_done.png)
![Void done](image/void_done.png)

## Third stage : Finalizing
After GUI/TUI installer quit without rebooting, final part of the install process automatically starts. 

In this section, Kaiten-yaki put the encryption key of the LUKS volume in to the ramfs initial stage to allow the Linux kernel decrypt the LUKS partition which contains root logical volume. So, system will ask you passphrase only once when GRUB start. 

You can reboot the system, if you see the "Ready to reboot" message on the console. 

