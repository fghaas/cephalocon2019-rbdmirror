# `rbd-mirror` authentication

<!-- Note --> 
So. We know we need a running `rbd-mirror` that can watch journals on
one cluster, and then replay them on the other. That means that that
daemon needs CephX identities with very specific capabilities on
**both** clusters.

And the first thing that we need to do is create those.


# ceph auth get-or-create <!-- .element: class="hidden" --> 
```
ceph auth get-or-create \
  client.rbd-mirror.{unique id} \
  mon 'profile rbd-mirror' \
  osd 'profile rbd'
```

<!-- Note --> 
This needs to happen on both of (or rather, all of) the clusters
involved in replication.

By giving the `client.rbd-mirror` user the `mon 'profile rbd-mirror'`
and `'osd profile rbd'` capabilities, we ensure that the `rbd-mirror`
instance

* can participate in mirror peer discovery and mutual authentication
  (that’s the `mon` capability),
* can read from and write to RBD images in all pools (that’s the `osd`
  capability).

Now this is the easier part, thanks to [capability
profiles](http://docs.ceph.com/docs/nautilus/rados/operations/user-management/#authorization-capabilities).

What *is* a bit trickier is enabling the rbd-mirror instances to
*find* these authentication credentials, which largely means getting
the keyring locations right.


## Credentials for local cluster

```
ceph auth get \
  client.rbd-mirror.{unique id} \
  > /etc/ceph/ceph.client.rbd-mirror.{unique id}.keyring
```

```bash
/etc/ceph/$cluster.$type.$id.keyring
```

<!-- Note --> 
First, on whatever node(s) you’re going to be running `rbd-mirror`,
the daemon is going to have to be able to access the local
cluster. Thus, it will need to find its keyring in its default
location.

* The default keyring location is
  `/etc/ceph/$cluster.$type.$id.keyring`.

* Your local `$cluster` name is usually (read: almost always) `ceph`.

* And your `rbd-mirror` daemon, just like (for example) `radosgw`,
  acts as a **client** to both clusters it talks to, hence its `$type`
  is `client`.

So, if you want to call your RBD mirror daemon
`rbd-mirror.foo`, then the proper keyring
location to access the **local** cluster is
`/etc/ceph/ceph.client.rbd-mirror.foo.keyring`.

So far, so simple.


## Credentials from remote cluster 
(on `left`)

```ini
# /etc/ceph/right.conf
[global]
mon host = right-mon1, right-mon2, right-mon3
```

```
/etc/ceph/right.client.rbd-mirror.{unique id}.keyring
```

<!-- Note --> 
But your `rbd-mirror` daemon also needs to access the **remote**
cluster, and now here is where it gets mildly complicated.

First, you have to tell `rbd-mirror` where to **find** the remote
cluster. Luckily, this being Ceph, all it needs to know about is the
mon hosts.

So, you can give your `rbd-mirror` node a barebones Ceph client
configuration by dropping another configuration file, which now is
**not** named `ceph.conf` but `<remote cluster name>.conf` — in this
example, `/etc/ceph/right.conf`.

And then, it needs to find the correct keyring *for connecting to that
cluster,* and this follows the same naming convention as before
(`/etc/ceph/$cluster.$type.$id.keyring`), only that `$cluster` is now
not `ceph`, but `right`. So:
`/etc/ceph/right.client.rbd-mirror.{unique id}.keyring`


## Credentials from remote cluster 
(on `right`)

```ini
# /etc/ceph/left.conf
[global]
mon host = left-mon1, left-mon2, left-mon3
```

```
/etc/ceph/left.client.rbd-mirror.{unique id}.keyring
```

<!-- Note --> 
And on the other side of the replication link, you need the mirror
image of what you had earlier.

Meaning: from here, the remote cluster is named `left`, so the
configuration file is `/etc/ceph/left.conf`, and the keyring goes into 
`/etc/ceph/left.client.rbd-mirror.{unique id}.keyring`.

Sounds complicated and it is, but it’s really quite logical.


## This should all work

```bash
# on left
ceph --id rbd-mirror.{unique id} -s
ceph --cluster right --id rbd-mirror.{unique id} -s

# on right
ceph --id rbd-mirror.{unique id} -s
ceph --cluster left --id rbd-mirror.{unique id} -s
```

<!-- Note --> 
If you’re setting up `rbd-mirror` manually (or you’re troubleshooting
authentication issues), then this is how you can verify that mutual
authentication works.

You should always be able to contact the local
`ceph` cluster (and find the keyring in the expected location), and
you should also be able to get to the remote cluster (i.e. from `left`
to `right`, and from `right` to `left`).

If this all works, you’re good to deploy your mirror daemon!
