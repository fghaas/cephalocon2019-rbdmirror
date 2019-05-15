<!-- .slide: data-timing="15" -->
# Performance considerations

<!-- Note -->
About the performance implications of RBD mirroring, there’s good news
and bad news:

* Good news: RBD mirroring doesn’t have a major impact on an
  image’s performance.
* Bad news: Journaling, unfortunately, *absolutely* does.


<!-- .slide: data-timing="50" -->
## `rbd bench`

Single 1GB RBD image <!-- .element: class="fragment" -->

All-SSD Ceph Luminous cluster <!-- .element: class="fragment" -->

Data pool == journal pool <!-- .element: class="fragment" -->

16 threads <!-- .element: class="fragment" -->

Sequential & random <!-- .element: class="fragment" -->

Read & write <!-- .element: class="fragment" -->

I/O size from 4K to 4M <!-- .element: class="fragment" -->

<!-- Note -->
The data on the following slides is from `rbd bench` writes, all
against a single 1-GB RBD image running on an all-SSD Ceph Luminous
cluster with the journal objects in the same pool as the data
objects. The `rbd bench` runs all used the default of 16 I/O threads,
and were run in sequential and random read and write mode, with the
I/O size varying in powers of 2 — from 4K to 4M.

It’s important to understand that *none* of the absolute numbers in
these results should be considered dependable benchmarks that you can
compare to your own cluster, and indeed they may differ wildly based
on the hardware you employ and the Ceph version you run. My point is
to show the impact that journaling has in relative terms, vs. running
non-journaled RBD.


<!-- .slide: data-timing="15" -->
### Sequential read throughput
(Bytes/s in terms of I/O size)
<canvas data-chart="line" data-chart-src="benchmarks/csv/aggregate/throughput-read-seq.csv"></canvas>

<!-- Note -->
Now again: good news first: there’s very little impact that RBD
journaling has on image reads, thus read-heavy workloads shouldn’t
expect to suffer badly when RBD journaling is enabled. This is true
for the throughput of sequential reads, ... 


<!-- .slide: data-timing="15" -->
### Random read throughput
(Bytes/s in terms of I/O size)
<canvas data-chart="line" data-chart-src="benchmarks/csv/aggregate/throughput-read-rand.csv"></canvas>

<!-- Note -->
... the throughput of random reads, ...


<!-- .slide: data-timing="15" -->
### Sequential read IOPS
(IOPS in terms of I/O size)
<canvas data-chart="line" data-chart-src="benchmarks/csv/aggregate/iops-read-seq.csv"></canvas>

<!-- Note -->
... and also read latency, and hence IOPS, are not extremely heavily
impacted by journaling, whether we’re dealing with sequential ...


<!-- .slide: data-timing="15" -->
### Random read IOPS
(IOPS in terms of I/O size)
<canvas data-chart="line" data-chart-src="benchmarks/csv/aggregate/iops-read-rand.csv"></canvas>

<!-- Note -->
... or random read IOPS.


<!-- .slide: data-timing="15" -->
### Sequential write throughput
(Bytes/s in terms of I/O size)
<canvas data-chart="line" data-chart-src="benchmarks/csv/aggregate/throughput-write-seq.csv"></canvas>

<!-- Note -->
With writes, however, we’re really in for a bit of an unpleasant
surprise.

Now generally, if we’re writing our data and journal objects to the
same pool, and we are in this case, then we’re sort of assuming our
throughput to be roughly halved, because we’re writing everything
twice.

And that is true for large-ish I/O sizes, as we can see here on the
right-hand side of the chart where we’re in 1M to 4M territory, but
for small writes the overhead is truly significant — yes that *is*
really a factor of 10 for 4K writes, it doesn’t merely look like that.


<!-- .slide: data-timing="15" -->
### Random write throughput
(Bytes/s in terms of I/O size)
<canvas data-chart="line" data-chart-src="benchmarks/csv/aggregate/throughput-write-rand.csv"></canvas>

<!-- Note -->
The same pattern expectedly manifests itself for random write
throughput.


<!-- .slide: data-timing="15" -->
### Sequential write IOPS
(IOPS in terms of I/O size)
<canvas data-chart="line" data-chart-src="benchmarks/csv/aggregate/iops-write-seq.csv"></canvas>

<!-- Note -->
For sequential write IOPS, we’re also seeing that nine-tenths
reduction for small writes.


<!-- .slide: data-timing="15" -->
### Random write IOPS
(IOPS in terms of I/O size)
<canvas data-chart="line" data-chart-src="benchmarks/csv/aggregate/iops-write-rand.csv"></canvas>

<!-- Note -->
And again for random writes, it looks just a little less than what
you’d intuitively expect, but it’s still quite significant for small
writes.


## Performance impact summary <!-- .element: class="hidden" -->

<!-- Note -->
Performance impact summary
