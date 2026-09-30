#!/usr/bin/env bash
# Run as root on Ubuntu 22.04/24.04 after installing curl, tar and xz-utils.
set -euo pipefail
[[ "$EUID" == 0 && "$(uname -m)" == x86_64 ]] || { echo 'Requires root on Linux amd64' >&2; exit 1; }
temporary="$(mktemp -d)"
trap 'rm -rf -- "$temporary"' EXIT
cd "$temporary"
curl -fsSLO https://get.helm.sh/helm-v3.21.3-linux-amd64.tar.gz
curl -fsSLO https://get.helm.sh/helm-v3.21.3-linux-amd64.tar.gz.sha256sum
sha256sum -c helm-v3.21.3-linux-amd64.tar.gz.sha256sum
tar -xzf helm-v3.21.3-linux-amd64.tar.gz
install -m 755 linux-amd64/helm /usr/local/bin/helm
curl -fsSLo kubectl https://dl.k8s.io/release/v1.35.8/bin/linux/amd64/kubectl
curl -fsSLo kubectl.sha256 https://dl.k8s.io/release/v1.35.8/bin/linux/amd64/kubectl.sha256
printf '%s  kubectl\n' "$(cat kubectl.sha256)" | sha256sum -c -
install -m 755 kubectl /usr/local/bin/kubectl
curl -fsSLo SHASUMS256.txt https://nodejs.org/dist/v22.23.3/SHASUMS256.txt
node_archive=node-v22.23.3-linux-x64.tar.xz
curl -fsSLO "https://nodejs.org/dist/v22.23.3/$node_archive"
grep "  $node_archive$" SHASUMS256.txt | sha256sum -c -
tar -xJf "$node_archive" --strip-components=1 -C /usr/local
npm install --global newman@6.2.1
