#!/bin/bash
ROOT_DIR="/home/adrianojr59/Downloads/NX809JAndroid16"
KSU_DIR="${ROOT_DIR}/ksu_wlan_module"
OUT_ZIP="${ROOT_DIR}/ksu_redmagic11_wlan.zip"

echo "--- Iniciando empacotamento do módulo KernelSU ---"

# Limpar e criar estrutura
rm -rf "${KSU_DIR}"
mkdir -p "${KSU_DIR}/system/lib/modules"

# 1. Copiar Módulos do Kernel (GKI)
cp "${ROOT_DIR}/kernel_platform/common/out/net/wireless/cfg80211.ko" "${KSU_DIR}/system/lib/modules/"
cp "${ROOT_DIR}/kernel_platform/common/out/net/mac80211/mac80211.ko" "${KSU_DIR}/system/lib/modules/"
cp "${ROOT_DIR}/kernel_platform/common/out/drivers/bus/mhi/host/mhi.ko" "${KSU_DIR}/system/lib/modules/"
cp "${ROOT_DIR}/kernel_platform/common/out/drivers/soc/qcom/qmi_helpers.ko" "${KSU_DIR}/system/lib/modules/"
cp "${ROOT_DIR}/kernel_platform/common/out/net/qrtr/qrtr.ko" "${KSU_DIR}/system/lib/modules/"

# 2. Copiar Módulos da Plataforma (CNSS)
cp "${ROOT_DIR}/vendor/qcom/opensource/wlan/platform/cnss_utils/cnss_utils.ko" "${KSU_DIR}/system/lib/modules/"
cp "${ROOT_DIR}/vendor/qcom/opensource/wlan/platform/cnss_utils/wlan_firmware_service.ko" "${KSU_DIR}/system/lib/modules/"
cp "${ROOT_DIR}/vendor/qcom/opensource/wlan/platform/cnss_utils/cnss_plat_ipc_qmi_svc.ko" "${KSU_DIR}/system/lib/modules/"
cp "${ROOT_DIR}/vendor/qcom/opensource/wlan/platform/cnss_prealloc/cnss_prealloc.ko" "${KSU_DIR}/system/lib/modules/"
cp "${ROOT_DIR}/vendor/qcom/opensource/wlan/platform/cnss_genl/cnss_nl.ko" "${KSU_DIR}/system/lib/modules/"
cp "${ROOT_DIR}/vendor/qcom/opensource/wlan/platform/cnss2/cnss2.ko" "${KSU_DIR}/system/lib/modules/"

# 3. Copiar Driver Principal
cp "${ROOT_DIR}/vendor/qcom/opensource/wlan/qcacld-3.0/wlan.ko" "${KSU_DIR}/system/lib/modules/"

# 4. Criar module.prop
cat <<EOF > "${KSU_DIR}/module.prop"
id=rm11_wlan_fix
name=RedMagic 11 WLAN Fix
version=v1.0-pakala
versionCode=1
author=Antigravity AI
description=Módulos WLAN (Wi-Fi 7/MLO) estabilizados para RedMagic 11 Pro (SM8750).
EOF

# 5. Criar service.sh (Script de carregamento)
cat <<EOF > "${KSU_DIR}/service.sh"
#!/system/bin/sh
MODDIR=\${0%/*}

# Função para carregar com log
load_module() {
    insmod "\$1" 2>> /data/local/tmp/wlan_ksu.log
    if [ \$? -eq 0 ]; then
        echo "Sucesso: \$1" >> /data/local/tmp/wlan_ksu.log
    else
        echo "Falha: \$1" >> /data/local/tmp/wlan_ksu.log
    fi
}

echo "--- Iniciando carregamento WLAN ---" > /data/local/tmp/wlan_ksu.log

# Ordem de carregamento crítica
MODULES_PATH="\$MODDIR/system/lib/modules"

load_module "\$MODULES_PATH/cfg80211.ko"
load_module "\$MODULES_PATH/mac80211.ko"
load_module "\$MODULES_PATH/qrtr.ko"
load_module "\$MODULES_PATH/qmi_helpers.ko"
load_module "\$MODULES_PATH/mhi.ko"
load_module "\$MODULES_PATH/cnss_utils.ko"
load_module "\$MODULES_PATH/cnss_prealloc.ko"
load_module "\$MODULES_PATH/wlan_firmware_service.ko"
load_module "\$MODULES_PATH/cnss_plat_ipc_qmi_svc.ko"
load_module "\$MODULES_PATH/cnss_nl.ko"
load_module "\$MODULES_PATH/cnss2.ko"
load_module "\$MODULES_PATH/wlan.ko"
EOF

chmod +x "${KSU_DIR}/service.sh"

# 6. Zipar
cd "${KSU_DIR}"
zip -r "${OUT_ZIP}" .
cd "${ROOT_DIR}"

echo "--- Módulo gerado com sucesso: ${OUT_ZIP} ---"
