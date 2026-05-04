#!/bin/bash
ROOT_DIR="/home/adrianojr59/Downloads/NX809JAndroid16"
KERNEL_DIR="${ROOT_DIR}/kernel_platform/common"
WLAN_ROOT="${ROOT_DIR}/vendor/qcom/opensource/wlan/qcacld-3.0"
export PATH="/home/adrianojr59/toolchains/linux-x86/clang-r547379/bin:${PATH}"

make -C "${KERNEL_DIR}" O=out ARCH=arm64 LLVM=1 LLVM_IAS=1 \
    M="${WLAN_ROOT}" \
    WLAN_ROOT="${WLAN_ROOT}" \
    WLAN_COMMON_ROOT=cmn \
    WLAN_COMMON_INC="${WLAN_ROOT}/cmn" \
    WLAN_FW_API="${WLAN_ROOT}/../fw-api" \
    CONFIG_CNSS_KIWI_V2=y \
    CONFIG_BERYLLIUM=y \
    CONFIG_WLAN_VENDOR_QCOM=y \
    CONFIG_CNSS2=y \
    CONFIG_CNSS2_PCI=y \
    CONFIG_ARCH_CANOE=y \
    CONFIG_QCA_CLD_WLAN=m \
    CONFIG_CNSS_OUT_OF_TREE=y \
    CONFIG_WLAN_FEATURE_11BE=y \
    CONFIG_WLAN_FEATURE_11BE_MLO=y \
    KBUILD_EXTRA_SYMBOLS="${ROOT_DIR}/vendor/qcom/opensource/wlan/platform/Module.symvers" \
    MODNAME=wlan \
    modules
