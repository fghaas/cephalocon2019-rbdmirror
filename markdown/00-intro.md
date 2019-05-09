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
