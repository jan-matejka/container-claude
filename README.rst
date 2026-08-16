######################
claude container image
######################

Requirements
############

- podman (or docker)
- docker/compose

Build
#####

- `podman compose build`

Host configuration
##################

- Enable podman socket for docker/compose:

  `systemctl --user enable --now podman.socket`

Container configuration
#######################

The `compose.yaml` defines volumes that are mapped into the container so the
claude configuration and authentication is persistent across containers.

Repository Structure
####################

It is assumed claude is being run from a git-worktree and the git-dir is in
``../main/.git``.

Claude gets RW access to the worktree but only RO access to the git-dir.

Run
###

built locally: `podman compose run claude`

or `IMAGE=ghcr.io/jan-matejka/claude podman compose run claude`
