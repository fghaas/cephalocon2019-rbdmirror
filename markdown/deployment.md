# Deploying `rbd‑mirror`

<!-- Note -->
With all our prerequisites squared away, we can discuss what needs to
happen in order to actually start replicating.

Now, depending on your deployment automation facility, this may be
automated away to various degrees. But it still doesn’t hurt to know
what’s happening under the covers.

The first thing we need is a way to reliably start the `rbd-mirror`
binary.


## `systemd` service

```bash
systemctl enable ceph-rbd-mirror@rbd-mirror.{unique id}
systemctl start ceph-rbd-mirror@rbd-mirror.{unique id}
```

<!-- Note -->

In conventional (non container driven) deployment schemes, the
`rbd-mirror` binary is normally started from `systemd`, and as such, a
`systemd` unit file is deployed with the `rbdmirror` package.

This is how you can enable the `ceph-rbd-mirror` service on a machine
where `rbd-mirror` is managed by `systemd`.


## Foreground daemon

```bash
rbd-mirror --foreground --id rbd-mirror.{unique id}
```

<!-- Note --> 

If you ever would want to manually run `rbd-mirror` in the foreground,
which you almost never have to do, this is how you’d do it.

But it’s also how application containers — such as the Docker
containers that `ceph-ansible` deploys, if you so choose, and the
Kubernetes-managed containers in Rook — invoke the `rbd-mirror`
binary.


## Enable Mirroring

<!-- Note -->
Next, you need to enable mirroring.

Mirroring is not enabled by default in your cluster, and you switch it
on and off for each pool you want mirrored. In doing so, you have two
options:


## Pool-mode mirroring <!-- .element class="hidden" -->

```
rbd mirror pool enable <pool> pool
```

(do this on both clusters)

<!-- Note -->
In **pool-mode** mirroring, **all** images in `<pool>` are
automatically mirrored, as long as they have journaling enabled.


## Image-mode mirroring <!-- .element class="hidden" -->

```
rbd mirror pool enable <pool> image
```

(do this on both clusters)

<!-- Note -->
In **image-mode** mirroring, any images that should be mirrored must

* have journaling enabled,
* additionally be *explicitly* enabled for mirroring with:
  ```
  rbd mirror image enable <pool>/<image>
  ```


## Connect Peers

<!-- Note -->
Next, you’ll have to connect `rbd-mirror` instances to one another.

We collectively refer to `rbd-mirror` instances that are meant to talk
to each other as *peers,* but I’d strongly caution against using the
term “peering” for this process. That will just cause royal confusion
if you’re talking to someone unfamiliar with `rbd-mirror`, but
familiar with [PG
peering](http://docs.ceph.com/docs/nautilus/dev/peering/), which is a
wholly different concept.

So, call it “connecting peers” instead.


## `rbd mirror pool peer add` <!-- .element class="hidden" -->

```bash
# on left
rbd mirror pool peer add <pool> \
  client.rbd-mirror.<id>@right
```
then
```bash
# on left
rbd --cluster right \
  mirror pool peer add <pool> \
  client.rbd-mirror.<id>@left
```

<!-- Note -->
For connecting peers, you have two options: you can to everything from
one host, or you can set up one side on one cluster and the other, on
the other. Which you choose only differentiates in convenience, not in
function — they both achieve the same result.

The first one is shown here, where you do everything on one cluster,
`left`:

1. Talk to the *local* cluster and add the *remote* one, `right`,
   as a peer.
2. Talk to the *remote* cluster, and register the local one as a peer.


## `rbd mirror pool peer add` <!-- .element class="hidden" -->
alternatively:
```bash
# on left
rbd mirror pool peer add <pool> \
  client.rbd-mirror.<id>@right
```
then
```bash
# on right
rbd mirror pool peer add <pool> \
  client.rbd-mirror.<id>@left
```

<!-- Note -->
The second option requires you to shell into both clusters
sequentially.

1. Shell into the `left` cluster and add `right` locally as a peer.
2. Shell into the `right` cluster and add `left` locally as a peer.


## Demotion

```bash
rbd mirror image demote <pool>/<image>
```
```bash
rbd mirror pool demote <pool>
```

<!-- Note -->
Once the clusters are properly connected and replication is active,
you can also influence the direction of your replication.

An image that is currently primary can be demoted to non-primary
status with `rbd mirror image demote`. If you need to demote **all**
images in a pool, you can do so with `rbd mirror pool demote`.


## Promotion

```bash
rbd mirror image promote <pool>/<image>
```
```bash
rbd mirror pool promote <pool>
```

<!-- Note -->
Conversely, an image that is currently non-primary can be promoted to
primary status with `rbd mirror image promote`. If you need to promote
all images in a pool, you can do so with `rbd mirror pool promote`.


<!-- .slide: data-background-color="#121314" data-timing="15" -->
## rbd info on mirrored image <!-- .element: class="hidden" -->

<iframe src="https://asciinema.org/a/lBXz520XopDyZKLJeCYynrXir/embed?size=big&rows=19&cols=80&theme=tango&loop=1" class="stretch"></iframe>


<!-- .slide: data-background-color="#121314" data-timing="15" -->
## rbd mirror status <!-- .element: class="hidden" -->

<iframe src="https://asciinema.org/a/vnN6Krhi5zax4YjJTob7jEiUe/embed?size=big&rows=19&cols=80&theme=tango&loop=1" class="stretch"></iframe>


<!-- .slide: data-background-image="images/site-failure.svg" data-background-size="contain" -->
## Site failure and recovery <!-- .element class="hidden" -->

<!-- Note -->
An image *must* be demoted on one side before it can be promoted on
the other, **except** in the case that its peer is down or
unreachable. 

In that case, you can force promotion with the `--force` option.

However, in case of the peer site subsequently recovering, there is
no automated mechanism to reconcile the image content, and you will
need to resynchronize its contents with `rbd mirror image resync`.


## Deployment Automation

<!-- Note -->
Now with all of what I said about what you need to do in
order to **manually** make `rbd-mirror` work, which of course you
probably won’t want to do, let’s take a quick look at what individual
deployment automation facilities do about `rbd-mirror`.


<!-- .slide: data-timing="140" -->
## Deployment Automation Support <!-- .element class="hidden" -->

|                                  | ceph‑ansible | Juju | DeepSea | Rook
| -------------------------------- | ------------ | ---- | ------- | ----
| Create and deploy local keyrings | ✓            | ✓    | ✗       | ✓
| Fetch remote config and keyrings | ✓ish         | ✓    | ✗       | ?
| Deploy `rbd-mirror` daemon       | ✓            | ✓    | ✗       | ✓
| Connect peers                    | ✓            | ✓    | ✗       | ✗
| Enable, disable, promote, demote | ✗            | ✓    | ✗       | ✗

<!-- Note -->
* **`ceph-ansible`** lets you create and deploy `rbd-mirror`
  credentials, capabilities and keyrings; it deploys the `rbd-mirror`
  daemon, and can automatically connect your cluster to a remote
  one.

  It does also help you with keyring exchange and remote-cluster
  client configuration, so it does give you the tools to fully
  automate an rbd-mirror cluster pair, but [only if you thought to set
  two different cluster names from the
  get-go](https://www.sebastien-han.fr/blog/2016/05/09/Bootstrap-two-Ceph-and-configure-RBD-mirror-using-Ceph-Ansible/).
  (If one of your clusters is already deployed and uses the name
  `ceph`, manual intervention is required.)

  Promotion and demotion of individual images are outside
  `ceph-ansible`’s scope.

* The **Juju** [`ceph-rbd-mirror`
  charm](https://jujucharms.com/ceph-rbd-mirror) can automate the entire
  `rbd-mirror` lifecycle, including key exchange (with `juju
  offer`/`juju consume`), and failover and failback (with `juju
  run-action`).

* [DeepSea](https://github.com/SUSE/DeepSea) currently supports
  support no rbd-mirror automation facilities. However, if you happen
  to be on SUSE Enterprise Storage (SES, which is deployed with
  DeepSea), then your supported RBD Mirroring deployment automation
  facility in SES 6 and later is the included post-Nautilus Ceph
  dashboard.

* [Rook](https://rook.io/docs/rook/master/ceph-storage.html) is
  capable of managing `rbd-mirror` instances and configuring them, but
  currently relies on an administrator running `rbd mirror` commands
  for peer connection and pool and image actions.
