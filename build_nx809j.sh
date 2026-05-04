#!/bin/bash
# =============================================================================
# Build Script para Kernel NX809J (RedMagic 11 Pro)
# Plataforma: Qualcomm Canoe (SM8850 / Snapdragon 8 Elite)
# GPU: Adreno 840
# Kernel: Linux 6.12.23 (GKI)
# =============================================================================

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Diretório raiz do projeto
ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
KERNEL_DIR="${ROOT_DIR}/kernel_platform/common"
VENDOR_DIR="${ROOT_DIR}/vendor/qcom/opensource"
VENDOR_PROP="${ROOT_DIR}/vendor/qcom/proprietary"
OUT_DIR="${KERNEL_DIR}/out"
MODULES_OUT="${ROOT_DIR}/modules_out"

# ========================== CONFIGURAÇÃO ==========================
# Ajuste o caminho do toolchain conforme sua instalação
CLANG_PATH="${HOME}/toolchains/linux-x86/clang-r547379/bin"

# Número de threads para compilação
JOBS=$(nproc)

# Arquitetura
export ARCH=arm64
export SUBARCH=arm64
export LLVM=1
export LLVM_IAS=1

# ========================== FUNÇÕES ==========================

check_toolchain() {
    echo -e "${CYAN}[1/7] Verificando toolchain...${NC}"
    if [ -d "${CLANG_PATH}" ]; then
        export PATH="${CLANG_PATH}:${PATH}"
        CLANG_VERSION=$("${CLANG_PATH}/clang" --version | head -1)
        echo -e "${GREEN}  ✓ Clang encontrado: ${CLANG_VERSION}${NC}"
    else
        echo -e "${RED}  ✗ Toolchain não encontrado em: ${CLANG_PATH}${NC}"
        echo -e "${YELLOW}  Baixe com:${NC}"
        echo "    mkdir -p ~/toolchains && cd ~/toolchains"
        echo "    git clone --depth=1 https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86 -b android-16.0.0_r1"
        echo ""
        echo -e "${YELLOW}  Ou ajuste CLANG_PATH no topo deste script.${NC}"
        exit 1
    fi
}

build_gki_kernel() {
    echo -e "${CYAN}[2/7] Compilando Kernel Base (GKI)...${NC}"
    cd "${KERNEL_DIR}"

    # Gerar configuração GKI
    echo -e "  ${YELLOW}→ Gerando gki_defconfig...${NC}"
    make O=out gki_defconfig

    # Adicionar CONFIG_ARCH_CANOE e WLAN configs
    echo -e "  ${YELLOW}→ Adicionando configurações extras...${NC}"
    echo "CONFIG_ARCH_CANOE=y" >> out/.config
    echo "CONFIG_CFG80211=m" >> out/.config
    echo "CONFIG_CFG80211_CERTIFICATION_ONUS=y" >> out/.config
    echo "CONFIG_CFG80211_REG_CELLULAR_HINTS=y" >> out/.config
    echo "CONFIG_MAC80211=m" >> out/.config
    echo "CONFIG_MHI_BUS=m" >> out/.config
    echo "CONFIG_MHI_BUS_PCI_GENERIC=m" >> out/.config
    echo "CONFIG_MHI_NET=m" >> out/.config
    echo "CONFIG_QCOM_QMI_HELPERS=m" >> out/.config
    echo "CONFIG_QRTR=m" >> out/.config
    echo "CONFIG_QRTR_SMD=m" >> out/.config
    echo "CONFIG_QRTR_TUN=m" >> out/.config
    echo "CONFIG_QCOM_PD_MAPPER=m" >> out/.config
    echo "CONFIG_QCOM_SYSMON=m" >> out/.config
    echo "CONFIG_QCOM_SMEM=y" >> out/.config
    echo "CONFIG_RPMSG_QCOM_SMD=y" >> out/.config
    make O=out olddefconfig

    # Compilar
    echo -e "  ${YELLOW}→ Compilando Image (${JOBS} threads)...${NC}"
    make O=out -j${JOBS} Image
    echo -e "  ${YELLOW}→ Compilando Módulos do Kernel...${NC}"
    make O=out -j${JOBS} modules

    if [ -f "out/arch/arm64/boot/Image" ]; then
        IMAGE_SIZE=$(du -sh out/arch/arm64/boot/Image | cut -f1)
        echo -e "${GREEN}  ✓ Kernel Image compilado com sucesso (${IMAGE_SIZE})${NC}"
    else
        echo -e "${RED}  ✗ Falha na compilação do kernel${NC}"
        exit 1
    fi

    cd "${ROOT_DIR}"
}

build_module() {
    local MODULE_NAME="$1"
    local MODULE_PATH="$2"
    local EXTRA_FLAGS="$3"

    echo -e "  ${YELLOW}→ Compilando ${MODULE_NAME}...${NC}"

    make -C "${KERNEL_DIR}" O=out \
        M="${MODULE_PATH}" \
        CONFIG_ARCH_CANOE=y \
        ${EXTRA_FLAGS} \
        modules 2>&1 | tail -5

    local KO_COUNT=$(find "${KERNEL_DIR}/out" -path "*${MODULE_PATH}*" -name "*.ko" 2>/dev/null | wc -l)
    if [ "$KO_COUNT" -gt 0 ]; then
        echo -e "${GREEN}    ✓ ${MODULE_NAME}: ${KO_COUNT} módulo(s) compilado(s)${NC}"
    else
        echo -e "${RED}    ✗ ${MODULE_NAME}: nenhum módulo gerado (pode ser normal para alguns drivers)${NC}"
    fi
}

build_vendor_modules() {
    echo -e "${CYAN}[3/7] Compilando Módulos Vendor (out-of-tree)...${NC}"

    # GPU - Adreno 840 (msm_kgsl.ko)
    build_module "GPU (Adreno 840)" \
        "${ROOT_DIR}/vendor/qcom/opensource/graphics-kernel" \
        "KGSL_PATH=${ROOT_DIR}/vendor/qcom/opensource/graphics-kernel"

    # Display (msm_drm.ko)
    build_module "Display" \
        "${ROOT_DIR}/vendor/qcom/opensource/display-drivers/msm" \
        "DISPLAY_ROOT=${ROOT_DIR}/vendor/qcom/opensource/display-drivers CONFIG_DRM_ZTE_DISP=y"

    # Câmera (Spectra)
    build_module "Câmera" \
        "${ROOT_DIR}/vendor/qcom/opensource/camera-kernel"
    # Áudio
    build_module "Áudio" \
        "${ROOT_DIR}/vendor/qcom/opensource/audio-kernel"
    # Bluetooth
    build_module "Bluetooth" \
        "${ROOT_DIR}/vendor/qcom/opensource/bt-kernel"
    # Vídeo (Codec)
    build_module "Vídeo" \
        "${ROOT_DIR}/vendor/qcom/opensource/video-driver"
    # Touch
    build_module "Touch" \
        "${ROOT_DIR}/vendor/qcom/opensource/touch-drivers"
    # SecureMSM
    build_module "SecureMSM" \
        "${ROOT_DIR}/vendor/qcom/opensource/securemsm-kernel"
    # MM-Drivers (hw_fence, sync_fence, etc.)
    build_module "MM-Drivers (sync_fence)" \
        "${ROOT_DIR}/vendor/qcom/opensource/mm-drivers/sync_fence"
    build_module "MM-Drivers (hw_fence)" \
        "${ROOT_DIR}/vendor/qcom/opensource/mm-drivers/hw_fence"
    build_module "MM-Drivers (msm_ext_display)" \
        "${ROOT_DIR}/vendor/qcom/opensource/mm-drivers/msm_ext_display"
    # DataIPA
    build_module "DataIPA" \
        "${ROOT_DIR}/vendor/qcom/opensource/dataipa"
}

build_devicetrees() {
    echo -e "${CYAN}[4/7] Compilando Device Trees...${NC}"

    # GPU DeviceTree
    echo -e "  ${YELLOW}→ DeviceTree GPU (Canoe/Adreno 840)...${NC}"
    make -C "${KERNEL_DIR}" O=out \
        M="../../vendor/qcom/opensource/graphics-devicetree" \
        CONFIG_ARCH_CANOE=y \
        dtbs 2>&1 | tail -3 || echo -e "${RED}    ✗ DeviceTree GPU falhou (pode precisar de ajuste)${NC}"

    # Display DeviceTree
    echo -e "  ${YELLOW}→ DeviceTree Display...${NC}"
    make -C "${KERNEL_DIR}" O=out \
        M="../../vendor/qcom/opensource/display-devicetree" \
        CONFIG_ARCH_CANOE=y \
        dtbs 2>&1 | tail -3 || echo -e "${RED}    ✗ DeviceTree Display falhou (pode precisar de ajuste)${NC}"

    # ZTE DeviceTree (Aston/qwjujube)
    echo -e "  ${YELLOW}→ DeviceTree ZTE (NX809J/Aston)...${NC}"
    make -C "${KERNEL_DIR}" O=out \
        M="../../vendor/qcom/proprietary/zte-devicetree" \
        CONFIG_ARCH_CANOE=y \
        dtbs 2>&1 | tail -3 || echo -e "${RED}    ✗ DeviceTree ZTE falhou (pode precisar de ajuste)${NC}"
}

collect_modules() {
    echo -e "${CYAN}[5/7] Coletando módulos compilados...${NC}"
    mkdir -p "${MODULES_OUT}"

    find "${KERNEL_DIR}/out" -name "*.ko" -exec cp -v {} "${MODULES_OUT}/" \; 2>/dev/null

    local TOTAL=$(ls -1 "${MODULES_OUT}"/*.ko 2>/dev/null | wc -l)
    echo -e "${GREEN}  ✓ ${TOTAL} módulos coletados em: ${MODULES_OUT}/${NC}"
}

collect_dtbs() {
    echo -e "${CYAN}[6/7] Coletando Device Trees...${NC}"
    mkdir -p "${MODULES_OUT}/dtbs"

    find "${KERNEL_DIR}/out" -name "*.dtbo" -exec cp -v {} "${MODULES_OUT}/dtbs/" \; 2>/dev/null
    find "${KERNEL_DIR}/out" -name "*.dtb" -exec cp -v {} "${MODULES_OUT}/dtbs/" \; 2>/dev/null

    local TOTAL=$(ls -1 "${MODULES_OUT}/dtbs/"*.dtb* 2>/dev/null | wc -l)
    echo -e "${GREEN}  ✓ ${TOTAL} device trees coletados em: ${MODULES_OUT}/dtbs/${NC}"
}

print_summary() {
    echo ""
    echo -e "${CYAN}================================================================${NC}"
    echo -e "${GREEN}  BUILD COMPLETO - NX809J (RedMagic 11 Pro)${NC}"
    echo -e "${CYAN}================================================================${NC}"
    echo ""
    echo -e "  Kernel:   ${OUT_DIR}/arch/arm64/boot/Image"
    echo -e "  Módulos:  ${MODULES_OUT}/"
    echo -e "  DTBs:     ${MODULES_OUT}/dtbs/"
    echo ""
    echo -e "${YELLOW}  Próximo passo:${NC}"
    echo -e "  1. Extraia o boot.img original do firmware stock"
    echo -e "  2. Substitua o kernel Image"
    echo -e "  3. Use 'fastboot boot new_boot.img' para testar (sem gravar)"
    echo ""
    echo -e "${CYAN}================================================================${NC}"
}

# ========================== EXECUÇÃO ==========================

echo ""
echo -e "${CYAN}================================================================${NC}"
echo -e "${GREEN}  NX809J Kernel Builder${NC}"
echo -e "${GREEN}  RedMagic 11 Pro | Snapdragon 8 Elite | Adreno 840${NC}"
echo -e "${GREEN}  Kernel 6.12.23 (GKI) | Android 16${NC}"
echo -e "${CYAN}================================================================${NC}"
echo ""

check_toolchain
build_gki_kernel
build_vendor_modules
build_devicetrees
collect_modules
collect_dtbs
print_summary
