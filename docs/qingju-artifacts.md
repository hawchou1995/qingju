# 青橘五平台构建产物

源码：分支 `qingju`，提交 `7b9d901a`（应用代码与 `6319b0ec` 相同，后者之后仅改动 Linux CI 脚本）。
四个平台产物由运行 [6319b0ec](https://github.com/hawchou1995/qingju/actions/runs/39361434602) 产出；
Linux 产物由运行 [7b9d901a](https://github.com/hawchou1995/qingju/actions/runs/39364743924) 产出。
均只上传 artifact，未创建 tag、Release 或商店版本。

| 平台 | 文件 | 字节 | SHA-256 |
|---|---|---|---|
| Android ARM64（debug 测试签名） | `qingju-android-arm64-debug.apk` | 229,749,356 | `6208863c44ff97a74403454c9a7a1ce496b4798c99d545d06a8bd873c5c5ee44` |
| iOS ARM64（无签名） | `qingju-ios-arm64-unsigned.ipa` | 54,098,301 | `aa53295403441ab908d63a15b73516d6cf1a1ca53d1f919a105ae10ed5bcbf1d` |
| macOS ARM64（adhoc，未公证） | `qingju-macos-arm64-adhoc.zip` | 57,203,490 | `4e757224676069600e1942e67086a38972b40a3b89ac4da784692ae9c09fe7b9` |
| Windows x64 | `qingju-windows-x64.zip` | 125,458,988 | `d015dc4f5fdc0c003ccb541e87c3e898ddb1eb3ca8f8800527b5f39b81c60c8d` |
| Linux x64 | `qingju-linux-x64.tar.gz` | 242,797,806 | `f809e5be9092ab9693e4c3e3009b7836ad23db113b26f250bd765f8e39097370` |

本地目录：`deliverables/qingju-<platform>/`（已加入 `.gitignore`，未提交）。每份 artifact 内含上游脚本生成的 `BUILD.txt`（源码提交）与 `SHA256SUMS.txt`；上表哈希已用 `Get-FileHash` 重新计算并与清单比对一致。

安装限制：

- Android：debug 测试签名（Gradle 本地无 `key.properties` 时回退 debug keystore），可侧载，不适合商店分发。
- iOS：未签名，需自备证书重签后才能安装。
- macOS：adhoc 签名、未公证，首次打开需右键或 `xattr -cr`。
- Windows：解压后运行 `qingju.exe`，保留同目录 `data/`、`native/` 与 DLL。
- Linux：解压后运行 `bundle/qingju`；需要与构建环境兼容的 glibc、GTK3、WPE WebKit 与系统密钥环。

构建依赖（Linux CI 使用固定 Arch 快照 `2026-09-06`，确保含 `libwpe`/`wpebackend-fdo`/`wpewebkit 2.52`）：另需 `alsa-lib`（volume_controller）、`mpv`（media_kit_video）、`jdk-openjdk`（jni）。

## GitHub Release：qingju-v0.2.28.1

<https://github.com/hawchou1995/qingju/releases/tag/qingju-v0.2.28.1>（Prerelease，提交 `d36d2ac4`，运行 `39372308883`：五个构建作业与发布作业全部 success）。

| 资产 | 字节 | SHA-256 |
|---|---|---|
| `qingju-android-arm64-debug.apk` | 229,749,356 | `93e61358edfe7897353b7b075717bbbd17c3d048d321cf812e367c21d8a99b98` |
| `qingju-ios-arm64-unsigned.ipa` | 54,098,156 | `1d133632723f0ab282f4efcaf89e8f2b1fe84d4c6a74817722d3de39c4500972` |
| `qingju-macos-arm64-adhoc.zip` | 57,203,500 | `729062789ba36f0a5352a4db15894ef9836d2894b09d2184be7ba1be87db3cab` |
| `qingju-windows-x64.zip` | 125,458,991 | `0426f1eead3972a90862e6a94dd99584230c392594ad47a9542c40d4e0b663b2` |
| `qingju-linux-x64.tar.gz` | 242,799,992 | `eaa7e401ea33c87b9431c446ee6261c376ba0fed80f7d5b237287580f795fe19` |

发布页的 `SHA256SUMS.txt` 由这五个已发布资产逐一下载后重新计算并回传，可离线复核。
