ARG UV_RELEASE=0.12
FROM ghcr.io/astral-sh/uv:${UV_RELEASE} AS uv
FROM ghcr.io/jan-matejka/debian:latest AS claude

RUN set -eux; \
apt-get update; \
apt-get install -y npm; \
npm install -g @anthropic-ai/claude-code

RUN mkdir -p /out && cp "$(readlink -f "$(command -v claude)")" /out/claude

FROM ghcr.io/jan-matejka/debian:latest

WORKDIR /src
CMD ["claude"]

COPY --from=claude /out/claude /usr/local/bin/claude
COPY --from=uv /uv /uvx /usr/local/bin/

RUN set -eux; \
apt-get update; \
apt-get install -y cloc gh podman python3-docutils openssh-client git-lfs

USER user

ARG DOCKER_COMPOSE_RELEASE=v5.5.1
ARG DOCKER_COMPOSE_URL=https://github.com/docker/compose/releases/${DOCKER_COMPOSE_RELEASE}/download/docker-compose-linux-x86_64

ENV DOCKER_COMPOSE_URL=$DOCKER_COMPOSE_URL

RUN set -eux; \
mkdir -p ~/.local/bin; \
curl -SL ${DOCKER_COMPOSE_URL} -o ~/.local/bin/docker-compose

RUN uv python install 3.14

RUN set -eu; \
mkdir -p ~/.config/claude ~/.local/share/claude; \
ln -snf ~/.config/claude/claude.json ~/.claude.json; \
ln -snf ~/.local/share/claude ~/.claude

RUN curl https://raw.githubusercontent.com/jan-matejka/dotfiles-git/refs/heads/master/.gitconfig >~/.gitconfig
USER root
RUN apt-get install -y python3 ruby puppet
USER user

ARG IMAGE_BUILD_CTIME=
ARG IMAGE_BUILD_COMMIT=
ARG IMAGE_BUILD_REF=
ARG IMAGE_BUILD_BY=

ENV JMA_CLAUDE_IMAGE_BUILD_CTIME=${IMAGE_BUILD_CTIME} \
  JMA_CLAUDE_IMAGE_BUILD_COMMIT=${IMAGE_BUILD_COMMIT} \
  JMA_CLAUDE_IMAGE_BUILD_REF=${IMAGE_BUILD_REF} \
  JMA_CLAUDE_IMAGE_BUILD_BY=${IMAGE_BUILD_BY}
