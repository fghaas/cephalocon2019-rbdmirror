<!-- .slide: data-timing="-1" -->
## rbd-bench script <!-- .element: class="hidden" -->

```bash
#!/bin/bash

IMAGE="$1"

for iotype in "write" "read"; do
  for iopattern in "seq" "rand"; do 
    for iosize in 4K 8K 16K 32K 64K 128K \ 
	              256K 512K 1M 2M 4M; do 
      sudo rbd bench --io-type $iotype \
                     --io-pattern $iopattern \
                     --io-size $iosize \
      $IMAGE; done | tee rbd-bench.$iotype.$iopattern.txt
  done
done
```
`rbd bench` script used to get benchmark data

<!-- Note -->
For reference, this is the script that I used to generate the
benchmark data — first against an image with no journaling, then one
with journaling enabled.


<!-- .slide: data-timing="-1" -->
## rbd-bench output to CSV <!-- .element: class="hidden" -->

```bash
for iotype in "write" "read"; do
    for iopattern in "seq" "rand"; do
	grep -E "^(bench|elapsed:)" \
	    rbd-bench.$iotype.$iopattern.txt \
	    | paste -sd ' \n' \
	    | sed -e 's/ \+/ /g' \
	    | cut -d " " -f 3,11,5,15,17,19 \
	    | tr " " "," > rbd-bench.$iotype.$iopattern.csv
  done
done
```
Turns `rbd bench` output into CSV

<!-- Note -->
If you ever find yourself in the position of parsing `rbd bench`
output it to something that a spreadsheet can grok, please feel free
to use this “one”-liner.
