FROM docker.io/library/debian:trixie-slim

WORKDIR /app
CMD ["claude"]

RUN <<EOF
apt-get update
apt-get install -y npm
npm install -g @anthropic-ai/claude-code
EOF

RUN useradd -m user

USER user

RUN <<EOF
set -eu
mkdir -p ~/.config/claude ~/.local/share/claude
ln -snf ~/.config/claude/claude.json ~/.claude.json
ln -snf ~/.local/share/claude ~/.claude
EOF
