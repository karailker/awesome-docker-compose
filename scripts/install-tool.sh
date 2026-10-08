#!/usr/bin/env bash
# Download a pinned release of a security tool and verify its SHA-256 before installing it.
# Usage: scripts/install-tool.sh <gitleaks|trivy> [dest-dir]     (default dest: ~/.local/bin)
# To upgrade: change the version AND the checksum (from the release's *_checksums.txt) together.
set -euo pipefail
tool=${1:?usage: install-tool.sh <gitleaks|trivy> [dest-dir]}
dest=${2:-$HOME/.local/bin}
case "$tool" in
  gitleaks)
    version=8.30.1
    url="https://github.com/gitleaks/gitleaks/releases/download/v${version}/gitleaks_${version}_linux_x64.tar.gz"
    sha256=551f6fc83ea457d62a0d98237cbad105af8d557003051f41f3e7ca7b3f2470eb ;;
  trivy)
    version=0.75.0
    url="https://github.com/aquasecurity/trivy/releases/download/v${version}/trivy_${version}_Linux-64bit.tar.gz"
    sha256=c6e65abddb348e25f10549df887045629cf28cc72453cd1c63acb717316b3f3f ;;
  *) echo "unknown tool: $tool" >&2; exit 2 ;;
esac
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
curl -fsSL "$url" -o "$tmp/pkg.tgz"
echo "$sha256  $tmp/pkg.tgz" | sha256sum -c - >/dev/null || { echo "checksum mismatch for $tool $version" >&2; exit 1; }
mkdir -p "$dest"
tar -xzf "$tmp/pkg.tgz" -C "$tmp" "$tool"
install -m 0755 "$tmp/$tool" "$dest/$tool"
echo "installed $tool $version to $dest"
