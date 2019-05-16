<!-- .slide: data-timing="90" -->
# Geographical Redundancy with rbd-mirror
Best practices, performance  
recommendations, and pitfalls

* * *

Florian Haas | [@xahteiwi](https://twitter.com/xahteiwi)

Cephalocon 2019 | 2019-05-20

<!-- Note --> 
rbd-mirror is a Ceph feature that’s been around for 3 years — since
the Jewel release — as a means of asynchronously replicating RADOS
block device (RBD) content to a remote Ceph cluster.

That's all fair and good, I hear you cry, but how do I use the damn
thing?

* How exactly does the rbd-mirror daemon work?
* What's the difference between one-way and two-way mirroring?
* What authentication considerations apply?
* How do I deploy rbd-mirror in an automated fashion?
* How is mirroring related to RBD journaling?
* How does that affect RBD performance? 
* How do I integrate my mirrored devices into a cloud platform like
  OpenStack, so I can achieve true site-to-site redundancy and
  disaster recovery capability for persistent volumes?

Well it’s great you asked, because that’s what this talk is about.
I’m about to give you a run-down of the ins and outs of RBD mirroring,
I’ll suggests best practices to deploy it, I’ll outline performance
considerations, and I’ll try to highlight traps and pitfalls to avoid
along the way.

My name is Florian, I’ve worked with Ceph since about 2012, and my
Twitter handle is here on this slide, and also on all other slides in
the bottom-right corner. If you have questions, please feel free to
tweet them, include my handle, and if time permits, I’ll be happy to
get to your question during the talk — if not, I’ll reply to your
question directly on Twitter, afterwards.


<!-- .slide: data-timing="15" -->
## RBD mirroring

... asynchronously replicates RBD data  
from one Ceph cluster to another. <!-- .element: class="fragment" --> 

<!-- Note -->
What’s RBD mirroring good for? RBD mirroring serves the purpose of

* **asynchronously** replicating RADOS Block Device (RBD) data from
one Ceph cluster to another.

Now to understand how and why that is useful, we’ll have to back up a
bit and look at how replication in a Ceph cluster *normally* works.


<!-- .slide: data-background-image="images/osd-replication.svg" data-background-size="contain" -->
## Standard Ceph replication <!-- .element: class="hidden" --> 

<!-- Note -->
As an application writes data to a Ceph cluster, it always talks to a
single OSD (the **primary OSD**), which then takes care of replicating
the write to the other, non-primary OSDs. 

Consider the flying blue balls here representing I/O in flight: as
long as it’s not completed — turned green — *and reported as
such* from all OSDs, the application considers it not completed at all
and remains blue. Only when an acknowledgment from all OSDs has
arrived does the client consider the write operation complete, and
turns green itself.

This is what we refer to as **synchronous** replication.


<!-- .slide: data-background-image="images/osd-replication-slow.svg" data-background-size="contain" -->
## Slow OSD <!-- .element: class="hidden" --> 

<!-- Note -->
Synchronous replication is, inherently, latency-critical. If just one
OSD is slow, or slow *to get to*, then that potentially holds up your
entire application.

This is why, with very few and clearly delineated exceptions, you
should not attempt to do something like this:


<!-- .slide: data-background-image="images/map.svg" data-background-size="cover" -->
## Stretched cluster <!-- .element: class="hidden" --> 

<!-- Note -->
This approach is known as “stretched cluster” and means that you’re
operating a single Ceph cluster, stretched across several
physically separated locations or “sites.” 

You should only do this if you have full control over your
site-to-site links, and you can ensure that your latency stays within
reasonable limits. Normally, this is only true for Ceph clusters where
all nodes are within the same city, **and** where you have dedicated
fiber connections between them.

However, building stretched clusters for Ceph becomes impossible once
you’re having to deal with 𝒄.

* * *

Map of Barcelona: © OpenStreetMap contributors.

OpenStreetMap data is available under the [Open Database
Licence](https://www.opendatacommons.org/licenses/odbl).


<!-- .slide: data-timing="15" -->
# 𝒄
≈ 299 792.5 km/s <!-- .element: class="fragment" --> 

<!-- Note -->
No, that’s not C the programming language, but c as in the speed of light.

Now the scientists and academics in the audience will forgive me the
cheap joke, because in fact we’re obviously talking about the speed of
light not in a vacuum, but in fibre-optic cables, [where it’s more
like 204,190.5
km/s](https://www.quora.com/What-is-precisely-the-speed-of-light-in-fiber-optics/answer/Steve-Blumenkranz).

But:


<!-- .slide: data-timing="60" -->
### Why long-distance Ceph clusters don’t work <!-- .element: class="hidden" --> 

Ethernet RTT ≈ 0.1 ms <!-- .element: class="fragment" --> 

0.1 light-ms (in fibre) ≈ 20 km <!-- .element: class="fragment" --> 

10 km = 20 km round-trip <!-- .element: class="fragment" --> 

100 km ≈ 1 ms light round-trip <!-- .element: class="fragment" --> 

100 km = 10× Ethernet RTT <!-- .element: class="fragment" --> 

1,000 km = 100× Ethernet RTT <!-- .element: class="fragment" --> 

<!-- Note --> 
* Consider that a typical Ethernet round-trip time (ping time) is on
  the order of 100µs or 0.1 milliseconds.

* 0.1 *light*-milliseconds in fibre, that is to say the distance that
  light travels in a glass fibre in that time, is just 20 kilometers,
  or
  
* a round-trip of a link that’s 10 km one-way.

  And that’s assuming a theoretically perfect environment, where
  there’s **no** additional latency, other than that of light
  traveling — in a straight-line fibre-optic link — between the two
  locations. So you can’t ever assume LAN-like latency outside a 10-km
  radius.

* It also means if your cluster sites are just 100 km apart — which
  doesn’t even cover the distance from here to the French border —,
  
* your round-trip time increases tenfold versus a local Ethernet LAN.
  
* For 1000 km (a distance from here to Munich, or Lisbon) it’s
  100-fold.

So clearly, building stretched clusters is not an option if you want
to replicate your Ceph data on a continental, let alone
intercontinental scale.


<!-- .slide: data-background-image="images/multiple-clusters.svg" data-background-size="contain" -->
## RBD Multi-Site Replication <!-- .element: class="hidden" --> 

<!-- Note -->
So this is why, for long-distance replication, we must take a
different approach. And that is, we’re not doing replication at the
low, RADOS level, from OSD to OSD, but instead we’re doing it one
level up, at one of the abstraction layers *on top of* RADOS.

In this case, I am talking about the abstraction layer that’s most
important for virtualization use cases, namely RBD.

And, importantly, we need to be talking about replication that is
**asynchronous,** so we *don’t* have to worry about network latency
anymore.

~Now the first such Ceph application that got asynchronous replication
capability *wasn’t* RBD, it was RADOS Gateway (rgw). RADOS Gateway,
however, deals only with RESTful object data, and we needed something
to also replicate RBD block data, which we got in Jewel: RBD
mirroring.~

So, what we’d like to get is an RBD image whose changes are
*asynchronously* applied in a remote location. To get that capability,
we need to *track and record* those changes in the first place. To do
that, we use an RBD feature called **journaling.**
