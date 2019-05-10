# One-way and two-way mirroring

<!-- Note --> 
In one-way mirroring, there’s `rbd-mirror` daemons in only one
cluster.

In two-way mirroring, we have two separate Ceph clusters, **each**
with an `rbd-mirror` daemon of its own, and the ability to replicate
either in one direction, or the other.


<!-- .slide: data-background-image="images/primary.svg" data-background-size="contain" -->
## One-way replication <!-- .element: class="hidden" -->

<!-- Note --> 
So this configuration (which we’ve seen before, with only one
`rbd-mirror` in the `right` site) becomes...


<!-- .slide: data-background-image="images/two-way-ltr.svg" data-background-size="contain" -->
## Two-way replication (left to right) <!-- .element: class="hidden" -->

<!-- Note --> 
... this, where we have an `rbd-mirror` in both locations.

Thus, **any image** can replicate either from `left` to `right` (in
which case it is *primary* on `left` and *non-primary* on `right`), as
before, or...


<!-- .slide: data-background-image="images/two-way-rtl.svg" data-background-size="contain" -->
## Two-way replication (right to left) <!-- .element: class="hidden" -->

<!-- Note --> 
... it can replicate from `right` to `left` (in which
case it is *non-primary* on `left` and *primary* on `right`).


## Promotion and demotion

<!-- Note --> 
Flipping an image’s direction of replication (and thus, its *primary*
vs. *non-primary* state) is called

* **promotion** (where an non-primary image is made primary, meaning
  it was previously a replication target and is now a replication
  source);
* **demotion** (where an primary image is made non-primary, meaning
  it was previously a replication source and is now a replication
  target).
