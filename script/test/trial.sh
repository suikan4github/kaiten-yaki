#!/bin/bash

DISK=/dev/sdb

DISKSIZE=$(blockdev --report ${DISK} | awk /${DISK}/'{print $6}')
VOLSIZE=$(lvdisplay --units B /dev/vg_test/anko | awk '/Size/{print $3}')

echo $DISKSIZE
echo $VOLSIZE

echo "scale=3; $VOLSIZE/$DISKSIZE" | bc