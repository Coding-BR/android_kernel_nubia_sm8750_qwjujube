#!/bin/bash
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
KERNEL_DIR="${ROOT_DIR}/kernel_platform/common"
OUT_DIR="${KERNEL_DIR}/out"
CLANG_PATH="${HOME}/toolchains/linux-x86/clang-r547379/bin"
export PATH="${CLANG_PATH}:${PATH}"

cd "${ROOT_DIR}/vendor/qcom/opensource/wlan/platform"

make -C "${KERNEL_DIR}" O=out \
    M="$(pwd)" \
    ARCH=arm64 \
    LLVM=1 \
    LLVM_IAS=1 \
    CONFIG_CNSS_OUT_OF_TREE=y \
    CONFIG_CNSS2=m \
    CONFIG_CNSS2_QMI=y \
    CONFIG_PCIE_QCOM_ECAM=y \
    CONFIG_CNSS_QMI_SVC=m \
    CONFIG_CNSS2_SSR_DRIVER_DUMP=y \
    CONFIG_CNSS_HW_SECURE_DISABLE=y \
    CONFIG_CNSS_HW_SECURE_SMEM=y \
    CONFIG_CNSS2_SMMU_DB_SUPPORT=y \
    CONFIG_CNSS_PLAT_IPC_QMI_SVC=m \
    CONFIG_WCNSS_MEM_PRE_ALLOC=m \
    CONFIG_CNSS2_FMD_FEATURE_ENABLE=y \
    CONFIG_CNSS_UTILS=m \
    CONFIG_CNSS_GENL=m \
    WLAN_PLATFORM_ROOT="$(pwd)" \
    modules
