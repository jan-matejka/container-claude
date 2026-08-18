######################
claude container image
######################

Features
########

- Claude running in container with minimal privileges.
- Persistent claude configuration/authentication.
- Claude has RW access to git worktree.
- Claude has RO access to the git repository itself.
- Claude can run containers in a sandboxed VM.

Requirements
############

- podman (or docker)
- docker/compose

Build
#####

- `podman compose build`

Sandbox VM configuration
########################

- Install podman, docker-compose.
- Create a user for claude to run as.
- Enable the user's podman.socket and `# loginctl enable-linger <user>`.
- Create a ssh key for claude and install the pubkey into the host's
  authorized_keys with options
  ``restrict,port-forwarding,command="/bin/false"``
  [1]_
  (See ``virt-sysprep``).

Local claude container configuration
####################################

Mandatory environment variables:

- ``CLAUDE_REMOTE_PODMAN``

  - The URL to the VM's podman socket
    (e.g.: ``ssh://user@machine/.../podman.sock``)
  - This is consumed by podman itself.

- ``CLAUDE_SSH_KEY``

  - The path to the private ssh key to pass to claude to authenticate with to
    `CLAUDE_REMOTE_PODMAN`.

Optional environment variables:

- ``CLAUDE_CONTAINER_APP``

  - the app workspace for claude. RW mount.
  - Note it is assumed this a worktree.
  - Defaults to ``./``.

- ``CLAUDE_CONTAINER_APP_GIT_DIR``

  - the git dir mounted into claude. RO mount.
  - Defaults to ``../main/.git``.

- ``CLAUDE_CONTAINER_CONFIG``

  - config volume for claude.

- ``CLAUDE_CONTAINER_DATA``

  - data volume for claude.

- ``CLAUDE_KNOWN_HOSTS``

  - Location of known_hosts for claude's connection to sandbox VM
  - Defaults to ``~/.config/jm/claude/known_hosts``.

Other setup steps:

- `$ ssh-keyscan <VM_SANDBOX_HOSTNAME> > ~/.config/jm/claude/known_hosts`

- Enable podman socket for docker/compose:
  `$ systemctl --user enable --now podman.socket`

  Note: if you edit e.g. ${XDG_CONFIG_HOME}/containers/containers.conf you have
  to restart the socket or you want see the change take effect like do with
  podman-compose.

Run
###

built locally: `podman compose run claude`

or `IMAGE=ghcr.io/jan-matejka/claude podman compose run claude`

.. [1] Note this does not add any real security. ``restrict`` disables
       pty/agent/X11-forwarding and ``~/.ssh/rc``, and ``command="/bin/false"``
       fails any shell/exec attempt, but once forwarding reaches the podman
       socket the key can start arbitrary containers on the VM (e.g.
       bind-mounting the VM's own filesystem, running privileged) -- which is
       equivalent to full control of the VM regardless of these SSH-level
       restrictions. OpenSSH's ``permitopen`` also has no syntax to scope
       Unix-domain socket destinations (only ``host:port`` pairs), so
       forwarding itself can't be narrowed to just this one socket either.
       The VM's own network isolation is what actually bounds the blast
       radius, not this key's options.
