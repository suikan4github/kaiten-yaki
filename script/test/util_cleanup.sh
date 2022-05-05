#!/bin/bash -u

	# shellcheck disable=SC1091
	# Load configuration parameter
	source ./config01.sh

# ******************************************************************************* 
#              Delete the nwe volume if overwrite install, and close all
# ******************************************************************************* 
function util_cleanup(){
    echo "...Deleting the new logical volume \"${VGNAME}-${LVROOTNAME}\"."
    lvremove -f /dev/mapper/"${VGNAME}"-"${LVROOTNAME}" 

    if [ "${USELVEXT1}" -ne 0 ] ; then	# if using extra volume 1
        # Remove newly created extra volume 1
        echo "...Deleting the new logical volume \"${VGNAME}-${LVROOTNAME}${LVEXT1SUFFIX}\"."
        lvremove -f /dev/mapper/"${VGNAME}"-"${LVROOTNAME}${LVEXT1SUFFIX}" 					
    fi

    if [ "${USELVEXT2}" -ne 0 ] ; then	# if using extra volume 2
        # Remove newly created extra volume 2
        echo "...Deleting the new logical volume \"${VGNAME}-${LVROOTNAME}${LVEXT2SUFFIX}\"."
        lvremove -f /dev/mapper/"${VGNAME}"-"${LVROOTNAME}${LVEXT2SUFFIX}" 					
    fi

}

util_cleanup
