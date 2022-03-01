#!/bin/bash -u

	# shellcheck disable=SC1091
	# Load configuration parameter
	source ./config01.sh

	# Load common functions
	source ../lib/common.sh

function main() {

	# This is the mount point of the install target. 
	export TARGETMOUNTPOINT="/target"

	# ******************************************************************************* 
	#                                Confirmation before installation 
	# ******************************************************************************* 

	# parameters for distribution check
	export DISTRIBUTIONSIGNATURE="ubuntu"
	export DISTRIBUTIONNAME="Ubuntu"

	# Check whetehr given signature exist or not
	if ! distribution_check ; then
		return 1 # with error status
	fi

	# Common part of the parameter confirmation
	if ! confirmation ; then
		return 1 # with error status
	fi

	# ******************************************************************************* 
	#                                Pre-install stage 
	# ******************************************************************************* 

	# Common part of the pre-install stage
	if ! pre_install ; then
		return 1 # with error status
	fi
}

# main routine
main

