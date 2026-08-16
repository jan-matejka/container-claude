#########
Changelog
#########

2026-08-16
##########

Goal
====

Let the sandboxed claude container (hardened: ``cap_drop: ALL``,
``read_only``, ``no-new-privileges``, rootless ``keep-id`` userns) build and
run containers without weakening that hardening, by delegating execution to
a separate, network-isolated, disposable VM's podman over SSH.

Architecture & files
=====================

- ``Containerfile``: install ``podman`` and ``openssh-client`` in the
  final image stage.
- ``compose.yaml``: ``CONTAINER_HOST``/``CONTAINER_SSHKEY`` environment
  variables (from ``.env``'s ``CLAUDE_REMOTE_PODMAN``/``CLAUDE_SSH_KEY``),
  read-only mounts for the SSH key, a repo-local ``known_hosts``, and the
  host's ``/etc/hosts`` (for resolving the VM's hostname inside this
  container's own network namespace).
- ``.containerignore``: exclude ``.git`` and ``.env`` from the build
  context shipped to the VM.
- ``.env``: cleaned up -- stray unprefixed ``REMOTE_PODMAN`` entry
  removed, leaving just ``CLAUDE_REMOTE_PODMAN``/``CLAUDE_SSH_KEY``.

Build/run pipeline -- confirmed working end to end
=====================================================

Debugged through: empty-directory ``known_hosts`` mount, DNS resolution
failure for the VM's hostname, ``CONTAINER_SSHKEY`` needing to be set
explicitly (podman's native Go SSH client does not fall back to default
identity file locations the way the system ``ssh`` client does), a
``compose.yaml`` environment-list syntax bug, and a repeatedly stale
``/etc/hosts`` in this container after host-side edits (bind mounts are
inode-based; atomic file replacement leaves the mount pointing at the old,
unlinked file, requiring a container restart to pick up the current
content). Final verified state: ``podman build`` tags the image
successfully and ``podman run --rm claude true`` exits ``0``.

SSH key hardening on the VM
=============================

First attempt (``restrict,permitopen="unix:PATH",command="/bin/false"``)
was wrong -- verified against ``sshd(8)`` that ``permitopen`` only
supports ``host:port`` pairs, never Unix-domain sockets, and there is no
per-key mechanism in stock OpenSSH to scope streamlocal forwarding to one
socket path. The deployed restriction --
``restrict,port-forwarding,command="/bin/false"`` -- disables
pty/agent/X11-forwarding and ``~/.ssh/rc`` via ``restrict``, forces any
shell/exec attempt to fail via ``command``, and selectively re-enables
only port forwarding. This does not add any real security by itself:
once forwarding reaches the podman socket, the key can start arbitrary
(including privileged, filesystem-mounting) containers on the VM,
equivalent to full control of it. The VM's own network isolation is what
actually bounds the blast radius, not the key's options.

VM network isolation
======================

Dedicated libvirt network ``sandbox`` (``virbr-sandbox``,
``192.168.150.0/24``) instead of the shared ``default`` network, with
``/etc/libvirt/hooks/network`` driving a shared, ``ACTION``-parameterised
rule list (``-I`` on ``started``, ``-D`` on ``stopped``) that:

- rejects VM-sourced traffic to ``10.0.0.0/8``, ``172.16.0.0/12``,
  ``192.168.0.0/16``, and ``169.254.0.0/16``;
- accepts VM to gateway traffic on UDP 53/67/68 (DNS/DHCP) -- this
  carve-out fixed a bug where the private-range block was catching the
  gateway's own DNS/DHCP replies, since ``192.168.150.1`` falls inside
  the blocked ``192.168.0.0/16`` range;
- accepts ``ESTABLISHED,RELATED`` so return traffic for connections
  initiated *into* the VM (e.g. from this container, source
  ``10.89.0.11``, itself inside a blocked range) still works;
- cleans itself up on ``stopped`` so rules do not accumulate across
  network restarts.

The host's ``FORWARD`` chain default policy was also set to ``DROP``
(host-wide, not scoped to ``sandbox``); re-verified the build/run
pipeline still works afterward, since libvirt's own explicit ``ACCEPT``
rules for the network keep matching regardless of the chain's default
policy. Podman's own container networking was not re-verified against
this change and is accepted as a known risk to revisit if it surfaces.

Separately, SSH connectivity into the VM was fixed at one point by a full
``systemctl restart libvirtd`` -- root cause never fully pinned down,
most likely iptables rule-ordering/state drift from the amount of manual
editing done on this host (including one accidental ``LIBVIRT_FWI`` chain
deletion, since fixed).

Host firewall
==============

Default-deny ``INPUT`` policy on both ``iptables`` and ``ip6tables``,
with explicit allows for loopback, established/related connections,
rate-limited ICMP, SSH, and DNS/DHCP scoped to the ``sandbox`` and
``default`` libvirt bridges. The ``ip6tables`` side matters because the
host itself has real, routable IPv6 connectivity even though the bridges
are IPv4-only by design -- so it is protecting a live exposure, not just
forward-looking prep. Persisted across reboot via ``iptables-persistent``.

VM: IPv6 disabled at the kernel level
========================================

Chosen over the sysctl/NetworkManager alternatives, since it leaves no
window where Neighbor Discovery or link-local activity happens before
userspace configuration would otherwise catch it.

Status
=======

Full pipeline -- sandboxed outer container, SSH, isolated and firewalled
VM, podman -- verified working, with host and VM firewalls both in place
and persisted. ``README.rst`` updated to match the corrected SSH key
restriction and its accompanying security caveat.
