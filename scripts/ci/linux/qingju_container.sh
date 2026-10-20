#!/usr/bin/env bash
set -euo pipefail

# 上游 WPE 插件依赖 libwpe/FDO API；固定已验证包含这些包的官方快照。
# 配置仅写入本次构建容器，不影响宿主机器。
cat > /etc/pacman.d/mirrorlist <<'MIRRORS'
Server = https://archive.archlinux.org/repos/2026/09/06/$repo/os/$arch
MIRRORS
pacman -Syyuu --noconfirm git
# volume_controller 的 Linux 插件要求 ALSA 开发头文件。
pacman -S --noconfirm --needed alsa-lib
pacman -Si libwpe wpebackend-fdo wpewebkit alsa-lib
git config --global --add safe.directory '*'
bash scripts/ci/linux/build_bundle.sh
