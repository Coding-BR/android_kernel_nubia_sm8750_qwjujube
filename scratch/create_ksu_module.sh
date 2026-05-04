#!/bin/bash
# Script para gerar módulo KernelSU de estabilização de display

MOD_PATH="scratch/ksu_display_fix"
rm -rf $MOD_PATH
mkdir -p $MOD_PATH/system/vendor/lib/modules

# 1. Criar module.prop
cat <<EOF > $MOD_PATH/module.prop
id=rm11_display_fix
name=RedMagic 11 Pro Stabilized Drivers
version=v1.0-SM8750
versionCode=1
author=Coding-BR & Antigravity
description=Estabiliza o driver de display (msm_drm.ko) com mapeamento real de hardware para o Snapdragon 8 Elite.
EOF

# 2. Copiar drivers compilados
if [ -f "vendor/qcom/opensource/display-drivers/msm/msm_drm.ko" ]; then
    cp vendor/qcom/opensource/display-drivers/msm/msm_drm.ko $MOD_PATH/system/vendor/lib/modules/
    echo "✓ msm_drm.ko copiado"
fi

if [ -f "vendor/qcom/opensource/graphics-kernel/msm_kgsl.ko" ]; then
    cp vendor/qcom/opensource/graphics-kernel/msm_kgsl.ko $MOD_PATH/system/vendor/lib/modules/
    echo "✓ msm_kgsl.ko copiado"
fi

# 3. Criar script de instalação simples
cat <<EOF > $MOD_PATH/install.sh
SKIPMOUNT=false
PROPFILE=false
POSTFSDATA=false
LATESTARTSERVICE=false

on_install() {
    ui_print "- Instalando Estabilização de Display e GPU SM8750..."
    ui_print "- Substituindo msm_drm.ko e msm_kgsl.ko"
    ui_print "- Aplicando patches de hardware v1.0 Stabilized"
    
    # Extrair os arquivos
    unzip -o "$ZIPFILE" 'system/*' -d "$MODPATH" >&2
}

set_permissions() {
  set_perm_recursive \$MODPATH 0 0 0755 0644
}
EOF

# 3.1 Criar script de boot (forçar bind mount)
cat <<EOF > $MOD_PATH/post-fs-data.sh
#!/system/bin/sh
MODDIR=\${0%/*}
# Forçar bind mount se o overlay automático falhar
mount --bind \$MODDIR/system/vendor/lib/modules/msm_drm.ko /vendor/lib/modules/msm_drm.ko
mount --bind \$MODDIR/system/vendor/lib/modules/msm_kgsl.ko /vendor/lib/modules/msm_kgsl.ko
EOF
chmod 755 $MOD_PATH/post-fs-data.sh

# 4. Gerar o ZIP
cd $MOD_PATH
zip -r ../ksu_display_fix.zip .
cd ../..

echo "--------------------------------------------------"
echo "MÓDULO PRONTO: scratch/ksu_display_fix.zip"
echo "Instale via app do KernelSU e reinicie."
echo "--------------------------------------------------"
