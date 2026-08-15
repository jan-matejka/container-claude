Github CI Integration
######################

Goal
####

Add a GitHub Actions pipeline that builds the claude container image on
every push, tags it with the git commit hash, and pushes it to the ghcr.io
container registry.

Trigger
#######

- Push to any branch.

Build
#####

- Use ``podman compose build`` (via ``docker/compose`` on the GitHub
  runner) against the existing ``compose.yaml`` / ``Containerfile``, the
  same way the image is built locally per ``README.rst``.
- No parallel/alternate build path (e.g. ``docker/build-push-action``)
  should be introduced; CI should mirror the local build command.

Tag
###

- Tag the resulting image with the ``latest`` tag if built from main branch.

- Always tag the resulting image with the full git commit SHA
  of the commit that triggered the build.

Push
####

- Push the tagged image to the ghcr.io container registry. Always with the git
  commit tag and additionally with the latest tag if triggered from main
  branch.
- Authenticate with ``GITHUB_TOKEN``.

Concurrency
###########

Subsequent push should cancel a previous pipeline run if one is still running
from the same branch.

Status
######

Requirements only — the workflow itself has not been implemented yet.
