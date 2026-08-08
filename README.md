[中文文档](README.zh.md) | English
# OPPO A32 (SM4250 / bengal) Kernel Build Environment Package
Many thanks to rtyutechstudio(cuoxianxu) for participating in the testing and providing great help
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
Tip: The script automatically looks for python2.7 → python2 → python3. If compilation fails with python-related errors, install python2 afterwards.

Quick Start
bash
tar xzf oppoa32-source.tar.gz
cd oppoa32-source
chmod +x build_kernel.sh

# Incremental build (first run seeds .config from config/phone.config)
./build_kernel.sh Image.gz-dtb modules
Output is in build/arch/arm64/boot/:

Image.gz – kernel image used for packing boot.img (replace only this, keep original dtb/ramdisk)

Image.gz-dtb – kernel + dtb concatenated, for fastboot boot temporary testing only

build/arch/arm64/boot/dts/qcom/*.dtb – generic bengal dtb files (do not replace stock dtb)

Modules: rdbg lcd mpq-dmx-hw-plugin mpq-adapter

Common Commands
bash
./build_kernel.sh                       # default targets
./build_kernel.sh Image.gz-dtb modules  # build kernel + dtb + modules
./build_kernel.sh clean                 # clean build directory
./build_kernel.sh dtbs                  # build dtb only (Image.gz-dtb requires .dtb already)
./build_kernel.sh olddefconfig          # reprocess after modifying .config
Output directory defaults to build/; override with O=other_dir (useful for maintaining multiple configs).

Switching Version String (Branding)
The current config/kernel.config uses a custom version: 4.19.152-perf-Build-@Enjoy.
To revert to the stock version -perf (useful for testing sensor behavior while eliminating version-string differences):

bash
sed -i 's/CONFIG_LOCALVERSION="-perf-Build-@Enjoy"/CONFIG_LOCALVERSION="-perf"/' build/.config
./build_kernel.sh olddefconfig
./build_kernel.sh clean
./build_kernel.sh dtbs
./build_kernel.sh Image.gz-dtb modules
Key points:

When the version string is -perf, the kernel's vermagic matches stock, and the vermagic patch in build_kernel.sh becomes a no‑op. Stock /vendor modules load normally – no extra steps needed.

To switch back, change to -perf-Build-@Enjoy and rebuild.

Changing the version string does not affect kernel functionality – it only affects display and module vermagic checks.
