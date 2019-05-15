#!/bin/bash

IMAGE="$1"

if [ -z "$IMAGE" ]; then
  echo "No image specified" >&2
  exit 1
fi

if sudo rbd info $IMAGE | grep -q "features:.*journaling"; then
    if sudo rbd info $IMAGE | grep -q "mirroring state: enabled"; then
	echo "Image has mirroring enabled" >&2
	directory="with-mirroring"
    else
	echo "Image has journaling enabled" >&2
	directory="with-journaling"
    fi
else
    echo "Image has journaling disabled" >&2
    directory="without-journaling"
fi

for iotype in "write" "read"; do
  for iopattern in "seq" "rand"; do 
    for iosize in 4K 8K 16K 32K 64K 128K 256K 512K 1M 2M 4M; do 
      sudo rbd bench --io-type $iotype \
           --io-pattern $iopattern \
           --io-size $iosize \
	   $IMAGE
    done | tee $directory/rbd-bench.$iotype.$iopattern.txt
  done
done
