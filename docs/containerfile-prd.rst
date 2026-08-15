Containerfile PRD
#################

Once the claude binary is built, start over with another FROM instruction and
copy over only the claude executable binary.

Build args
##########

Take following build args:
- BUILD_INFO_CTIME - image create time in UTC
- BUILD_INFO_GIT_COMMIT - the git commit sha the image was built from.

Both default to ``latest``.

Bake both these args into the image as ENV variables of the same name and
and appropriate labels.

Make sure the build info is baked in last to not bust cache needlessly.

Make sure the build info is updated in the resulting image even if there was no
other change to the image since last build.
