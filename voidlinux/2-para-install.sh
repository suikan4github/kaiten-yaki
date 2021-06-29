#!/bin/bash

# Varidate whether script is executed as sourced or not
(return 0 2>/dev/null) && sourced=1 || sourced=0
if [ $sourced -eq 0 ] ; then
	cat <<HEREDOC 1>&2
***** ERROR : Must execute as source *****
Execute as following : 
source 2-para-install.sh

Installation terminated.
HEREDOC
	exit    # use "exit" instead of "return", if not "sourced" execusion
fi # "sourced" validation


# Check whether grub configuration file is ready to write
if [ ! -e /mnt/target/etc/default/grub ] ; then 
	cat <<HEREDOC 1>&2
***** ERROR : The /mnt/target/etc/default/grub is not ready. *****
Perhaps, too early to execute this script.

Installation terminated.
HEREDOC
	return
fi  # if grub file exists

# Make target GRUB aware to the crypt partition
echo "...Add GRUB_ENABLE_CRYPTODISK entry to /mnt/target/etc/default/grub "
echo "GRUB_ENABLE_CRYPTODISK=y" >> /mnt/target/etc/default/grub 

# Finishing message
cat <<HEREDOC
****************** Para-install process finished ******************

...Select "NO" to boot, when void-installer finishes. 
...And then, execute "source 3-post-install.sh"
HEREDOC
