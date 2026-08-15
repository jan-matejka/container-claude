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

- Use ``docker/compose`` to build the image.
  The same way the image is built locally per ``README.rst``.
  Doesn't matter if CI uses docker or podman. Whatever is simpler.

- No parallel/alternate build path (e.g. ``docker/build-push-action``)
  should be introduced; CI should mirror the local build command.

- Supply the correct build args for BUILD_INFO_CTIME and BUILD_INFO_GIT_COMMIT

Tag
###

- Always tag the resulting image with the full git commit SHA
  of the commit that triggered the build.

Note you do not need to retag the local image with latest tag as that is the
default and the pushed image is the same name as in the compose file.

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

Implemented.

Implementation Spec
###################

- The image name SHALL be just ``claude``.
- The image build SHALL also use the registry as a cache that can be leveraged
  across pipeline instances.
- Shell script steps consisting of more than a single simple command SHALL
  start setting shell options errexit, nounset, and xtrace.
