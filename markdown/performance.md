<!-- .slide: data-timing="20" -->
# Performance considerations

<!-- Note -->
About the performance implications of RBD mirroring, there’s good news
and bad news:

* Good news: RBD mirroring doesn’t have a major impact on an
  image’s performance.
* Bad news: Journaling, unfortunately, *absolutely* does, and since we
  can’t have mirroring without journaling that is something to take
  into consideration.


<!-- .slide: data-timing="55" -->
## `rbd bench`

Single 1GB RBD image (4MB objects) <!-- .element: class="fragment" -->

All-SSD BlueStore Ceph Luminous cluster <!-- .element: class="fragment" -->

Data pool == journal pool <!-- .element: class="fragment" -->

16 threads <!-- .element: class="fragment" -->

Sequential & random <!-- .element: class="fragment" -->

Read & write <!-- .element: class="fragment" -->

I/O size from 4K to 4M <!-- .element: class="fragment" -->

<!-- Note -->
The data on the following slides is from `rbd bench` runs, all done

* against a single 1-GB RBD image with the default `order` of 22,
  meaning 4-MB objects,
* running on an all-SSD BlueStore Ceph Luminous cluster
* with the journal objects in the same pool as the data objects.
* The `rbd bench` runs all used the default of 16 I/O threads,
* and were run in sequential and random 
* read and write mode, 
* with the I/O size varying in powers of 2 — from 4K to 4M.

It’s important to understand that *none* of the absolute numbers in
these results should be considered dependable benchmarks that you can
compare to your own cluster, and indeed they may differ wildly based
on the hardware you employ and the Ceph version you run. My point is
to show the impact that journaling has in relative terms, vs. running
non-journaled RBD.


### Sequential read throughput
(Bytes/s in terms of I/O size)
<canvas data-chart="line" data-chart-src="benchmarks/hardware/csv/aggregate/throughput-read-seq.csv"></canvas>

<!-- Note -->
Now what you see on all these charts is the I/O size on the x axis,
going on a scale of powers of two, from 4-kilobyte I/O on the extreme
left, to 4-megabyte I/O on the extreme right. And the y axis, which is
linear, has either bytes per second if we’re dealing with throughput,
or IOPS if it’s IOPS that we’re looking at. And the black line is what
we get without journaling, the red line is with journaling enabled.

Now again: good news first: there’s very little impact that RBD
journaling has on image reads, thus read-heavy workloads shouldn’t
expect to suffer badly when RBD journaling is enabled. This is true
for the throughput of sequential reads, ... 


<!-- .slide: data-timing="15" -->
### Random read throughput
(Bytes/s in terms of I/O size)
<canvas data-chart="line" data-chart-src="benchmarks/hardware/csv/aggregate/throughput-read-rand.csv"></canvas>

<!-- Note -->
... the throughput of random reads, ...


<!-- .slide: data-timing="15" -->
### Sequential read IOPS
(IOPS in terms of I/O size)
<canvas data-chart="line" data-chart-src="benchmarks/hardware/csv/aggregate/iops-read-seq.csv"></canvas>

<!-- Note -->
... and also read latency, and hence IOPS, are not extremely heavily
impacted by journaling, whether we’re dealing with sequential ...


<!-- .slide: data-timing="15" -->
### Random read IOPS
(IOPS in terms of I/O size)
<canvas data-chart="line" data-chart-src="benchmarks/hardware/csv/aggregate/iops-read-rand.csv"></canvas>

<!-- Note -->
... or random read IOPS.


<!-- .slide: data-timing="45" -->
### Sequential write throughput
(Bytes/s in terms of I/O size)
<canvas data-chart="line" data-chart-src="benchmarks/hardware/csv/aggregate/throughput-write-seq.csv"></canvas>

<!-- Note -->
With writes, however, we’re really in for a bit of an unpleasant
surprise.

Now generally, if we’re writing our data and journal objects to the
same pool, and we are in this case, then we’re sort of assuming our
throughput to be roughly halved, because we’re writing everything
twice.

And that is true for large-ish I/O sizes, as we can see here on the
right-hand side of the chart where we’re in 128K to 4M per write
territory, but for small writes the overhead is truly astounding — yes
that *is* really a factor of 10 for 4K writes. My untested hypothesis
for this is that the partial RADOS object writes (4K writes on 4M
objects) that `librbd` needs to do here play really badly with
journaling.


<!-- .slide: data-timing="15" -->
### Random write throughput
(Bytes/s in terms of I/O size)
<canvas data-chart="line" data-chart-src="benchmarks/hardware/csv/aggregate/throughput-write-rand.csv"></canvas>

<!-- Note -->
The same pattern expectedly manifests itself for random write
throughput.


<!-- .slide: data-timing="15" -->
### Sequential write IOPS
(IOPS in terms of I/O size)
<canvas data-chart="line" data-chart-src="benchmarks/hardware/csv/aggregate/iops-write-seq.csv"></canvas>

<!-- Note -->
For sequential write IOPS, we’re also seeing that nine-tenths
reduction for small writes.


<!-- .slide: data-timing="15" -->
### Random write IOPS
(IOPS in terms of I/O size)
<canvas data-chart="line" data-chart-src="benchmarks/hardware/csv/aggregate/iops-write-rand.csv"></canvas>

<!-- Note -->
And again for random writes, it looks just a little less than what
you’d intuitively expect, but it’s still quite significant for small
writes.


<!-- .slide: data-timing="45" -->
## Performance impact takeaway <!-- .element: class="hidden" -->
Enable journaling selectively and for good reasons. <!-- .element: class="fragment" -->

Don’t do it globally or on a whim. <!-- .element: class="fragment" -->

<!-- Note -->
Now I’ll humbly suggest this takeway:

* If you have *good* reasons for enabling journaling on your devices,
  such as *selectively* mirroring individual volumes, and you have
  weighed those expected benefits against the performance implications
  that I just talked about, then by all means go ahead and do so —
  again, selectively.
* But don’t, under any circumstances, enable it globally or just on a
  whim, because it’s likely that your users and customers will hate
  you for it.

Again, I need to reiterate that these benchmarks were all run against
Luminous on one specific set of hardware, but if you look up my slides
after the talk, you’ll find my benchmark scripts that I built these
charts with, and you can go ahead and reproduce (or refute) these
findings on your own systems.
