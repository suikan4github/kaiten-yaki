#!/bin/bash

# Varidate whether script is executed as sourced or not
(return 0 2>/dev/null) && sourced=1 || sourced=0
if [ $sourced -eq 0 ] ; then
	cat <<HEREDOC 1>&2
***** ERROR : Must execute as source *****
Execute as following : 
source 2-para-install.sh

Installation terminates.
HEREDOC
	exit
fi


# Check whether grub configuration file is ready to write
if [ ! -e /target/etc/default/grub ] ; then 
	cat <<HEREDOC 1>&2
***** ERROR : The /target/etc/default/grub is not ready. *****
Perhaps, to early to execute this script.

Installation terminates.
HEREDOC
	return
fi

# Make target GRUB aware to the crypt partition
echo "GRUB_ENABLE_CRYPTODISK=y" >> /target/etc/default/grub

cat <<HEREDOC

2-para-install.sh : Done. 
Make sure to click "Continue Testing", when the Ubiquity installer finishes. 

HEREDOC
