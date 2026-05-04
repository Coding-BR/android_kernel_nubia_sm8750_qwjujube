#!/bin/bash
ROOT_DIR="/home/adrianojr59/Downloads/NX809JAndroid16"
KSU_DIR="${ROOT_DIR}/ksu_wlan_module_v2"
OUT_ZIP="${ROOT_DIR}/ksu_redmagic11_wlan_v2.zip"

echo "--- Gerando Módulo WLAN v2 (Modo Overlay) ---"

rm -rf "${KSU_DIR}"
# Criar estrutura idêntica ao sistema original
mkdir -p "${KSU_DIR}/system/vendor/lib/modules"

# 1. Copiar nossos drivers renomeando-os para bater com o sistema
# O nosso wlan.ko assume a identidade do stock peach_v2
cp "${ROOT_DIR}/vendor/qcom/opensource/wlan/qcacld-3.0/wlan.ko" "${KSU_DIR}/system/vendor/lib/modules/qca_cld3_peach_v2.ko"

# Outros drivers da plataforma
cp "${ROOT_DIR}/vendor/qcom/opensource/wlan/platform/cnss2/cnss2.ko" "${KSU_DIR}/system/vendor/lib/modules/cnss2.ko"
cp "${ROOT_DIR}/vendor/qcom/opensource/wlan/platform/cnss_utils/cnss_utils.ko" "${KSU_DIR}/system/vendor/lib/modules/cnss_utils.ko"
cp "${ROOT_DIR}/vendor/qcom/opensource/wlan/platform/cnss_utils/wlan_firmware_service.ko" "${KSU_DIR}/system/vendor/lib/modules/wlan_firmware_service.ko"
cp "${ROOT_DIR}/vendor/qcom/opensource/wlan/platform/cnss_utils/cnss_plat_ipc_qmi_svc.ko" "${KSU_DIR}/system/vendor/lib/modules/cnss_plat_ipc_qmi_svc.ko"
cp "${ROOT_DIR}/vendor/qcom/opensource/wlan/platform/cnss_prealloc/cnss_prealloc.ko" "${KSU_DIR}/system/vendor/lib/modules/cnss_prealloc.ko"
cp "${ROOT_DIR}/vendor/qcom/opensource/wlan/platform/cnss_genl/cnss_nl.ko" "${KSU_DIR}/system/vendor/lib/modules/cnss_nl.ko"

# Drivers do Kernel (GKI)
cp "${ROOT_DIR}/kernel_platform/common/out/net/wireless/cfg80211.ko" "${KSU_DIR}/system/vendor/lib/modules/cfg80211.ko"
cp "${ROOT_DIR}/kernel_platform/common/out/drivers/bus/mhi/host/mhi.ko" "${KSU_DIR}/system/vendor/lib/modules/mhi.ko"
cp "${ROOT_DIR}/kernel_platform/common/out/drivers/soc/qcom/qmi_helpers.ko" "${KSU_DIR}/system/vendor/lib/modules/qmi_helpers.ko"

# 2. module.prop
cat <<EOF > "${KSU_DIR}/module.prop"
id=rm11_wlan_stabilized
name=RedMagic 11 WLAN (Stabilized Overlay)
version=v2.0
versionCode=2
author=Antigravity AI
description=Substitui os drivers Wi-Fi stock pelos drivers estabilizados (Wi-Fi 7/MLO) para RedMagic 11 Pro.
EOF

# 3. Zipar
cd "${KSU_DIR}"
zip -r "${OUT_ZIP}" .
cd "${ROOT_DIR}"

echo "--- Módulo v2 gerado: ${OUT_ZIP} ---"
