######################
claude container image
######################

Requirements
############

- podman
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

Run
###

`podman compose run claude`
