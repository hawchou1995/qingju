## GitHub Release：qingju-v0.2.33（正式版）

标签 `qingju-v0.2.33`，提交 `1ab8789c89a95f05158d802b87d475f5317b01b9`，GitHub Actions run `39546252766`（Android、iOS、macOS、Windows、Linux 与 publish 全部 success）。

| 资产 | 字节 | SHA-256 |
|---|---:|---|
| `qingju-0.2.33-android-arm64-debug.apk` | 229,745,636 | `e79c8ffed0a7db3e554a9f48fad271f7909b3f557b87d4dd11e1cd1ccd1d3d91` |
| `qingju-0.2.33-ios-arm64-unsigned.ipa` | 54,088,855 | `221ab9927010e14ad196689dd985c4a926de1875761afc76bd1ff7cf32f9e8ef` |
| `qingju-0.2.33-macos-arm64-adhoc.zip` | 57,199,077 | `b627f0008263945e61f46ca8a8385fdf241fcce9e8db61e3e94be787626df41e` |
| `qingju-0.2.33-windows-x64.zip` | 125,450,039 | `dea3d54838f5c4122736124f094ef23c5c66b8b08ca77475e13c18540e29372d` |
| `qingju-0.2.33-linux-x64.tar.gz` | 242,797,040 | `fa8d6e1aafc00fa762adbe75dfd10bca0ea37513f3b76e2dea53753ab7a1f8ca` |

五份 `SHA256SUMS-<platform>.txt` 均与 GitHub Release 资产 SHA-256 对拍一致；五份 `BUILD-<platform>.txt` 均指向提交 `1ab8789c89a95f05158d802b87d475f5317b01b9`。Android APK 已下载到 `deliverables/qingju-android-0.2.33/`；本地 SHA-256 与发布清单一致，`apksigner verify` 通过，证书 SHA-256 `f441792fdca48edc4a8c6a06a70fe88f075cc420ae4d425f2b8868db97243a30` 与 0.2.32 固定 debug signer 相同。

本版修复 `PreloadedDataService` 首页话题列表并发解析时重复完成 `Completer` 的异步竞态。Android 包为 ARM64 debug 测试签名；不是商店签名包。

---

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

## GitHub Release：qingju-v0.2.28.2（正式版）

<https://github.com/hawchou1995/qingju/releases/tag/qingju-v0.2.28.2>（非预发布，提交 `d6090b8e`，运行 `39376670769`：五个构建作业 + publish 全部 success）。

| 资产 | 字节 | SHA-256 |
|---|---|---|
| `qingju-android-arm64-debug.apk` | 229,749,356 | `f520af520c0650d7b8fef6ac61f6c2f31cf35a45e380712474a98d5f7491c206` |
| `qingju-ios-arm64-unsigned.ipa` | 54,098,152 | `3236a85cc367d0cdddd420bd2223e5f12c26412032efdcd1508922bf1e70d48b` |
| `qingju-macos-arm64-adhoc.zip` | 57,203,525 | `e0a66eec8d7e84f9c368d634656cdebff66a9aa3c76251d6dd269cc16dd77fe2` |
| `qingju-windows-x64.zip` | 125,458,989 | `e3705f800b4e24702db4384b2bc5bf67de5b4aa4681b0c3c7ec6d29b2c152f82` |
| `qingju-linux-x64.tar.gz` | 242,787,761 | `eeb6a254d76a5334b1785f0d2dedef18b862bd8d28580162295225dc84677306` |

每个平台另有独立的 `SHA256SUMS-<platform>.txt` 与 `BUILD-<platform>.txt`（均记录提交 `d6090b8e`）。已完整下载 macOS 包实测字节数 57,203,525、SHA-256 与清单一致；其余四份因带宽限制只核对了清单内容，未逐个完整下载复算。

`SHA256SUMS-linux.txt` 中的文件名带 `dist/` 前缀（`sha256sum` 在仓库根目录执行），其余平台为纯文件名。

上一版 `qingju-v0.2.28.1`（Prerelease）保留作历史，其发布页的 `SHA256SUMS.txt` 为合并后重算的全量清单。

### 历史：qingju-v0.2.28.1（Prerelease）

<https://github.com/hawchou1995/qingju/releases/tag/qingju-v0.2.28.1>（Prerelease，提交 `d36d2ac4`，运行 `39372308883`：五个构建作业与发布作业全部 success）。

| 资产 | 字节 | SHA-256 |
|---|---|---|
| `qingju-android-arm64-debug.apk` | 229,749,356 | `93e61358edfe7897353b7b075717bbbd17c3d048d321cf812e367c21d8a99b98` |
| `qingju-ios-arm64-unsigned.ipa` | 54,098,156 | `1d133632723f0ab282f4efcaf89e8f2b1fe84d4c6a74817722d3de39c4500972` |
| `qingju-macos-arm64-adhoc.zip` | 57,203,500 | `729062789ba36f0a5352a4db15894ef9836d2894b09d2184be7ba1be87db3cab` |
| `qingju-windows-x64.zip` | 125,458,991 | `0426f1eead3972a90862e6a94dd99584230c392594ad47a9542c40d4e0b663b2` |
| `qingju-linux-x64.tar.gz` | 242,799,992 | `eaa7e401ea33c87b9431c446ee6261c376ba0fed80f7d5b237287580f795fe19` |

发布页的 `SHA256SUMS.txt` 由这五个已发布资产逐一下载后重新计算并回传，可离线复核。
