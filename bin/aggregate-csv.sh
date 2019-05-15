#!/bin/bash

for iotype in "write" "read"; do
    for iopattern in "seq" "rand"; do
	(
	    echo -n "I/O size,"
	    cut -d "," -f 2 < without-journaling/rbd-bench.$iotype.$iopattern.csv | paste -s -d ','
	    echo -n 'Without journal,'
	    cut -d "," -f 5 < without-journaling/rbd-bench.$iotype.$iopattern.csv | paste -s -d ','
	    echo -n 'With journal,'
	    cut -d "," -f 5 < with-journaling/rbd-bench.$iotype.$iopattern.csv | paste -s -d ','
	    if [ -d with-mirroring ]; then
		echo -n 'With mirroring,'
		cut -d "," -f 5 < with-mirroring/rbd-bench.$iotype.$iopattern.csv | paste -s -d ','
	    fi
	) > aggregate/iops-$iotype-$iopattern.csv
	(
	    echo -n "I/O size,"
	    cut -d "," -f 2 < without-journaling/rbd-bench.$iotype.$iopattern.csv | paste -s -d ','
	    echo -n 'Without journal,'
	    cut -d "," -f 6 < without-journaling/rbd-bench.$iotype.$iopattern.csv | paste -s -d ','
	    echo -n 'With journal,'
	    cut -d "," -f 6 < with-journaling/rbd-bench.$iotype.$iopattern.csv | paste -s -d ','
	    if [ -d with-mirroring ]; then
		echo -n 'With mirroring,'
		cut -d "," -f 6 < with-mirroring/rbd-bench.$iotype.$iopattern.csv | paste -s -d ','
	    fi
	) > aggregate/throughput-$iotype-$iopattern.csv
  done
done
