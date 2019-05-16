<!-- .slide: data-timing="1" -->
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


<!-- .slide: data-timing="1" -->
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


## Benchmarks with mirroring

<!-- Note -->
Here are some benchmarks with mirroring enabled. These were taken on
virtual machines, with FileStore no less, thus the absolute numbers
are *completely* irrelevant, but the relative comparison
vs. non-journaled and journaled but unmirrored devices should still be useful.


<!-- .slide: data-timing="1" -->
### Sequential read throughput
(Bytes/s in terms of I/O size)
<canvas data-chart="line" data-chart-src="benchmarks/vms/csv/aggregate/throughput-read-seq.csv"></canvas>


<!-- .slide: data-timing="1" -->
### Random read throughput
(Bytes/s in terms of I/O size)
<canvas data-chart="line" data-chart-src="benchmarks/vms/csv/aggregate/throughput-read-rand.csv"></canvas>


<!-- .slide: data-timing="1" -->
### Sequential read IOPS
(IOPS in terms of I/O size)
<canvas data-chart="line" data-chart-src="benchmarks/vms/csv/aggregate/iops-read-seq.csv"></canvas>


<!-- .slide: data-timing="1" -->
### Random read IOPS
(IOPS in terms of I/O size)
<canvas data-chart="line" data-chart-src="benchmarks/vms/csv/aggregate/iops-read-rand.csv"></canvas>


<!-- .slide: data-timing="1" -->
### Sequential write throughput
(Bytes/s in terms of I/O size)
<canvas data-chart="line" data-chart-src="benchmarks/vms/csv/aggregate/throughput-write-seq.csv"></canvas>


<!-- .slide: data-timing="1" -->
### Random write throughput
(Bytes/s in terms of I/O size)
<canvas data-chart="line" data-chart-src="benchmarks/vms/csv/aggregate/throughput-write-rand.csv"></canvas>


<!-- .slide: data-timing="1" -->
### Sequential write IOPS
(IOPS in terms of I/O size)
<canvas data-chart="line" data-chart-src="benchmarks/vms/csv/aggregate/iops-write-seq.csv"></canvas>


<!-- .slide: data-timing="1" -->
### Random write IOPS
(IOPS in terms of I/O size)
<canvas data-chart="line" data-chart-src="benchmarks/vms/csv/aggregate/iops-write-rand.csv"></canvas>


<!-- .slide: data-background-color="#121314" data-timing="-1" -->
## Qemu boot on left <!-- .element: class="hidden" -->

<iframe src="https://asciinema.org/a/WB3hiOcOuDRTc8hrIdtSjS05v/embed?size=big&rows=19&cols=80&theme=tango" class="stretch"></iframe>


<!-- .slide: data-background-color="#121314" data-timing="-1" -->
## Qemu boot on right <!-- .element: class="hidden" -->

<iframe src="https://asciinema.org/a/VUmpUVswYtwjRKARunoNKWW3k/embed?size=big&rows=19&cols=80&theme=tango" class="stretch"></iframe>
