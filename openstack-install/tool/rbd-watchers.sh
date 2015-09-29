#!/bin/bash

name="$1"

volume="volumes/volume-$name"

rbd info $volume
subfix=`rbd info $volume | grep block_name_prefix | awk -F. '{print $2}'`

rados -p volumes listwatchers rbd_header.$subfix
