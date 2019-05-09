# Geographical Redundancy with rbd-mirror
Best practices, performance recommendations, and pitfalls

* * *

Florian Haas | [@xahteiwi](https://twitter.com/xahteiwi)

Cephalocon 2019 | 2019-05-20

<!-- Note --> 

rbd-mirror was introduced in the Ceph Jewel release, and it is a means
of asynchronously replicating RADOS block device (RBD) content to a
remote Ceph cluster.

That's all fair and good, but how do I use it?

* How exactly does the rbd-mirror daemon work?
* What's the difference between one-way and two-way mirroring?
* What authentication considerations apply?
* How do I deploy rbd-mirror in an automated fashion?
* How is mirroring related to RBD journaling?
* How does that affect RBD performance? 
* How do I integrate my mirrored devices into a cloud platform like
  OpenStack, so I can achieve true site-to-site redundancy and
  disaster recovery capability for persistent volumes?

This talk gives a run-down of the ins and outs of RBD mirroring,
suggests best practices to deploy it, outlines performance
considerations, and highlights pitfalls to avoid along the way.

My name is Florian, I’ve worked with Ceph since about 2012, and my
Twitter handle is here on this slide, and also on all other slides in
the bottom-right corner. If you have questions, please feel free to
tweet them, include my handle, and if time permits, I’ll be happy to
get to your question during the talk — if not, I’ll reply to your
question directly on Twitter, afterwards.


## What’s this good for?

<!-- Note -->
RBD mirroring serves the purpose of **asynchronously** replicating
data from one Ceph cluster to another. Now to understand how and why
that is useful, we’ll have to back up a bit and look at how
replication in a Ceph cluster *normally* works.


<!-- .slide: data-background-image="images/cluster-replication.svg" data-background-size="contain" -->
## Standard Ceph replication <!-- .element: class="hidden" --> 

<!-- Note -->
As an application writes data to a Ceph cluster, it always talks to a
single OSD (the **primary OSD**), which then takes care of replicating
the write to the other, non-primary OSDs. Until that write is
completed on *all* OSDs, the application considers it not completed at
all. This is what we refer to as **synchronous** replication.

Synchronous replication is, inherently, latency-critical. If just one
OSD is slow, or slow *to get to*, then that potentially holds up your
entire application. This is why, with very few and clearly delineated
exceptions, you should not attempt to do something like this:


<!-- .slide: data-background-image="images/stretched-cluster-1.svg" data-background-size="contain" -->
## Stretched cluster (narrow) <!-- .element: class="hidden" --> 

<!-- Note -->
This approach is known as “stretched cluster” and means that you’re
operating a single Ceph cluster, stretched across several
geographically separated locations or “sites.” You should only do this
if you have full control over your site-to-site links, and you can
ensure that your latency stays within reasonable limits.


<!-- .slide: data-background-image="images/stretched-cluster-2.svg" data-background-size="contain" -->
## Stretched cluster (wide) <!-- .element: class="hidden" --> 

<!-- Note -->
Building stretched clusters for Ceph is, however, impossible once the
speed of light becomes your problem. 

Even in a theoretically perfect environment where **no** additional
latency exists other than the latency of light to travel between two
locations, 1 light-millisecond is a meager 299.8 kilometers. That
means if your cluster locations are just 300 km apart, your latency
increases tenfold versus a local Ethernet LAN. For 3000 km (a distance
from here to Cairo) it’s 100-fold.

So clearly, that’s not an option if you want to replicate your Ceph
data on a continental, let alone intercontinental scale.


<!-- .slide: data-background-image="images/multiple-clusters.svg" data-background-size="contain" -->
## Multiple distributed Ceph clusters <!-- .element: class="hidden" --> 

<!-- Note -->
So this is why, for long-distance replication, we must take a
different approach. And that is, we’re not doing replication at the
low, RADOS level, from OSD to OSD, but instead we’re doing it one
level up, at one of the abstraction layers *on top of* RADOS. And,
importantly, we’re doing the replication **asynchronously.**

Now the first such Ceph application that got asynchronous replication
capability *wasn’t* RBD, it was RADOS Gateway (rgw). In Ceph Dumpling
(0.67, 2013) we got *Federated Gateways,* and then in Jewel (10.2,
2016), it was reimplemented as *Multi-Site RGW*. 

RADOS Gateway, however, deals only with RESTful object data, and we
needed something to also replicate RBD block data, which we got also
in Jewel: RBD mirroring.

So, what we’d like to get is an RBD image whose changes are
*asynchronously* applied in a remote location. To get that capability,
we need to *track and record* those changes in the first place. To do
that, we use an RBD feature called **journaling.**