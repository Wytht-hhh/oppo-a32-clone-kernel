# OPPO A32 (SM4250 / bengal) 内核构建环境包

本包是**自包含**的：解压到任意 x86_64 Linux 机器即可直接编译，不依赖任何本机路径。
不需要联网下载工具链（clang + GCC binutils 已打包在 `toolchain/`）。

## 包内容

| 路径 | 说明 |
|------|------|
| `kernel/` | OPPO SM4250 内核源码（`source/android/kernel/msm-4.19`，含 .git） |
| `toolchain/Snapdragon-LLVM-ARM-Compiler-10.0.7-for-Android-NDK/` | clang 10.0.7（编译器） |
| `toolchain/aarch64-linux-android-4.9/` | GCC 4.9 binutils（链接器/汇编器） |
| `config/phone.config` | 手机原厂 config（`~/boot/config`） |
| `config/kernel.config` | 上次编译实际用的 .config（版本串 = `-perf-Build-@Enjoy`） |
| `build_kernel.sh` | 可移植编译脚本（路径全相对，无需改） |

## 新机器前置条件（Ubuntu x86_64）

```bash
# 基础编译工具
sudo apt install make gcc flex bison libssl-dev bc kmod cpio

# python2.7（编译需要；见下）
# Ubuntu 20.04:
sudo apt install python2
# Ubuntu 22.04+（官方源没有 py2）:
#   方式A: sudo apt install python2.7   （若源里有）
#   方式B: 装 deadsnakes PPA
#   方式C: 直接用系统 python3 也行——build_kernel.sh 会自动兜底，
#          只有 gcc-wrapper.py 确实被调用时才需要真 python2
```

> 提示：脚本会自动找 `python2.7` → `python2` → `python3`。编译失败且报 python 相关错误时，再补装 python2。

## 快速开始

```bash
tar xzf oppoa32-source.tar.gz
cd oppoa32-source
chmod +x build_kernel.sh

# 日常增量编译（首次会自动用 config/phone.config 播种 .config）
./build_kernel.sh Image.gz-dtb modules
```

产物在 `build/arch/arm64/boot/`：
- **`Image.gz`** —— 打包 boot.img 用的内核本体（只换这个，dtb/ramdisk 保留原厂）
- `Image.gz-dtb` —— 内核+dtb 拼接，仅 `fastboot boot` 临时测试用
- `build/arch/arm64/boot/dts/qcom/*.dtb` —— 通用 bengal dtb（**不要**替换原厂 dtb）
- 模块：`rdbg` `lcd` `mpq-dmx-hw-plugin` `mpq-adapter`

## 常用命令

```bash
./build_kernel.sh                       # 默认目标
./build_kernel.sh Image.gz-dtb modules  # 编内核 + dtb + 模块
./build_kernel.sh clean                 # 清空 build 目录
./build_kernel.sh dtbs                  # 只编 dtb（Image.gz-dtb 需要先有 .dtb）
./build_kernel.sh olddefconfig          # 改完 .config 后重新处理
```

输出目录默认 `build/`，可用 `O=其他目录` 覆盖（想同时保留多个配置时用）。

## 版本串（branding）切换

当前 `config/kernel.config` 用的是自定义版本 `4.19.152-perf-Build-@Enjoy`。
换回原厂版 `-perf`（用于测试传感器回归时排除版本串嫌疑）：

```bash
sed -i 's/CONFIG_LOCALVERSION="-perf-Build-@Enjoy"/CONFIG_LOCALVERSION="-perf"/' build/.config
./build_kernel.sh olddefconfig
./build_kernel.sh clean
./build_kernel.sh dtbs
./build_kernel.sh Image.gz-dtb modules
```

要点：
- 版本串为 `-perf` 时，内核自身校验串自动匹配原厂，`build_kernel.sh` 里的 vermagic 补丁变成无操作，原厂 /vendor 模块照常加载，**不需要额外处理**。
- 换回 branding 时改回 `-perf-Build-@Enjoy` 再编一遍即可。
- 改版本串不影响内核功能，只影响显示/模块校验串。

## 刷机要点（外部有 AIK 时）

- 只用 `Image.gz` 替换 boot.img 的内核段；**dtb 用 boot.img 里原厂那个**，别用 `Image.gz-dtb` 或 `dtbs/` 里的。
- 先 `fastboot boot <boot.img>` 临时启动确认 WiFi/声音正常，再刷入 boot 分区。
