#!/bin/bash

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <osd.num>"
  echo "Example: $0 osd.3"
  exit 1
fi

OSD=$1


# Mark the OSD out of the cluster.
ceph osd out $OSD

# Remove the OSD from the cluster.
ceph osd crush remove $OSD

# Remove the OSD authentication key.
ceph auth del $OSD

# Remove the OSD.
ceph osd rm $OSD 

## 
