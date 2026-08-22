FROM ghcr.io/jan-matejka/debian:latest AS build

RUN <<EOF
apt-get update
apt-get install -y npm
npm install -g @anthropic-ai/claude-code
EOF

RUN mkdir -p /out && cp "$(readlink -f "$(command -v claude)")" /out/claude


FROM ghcr.io/jan-matejka/debian:latest

WORKDIR /src
CMD ["claude"]

COPY --from=build /out/claude /usr/local/bin/claude

RUN <<EOF
apt-get update
apt-get install -y podman openssh-client
EOF

USER user

RUN <<EOF
set -eu
mkdir -p ~/.config/claude ~/.local/share/claude
ln -snf ~/.config/claude/claude.json ~/.claude.json
ln -snf ~/.local/share/claude ~/.claude
EOF

ARG BUILD_INFO_CTIME=latest
ARG BUILD_INFO_GIT_COMMIT=latest

ENV BUILD_INFO_CTIME=${BUILD_INFO_CTIME} \
    BUILD_INFO_GIT_COMMIT=${BUILD_INFO_GIT_COMMIT}

LABEL org.opencontainers.image.created=${BUILD_INFO_CTIME} \
      org.opencontainers.image.revision=${BUILD_INFO_GIT_COMMIT}
