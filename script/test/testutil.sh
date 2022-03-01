

# ******************************************************************************* 
#              Deactivate all LV in the VG and close LUKS volume
# ******************************************************************************* 

function util_deactivate_and_close(){
	echo "...Deactivating all logical volumes in volume group \"${VGNAME}\"."
	vgchange -a n "${VGNAME}"
	echo "...Closing LUKS volume \"${CRYPTPARTNAME}\"."
	cryptsetup close  "${CRYPTPARTNAME}"
	cat <<- HEREDOC 

	...Installation process terminated..
	HEREDOC

}

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
