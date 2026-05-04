#!/bin/bash
WLAN_DIR="/home/adrianojr59/Downloads/NX809JAndroid16/vendor/qcom/opensource/wlan"
TAG="WLAN.LA.1.0.r1-09400-pakala.0"

mkdir -p "$WLAN_DIR"
cd "$WLAN_DIR"

# Backup existing if not git
[ -d fw-api ] && [ ! -d fw-api/.git ] && mv fw-api fw-api_old
[ -d qcacld-3.0 ] && [ ! -d qcacld-3.0/.git ] && mv qcacld-3.0 qcacld-3.0_old
[ -d qca-wifi-host-cmn ] && [ ! -d qca-wifi-host-cmn/.git ] && mv qca-wifi-host-cmn qca-wifi-host-cmn_old
[ -d platform ] && [ ! -d platform/.git ] && mv platform platform_old

echo "Cloning platform..."
git clone --depth 1 --branch "$TAG" https://git.codelinaro.org/clo/la/platform/vendor/qcom-opensource/wlan/platform.git
