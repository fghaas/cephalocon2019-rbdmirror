#!/bin/bash

for iotype in "write" "read"; do
    for iopattern in "seq" "rand"; do
	grep -E "^(bench|elapsed:)" rbd-bench.$iotype.$iopattern.txt \
	    | paste -sd ' \n' \
	    | sed -e 's/ \+/ /g' \
	    | cut -d " " -f 3,11,5,15,17,19 \
	    | tr " " "," > rbd-bench.$iotype.$iopattern.csv
  done
done
