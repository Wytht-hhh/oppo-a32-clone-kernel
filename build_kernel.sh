#!/bin/bash
# OPPO A32 (SM4250 / bengal) 内核构建脚本 —— 可移植版
# 用法（脚本路径任意，依赖全部在本包内，无需改路径）：
#   ./build_kernel.sh                     # 日常增量编译（默认目标）
#   ./build_kernel.sh Image.gz-dtb modules
#   ./build_kernel.sh clean               # 清空 build 目录
#   ./build_kernel.sh dtbs                # 编 dtb（Image.gz-dtb 需要先有 .dtb）
#   ./build_kernel.sh olddefconfig        # 重新处理 .config
# 输出目录默认 $SCRIPT_DIR/build，可用环境变量 O=xxx 覆盖。
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

KSRC="$SCRIPT_DIR/kernel/android_kernel_modules_and_devicetree_oppo_sm4250/source/android/kernel/msm-4.19"
O="${O:-$SCRIPT_DIR/build}"
LLVM_BIN="$SCRIPT_DIR/toolchain/Snapdragon-LLVM-ARM-Compiler-10.0.7-for-Android-NDK/bin"
GCC49_BIN="$SCRIPT_DIR/toolchain/aarch64-linux-android-4.9/bin"
PHONE_CONFIG="${PHONE_CONFIG:-$SCRIPT_DIR/config/phone.config}"

# 挑一个 python2（OPPO 内核 Makefile 的 CC 包装 gcc-wrapper.py 是 py2；
# 命令行传了 CC=clang 会覆盖掉它，但保留 py2 兜底最稳）。
PY=""
for cand in python2.7 python2; do
  if command -v "$cand" >/dev/null 2>&1; then PY="$cand"; break; fi
done
if [ -z "$PY" ]; then
  if command -v python3 >/dev/null 2>&1; then
    PY="python3"
    echo "WARN: 未找到 python2.7，用 python3 兜底。若编译失败，请先装 python2.7（Ubuntu20.04: sudo apt install python2）"
  else
    echo "ERROR: 需要 python 解释器（建议 python2.7）"
    exit 1
  fi
fi

MAKEARGS="PYTHON=$PY ARCH=arm64 CC=clang CLANG_TRIPLE=aarch64-linux-gnu- CROSS_COMPILE=aarch64-linux-android- TARGET_PRODUCT=bengal"
export PATH="$LLVM_BIN:$GCC49_BIN:$PATH"

# 若版本串不是原厂 -perf，则把模块校验 vermagic 钉住原厂版，让 /vendor 原厂模块能加载。
# 版本串为 -perf 时这是无操作。
ensure_vermagic_patch() {
  local vh="$KSRC/include/linux/vermagic.h"
  if grep -q 'UTS_RELEASE " "' "$vh"; then
    echo "== patching $vh: pin module-vermagic to 4.19.152-perf =="
    python3 - "$vh" <<'EOF'
import sys
p = sys.argv[1]
s = open(p).read()
open(p, 'w').write(s.replace('UTS_RELEASE " "', '"4.19.152-perf" " "'))
EOF
  fi
}
ensure_vermagic_patch

# 首次编译：build 目录没有 .config 时，用手机 config 播种。
if [ ! -f "$O/.config" ]; then
  mkdir -p "$O"
  cp "$PHONE_CONFIG" "$O/.config"
  make -C "$KSRC" O="$O" $MAKEARGS olddefconfig
fi

make -C "$KSRC" O="$O" $MAKEARGS -j"$(nproc)" "$@"

echo
echo "产物："
echo "  内核本体    $O/arch/arm64/boot/Image.gz   （打包 boot.img 用这个）"
echo "  内核+dtb    $O/arch/arm64/boot/Image.gz-dtb （仅 fastboot boot 临时测试）"
echo "  设备树      $O/arch/arm64/boot/dts/qcom/*.dtb"
echo "  模块        $O/*.ko"
