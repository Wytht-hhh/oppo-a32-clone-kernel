[中文文档](README.zh.md) | English
# OPPO A32 (SM4250 / bengal) Kernel Build Environment Package

This package is **self-contained**: extract it on any x86_64 Linux machine, and you can build the kernel directly – **no external dependencies** on host paths. No need to download toolchains (clang + GCC binutils) online; they are already bundled in `toolchain/`.

## Package Contents

| Path | Description |
|------|-------------|
| `kernel/` | OPPO SM4250 kernel source (`source/android/kernel/msm-4.19`, includes .git) |
| `toolchain/Snapdragon-LLVM-ARM-Compiler-10.0.7-for-Android-NDK/` | clang 10.0.7 (compiler) |
| `toolchain/aarch64-linux-android-4.9/` | GCC 4.9 binutils (linker/assembler) |
| `config/phone.config` | Stock device config (from `~/boot/config`) |
| `config/kernel.config` | Last used .config (version string = `-perf-Build-@Enjoy`) |
| `build_kernel.sh` | Portable build script (all paths are relative – no changes required) |

## Prerequisites on a Fresh Machine (Ubuntu x86_64)

```bash
# Essential build tools
sudo apt install make gcc flex bison libssl-dev bc kmod cpio

# python2.7 (required for compilation; see below)
# Ubuntu 20.04:
sudo apt install python2
# Ubuntu 22.04+ (no python2 in official repos):
#   Option A: sudo apt install python2.7   (if available)
#   Option B: add deadsnakes PPA
#   Option C: use system python3 directly – build_kernel.sh will fall back
#             to python3 only if gcc-wrapper.py actually needs it.
