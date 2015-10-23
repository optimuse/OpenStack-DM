#!/bin/bash

#volume_uuid="$1"
#volume="volumes/volume-${volume_uuid}"

volume=$1
pool=${volume%%/*}

rbd info $volume
subfix=`rbd info $volume | grep block_name_prefix | awk -F. '{print $2}'`

rados -p ${pool} listwatchers rbd_header.$subfix
