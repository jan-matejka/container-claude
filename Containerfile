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


ARG IMAGE_BUILD_CTIME=
ARG IMAGE_BUILD_COMMIT=
ARG IMAGE_BUILD_REF=
ARG IMAGE_BUILD_BY=

ENV JMA_CLAUDE_IMAGE_BUILD_CTIME=${IMAGE_BUILD_CTIME} \
  JMA_CLAUDE_IMAGE_BUILD_COMMIT=${IMAGE_BUILD_COMMIT} \
  JMA_CLAUDE_IMAGE_BUILD_REF=${IMAGE_BUILD_REF} \
  JMA_CLAUDE_IMAGE_BUILD_BY=${IMAGE_BUILD_BY}
