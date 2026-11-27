#!/usr/bin/env bash
set -euo pipefail

# 上游 WPE 插件依赖 libwpe/FDO API；固定已验证包含这些包的官方快照。
# 配置仅写入本次构建容器，不影响宿主机器。
cat > /etc/pacman.d/mirrorlist <<'MIRRORS'
Server = https://archive.archlinux.org/repos/2026/09/06/$repo/os/$arch
MIRRORS
pacman -Syyuu --noconfirm git
# archive.archlinux.org 快照偶发极慢，pacman 默认「<1 B/s 持续 10 秒即中止」会让大体积
# 依赖（如 mpv 约 150 MiB）整笔事务失败。关闭低速超时并对下载类事务做有界重试。
pacman_retry() {
  local attempt
  for attempt in 1 2 3; do
    if pacman --disable-download-timeout "$@"; then
      return 0
    fi
    echo "pacman $* 第 ${attempt}/3 次失败" >&2
    if [ "${attempt}" -lt 3 ]; then
      sleep 10
    fi
  done
  return 1
}
# volume_controller 的 Linux 插件要求 ALSA 开发头文件。
pacman_retry -S --noconfirm --needed alsa-lib
# media_kit_video 链接 libmpv（提供 mpv.pc）。
pacman_retry -S --noconfirm --needed mpv
# jni 插件需要 JDK 头文件（FindJNI）。
pacman_retry -S --noconfirm --needed jdk-openjdk
export JAVA_HOME="$(dirname "$(dirname "$(readlink -f "$(command -v javac)")")")"
pacman -Si libwpe wpebackend-fdo wpewebkit alsa-lib mpv
git config --global --add safe.directory '*'
# CI 容器有网络：不要给 cargokit 打 --offline 补丁（flatpak 沙箱才需要）。
export CARGOKIT_OFFLINE_PATCH=0
bash scripts/ci/linux/build_bundle.sh
