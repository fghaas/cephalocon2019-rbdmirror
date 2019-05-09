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

You can, of course, also enable journaling in the course of *creating*
the image in the first place. To so, use:

```
rbd create \
  --image-feature exclusive-lock,journaling \
  --size <size> \
  <pool>/<image>
```


## rados output for journal-enabled RBDs <!-- .element: class="hidden" --> 

```
```

<!-- Note --> 
Once journaling is enabled, writes on the device result in both data
and journal objects in the RBD pool. I should perhaps reiterate at
this point that there is no server-side magic that’s happening here,
it’s just `librbd` that writes both types of objects.
