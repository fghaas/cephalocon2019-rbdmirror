# Cloud integration

<!-- Note --> 
So finally, some thoughts on integration of rbd-mirror with cloud
applications, and since I only have a few minutes left and consider
myself qualified to talk about OpenStack more than any other cloud
platform, that is what I’ll cover.


## Cinder replication

```ini
[ceph]
...
replication_device = backend_id:secondary,
                     conf:/etc/ceph/secondary.conf,
                     user:cinder,
                     pool:volumes
```

<!-- Note --> 
So first up, in OpenStack the definition is that any persistent data
needs to go into a volume and thus, in reverse, everything that is
*not* in a volume is, by definition, ephemeral. So really, the only
user-generated data that’s permanently being modified, by users, is in
Cinder.

And in Cinder, we have the concept of
[replication](https://docs.openstack.org/cinder/rocky/contributor/replication.html),
which you must define by adding a `replication_device` stanza to your
Cinder backend configuration. This is totally supported for the RBD
driver, so you **can** have Cinder interface with `rbd-mirror` managed
volumes.

This is somewhat under-documented (though
[this](https://gist.github.com/jbernard/1d7359cac7641216659066b3860760d6)
and
[this](https://www.sebastien-han.fr/blog/2017/06/19/OpenStack-Cinder-configure-replication-api-with-ceph/)
are good starting points), but generally this works — in such a way
that your OpenStack environment can use a primary and a standby Ceph
cluster.


## Does this get me full automated DR capability?

No.  <!-- .element: class="fragment" -->

<!-- Note --> 
Some people claim that with this, you can build a fully automated
DR-capable OpenStack environment.

To wit, an OpenStack environment where you can lose an entire site,
and you can then, within a reasonable timeframe (let’s say an hour)
bring all of the VMs and resources up in another site, without any
intervention from end users.

(A variation thereof is to bring all of the **volume-backed** VMs and
resources up in the other site, which would be a reasonable
restriction.)

I maintain that this is handwaving, and I have yet to see it work,
anywhere (but I’ll be happy to stand corrected). Because:


## OpenStack cluster and colocated Ceph cluster failure <!-- .element: class="hidden" -->

<!-- Note --> 

Frequently, however, at least one of your Ceph clusters is co-located
with an OpenStack cluster, so if this happens (namely some major issue
taking out **both** your OpenStack cluster and the locally attached
Ceph cluster — think a plane crash, or flooding), then you have your
data in another site, but no way to restore service.


## OpenStack cluster and colocated Ceph cluster failure (with full redundancy) <!-- .element: class="hidden" -->

<!-- Note --> 

And even if you **do** have OpenStack in one site *and* the other, and
a Ceph cluster (with replicated data) in both, then there will still
be no automated failover unless you also replicate your OpenStack
*metadata*.

Having, say, a mirrored volumed named
`volumes/volume-78e176f2a66a4b1a9e0d08c2ba17fa18` in a pool isn’t
going to help you lots if you are lacking all the metadata related to
the volume with the UUID 78e176f2a66a4b1a9e0d08c2ba17fa18 (including
its attachment data).


## Semi-automated?

Yes, sort of.  <!-- .element: class="fragment" -->

If you design really well.  <!-- .element: class="fragment" -->

From the get-go.  <!-- .element: class="fragment" -->

<!-- Note --> 
So can I do this? Is there any way at all? Well yes, and with
rbd-mirror, but most likely not with Cinder volume replication.

Now to be fair, what follows is **also** handwaving, because I have
not implemented this in production, but it’s the only way that I can
**imagine** this works.

But you’d have to do this from the start, when you first stand up an
OpenStack environment, and you’d have to get it right immediately —
there’s practically no way to add this as an afterthought.


<!-- .slide: data-background-image="images/multisite-openstack-database.svg" data-background-size="contain" data-timing="15" -->
## OpenStack Integration: Cinder AZs and pool-level mirroring <!-- .element: class="hidden" -->

<!-- Note --> 
This is your checklist:

* You need one logical database, that spans all locations. Either you
  run 2 OpenStack/Ceph sites, and a third one with just Galera, or you
  run 3 sites anyway, in the first place.


<!-- .slide: data-background-image="images/multisite-openstack-api.svg" data-background-size="contain" data-timing="15" -->

<!-- Note --> 
* You need all OpenStack API services in all locations. 
* You’ll also need AZs by site for Nova, Cinder, and Neutron.


<!-- .slide: data-background-image="images/multisite-openstack-routers.svg" data-background-size="contain" data-timing="15" -->

<!-- Note --> 
* You need compute nodes, and network gateway nodes plus independent
  provider uplinks in all locations, plus a dynamic routing protocol
  like BGP so you can arbitrarily announce routable IP addresses
  either here or there.


<!-- .slide: data-background-image="images/multisite-openstack-l3.svg" data-background-size="contain" data-timing="15" -->

<!-- Note --> 
* You need management, tenant/tunnel, and storage L3 connectivity
  between all locations.


<!-- .slide: data-background-image="images/multisite-openstack-ceph.svg" data-background-size="contain" data-timing="15" -->

<!-- Note --> 
* Nova, Glance, and Cinder must all be wired up with their **local**
  Ceph cluster.


<!-- .slide: data-background-image="images/multisite-openstack-rbdmirror.svg" data-background-size="contain" data-timing="15" -->

<!-- Note --> 
* You must set up two-way, pool-level replication for your Nova,
  Glance, and Cinder pools, and you must auto-enable journaling on all
  RBD images created in these pools.

* And then you must have automated scripting in place so that, when
  one site goes down, everything linked to that AZ is reassigned to a
  different one.
