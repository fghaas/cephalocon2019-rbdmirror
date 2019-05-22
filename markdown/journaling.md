# RBD Journaling

<!-- Note -->
Now RBD journaling has nothing — zilch, nada, niente — to do with *OSD
journaling,* which is an implementation detail of the OSD FileStore
implementation, which is obsolete as of BlueStore. RBD journaling is
inherently tied to RADOS Block Device (RBD) and RBD only, and is
independent of the Ceph cluster’s OSD implementation.

The purpose of the RBD journal is to 

> record all writes (data and metadata changes) [to an RBD image] to a
> journal of RADOS objects, preserving a consistent point-in-time
> stream that can be mirrored to other sites.

(from <https://tracker.ceph.com/projects/ceph/wiki/Rbd_journal>)

It landed in the Ceph source tree in [November
2015](https://github.com/ceph/ceph/pull/6034).


<!-- .slide: data-background-image="images/rbd-journal.svg" data-background-size="contain" -->
## Journaling overview diagram <!-- .element: class="hidden" --> 

<!-- Note -->
Here’s — roughly — how RBD journaling works. Once the journaling
feature is enabled on an image, all writes go to both the original
image, and to a separate set of RADOS objects that record all
modifications to the image, chronologically.

That journal can then be consumed by a daemon, which — again,
chronologically — applies the journaled changes to a *different* RBD
image.

Note that as of today, RBD journaling is a `librbd`-only feature;
client-side journaling support [has yet to
land](https://patchwork.kernel.org/cover/10857021/) in the `rbd.ko`
kernel driver.


## Enabling journaling on an existing image <!-- .element: class="hidden" --> 

```
rbd feature enable <pool>/<image> journaling
```

<!-- Note --> 
Journaling is not enabled by default on RBD images (except if you
configure the `rbd_image_features` option to include it); either you
or something acting on your behalf must enable it. The `rbd` utility
allows you to do that with `rbd feature enable`.


## Enabling journaling on a new image <!-- .element: class="hidden" --> 

```
rbd create \
  --image-feature exclusive-lock,journaling \
  --size <size> \
  <pool>/<image>
```
```
rbd import \
  --image-feature exclusive-lock,journaling \
  <file> \
  <pool>/<image>
```

<!-- Note --> 
You can, of course, also enable journaling in the course of *creating*
the image in the first place. To do so, you’d use either `rbd create` or
`rbd import` with the `--image-feature` flag. You’ll need to specify
the `journaling` feature itself, and the `exclusive-lock` feature that
it depends upon.

Note that `--image-feature` overrides the default feature set, so with
the commands shown here you’ll *only* get `journaling` and
`exclusive-lock`. You *probably* want to really set `--image-feature
layering,exclusive-lock,object-map,fast-diff,deep-flatten,journaling`
instead (omitted here for brevity).


<!-- .slide: data-background-color="#121314" data-timing="30" -->
## rados output for journal-enabled RBDs <!-- .element: class="hidden" -->

<iframe src="https://asciinema.org/a/DZkygWMvsZTvL19ZcYodJLyBf/embed?size=big&rows=19&cols=80&theme=tango" class="stretch"></iframe>

<!-- Note --> 
Here’s what happens if you enable journaling: 

* You create or import an image with journaling enabled (in this case
  we import),
* then you can use `rbd info` to read back that the feature is indeed
  enabled,
* and if we then list the RADOS objects belonging to that image, we
  see header and data and object-map objects as usual, *and also*
  journal objects.


<!-- .slide: data-background-color="#121314" data-timing="30" -->
## rados output for journal-disabled RBDs <!-- .element: class="hidden" -->

<iframe src="https://asciinema.org/a/OUQEOvsLCj4fKXqz5JMbpQk3Y/embed?size=big&rows=19&cols=80&theme=tango" class="stretch"></iframe>

<!-- Note --> 
And disabling journaling is just as easy:

* You use `rbd feature disable` to turn journaling off,
* then you can use `rbd info` to verify that the feature is now
  disabled,
* and when you rerun your listing of RADOS objects associated with the
  image, you’ll notice that the journal objects are gone, and only the
  data and header and object-map objects remain.

I should perhaps reiterate at this point that there is no server-side
magic that’s happening here, it’s just `librbd` that writes both types
of objects.
