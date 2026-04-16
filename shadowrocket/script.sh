#!/bin/bash
#
# shadowrocket/script.sh
# Shadowrocket 配置管线 — 从上游懒人配置 + 本地 DIY 规则生成最终 shadowrocket.conf
#
# 输入:
#   shadowrocket/input/*.list  — DIY 规则片段
#   shadowrocket/version.txt  — 版本号
# 输出:
#   dist/shadowrocket.conf    — 最终产物
#
# 依赖: wget, sed
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
INPUT_DIR="${SCRIPT_DIR}/input"
OUTPUT_DIR="${PROJECT_ROOT}/dist"
VERSION_FILE="${SCRIPT_DIR}/version.txt"

# ── 读取版本号和注释头 ─────────────────────────────────────────
CURRENT_VERSION=$(cat "$VERSION_FILE" 2>/dev/null || echo "0.1")
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

# ── 变量校验 ──────────────────────────────────────────────────
INPUT_FILES=(
    "${INPUT_DIR}/rule.list"
    "${INPUT_DIR}/proxy_group.list"
    "${INPUT_DIR}/host.list"
)

for f in "${INPUT_FILES[@]}"; do
    if [[ ! -f "$f" ]]; then
        echo "[Shadowrocket] ERROR: 缺少输入文件: $f"
        exit 1
    fi
done

echo "[Shadowrocket] 开始构建 (版本 ${CURRENT_VERSION})..."

# ── 下载上游懒人配置 ──────────────────────────────────────────
UPSTREAM_URL="https://johnshall.github.io/Shadowrocket-ADBlock-Rules-Forever/lazy_group.conf"
UPSTREAM_TMP="${SCRIPT_DIR}/output/lazy_base.conf"

mkdir -p "${SCRIPT_DIR}/output"
wget -q -O "$UPSTREAM_TMP" "$UPSTREAM_URL"
if [[ ! -s "$UPSTREAM_TMP" ]]; then
    echo "[Shadowrocket] ERROR: 下载上游配置失败"
    exit 1
fi
echo "[Shadowrocket] 上游配置已下载"

# ── 生成版本注释头 ────────────────────────────────────────────
HEADER_COMMENT="# 当前版本: ${CURRENT_VERSION}
# 更新时间: ${TIMESTAMP}
# 仓库: https://github.com/LAN-Cliv/ss-conf
# 管线: shadowrocket/script.sh
"

# ── 删除局域网相关规则 (避免冲突) ─────────────────────────────
# 原配置含 192.168.0.0/16，这里移除避免和个人规则冲突
sed -i 's/192\.168\.0\.0\/16,//g' "$UPSTREAM_TMP"
echo "[Shadowrocket] 已清理上游局域网规则"

# ── 在 [Rule] 下插入 DIY 规则 ──────────────────────────────────
# 读取 rule.list 内容（去掉注释和空行）
RULE_CONTENT=$(grep -v '^#' "${INPUT_DIR}/rule.list" | grep -v '^$' | grep -v '^#' | grep -v '^；')

if [[ -n "$RULE_CONTENT" ]]; then
    # 在 [Rule] 行后插入 DIY 规则
    sed -i "/^\[Rule\]\$/r /dev/stdin" "$UPSTREAM_TMP" <<< "$RULE_CONTENT"
    echo "[Shadowrocket] DIY 规则已注入 (${INPUT_DIR}/rule.list)"
fi

# ── 在 [Proxy Group] 下插入 DIY 分组 ───────────────────────────
PROXY_GROUP_CONTENT=$(grep -v '^#' "${INPUT_DIR}/proxy_group.list" | grep -v '^$' | grep -v '^#' | grep -v '^；')

if [[ -n "$PROXY_GROUP_CONTENT" ]]; then
    # 在 [Proxy Group] 行后插入 DIY 分组
    sed -i "/^\[Proxy Group\]\$/r /dev/stdin" "$UPSTREAM_TMP" <<< "$PROXY_GROUP_CONTENT"
    echo "[Shadowrocket] DIY 分组已注入 (${INPUT_DIR}/proxy_group.list)"
fi

# ── 在 [Host] 下插入 DIY 主机映射 ─────────────────────────────
HOST_CONTENT=$(grep -v '^#' "${INPUT_DIR}/host.list" | grep -v '^$' | grep -v '^#' | grep -v '^；')

if [[ -n "$HOST_CONTENT" ]]; then
    # 在 [Host] 行后插入 DIY 主机映射
    sed -i "/^\[Host\]\$/r /dev/stdin" "$UPSTREAM_TMP" <<< "$HOST_CONTENT"
    echo "[Shadowrocket] DIY 主机映射已注入 (${INPUT_DIR}/host.list)"
fi

# ── 组装最终文件 ──────────────────────────────────────────────
FINAL_OUTPUT="${OUTPUT_DIR}/shadowrocket.conf"

# 写出版本注释头
echo -e "$HEADER_COMMENT" > "$FINAL_OUTPUT"

# 追加处理后的上游配置
cat "$UPSTREAM_TMP" >> "$FINAL_OUTPUT"

# ── 清理临时文件 ─────────────────────────────────────────────
rm -f "$UPSTREAM_TMP"

echo "[Shadowrocket] 构建完成: ${FINAL_OUTPUT}"
