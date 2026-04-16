#!/bin/bash
#
# clash/subconf.sh
# Clash 配置管线 — 从上游 ACL4SSR 基础配置 + 本地 DIY 规则生成最终 clash.conf
#
# 输入:
#   clash/input/*.list   — DIY 规则片段
#   clash/version.txt    — 版本号
# 输出:
#   dist/clash.conf      — 最终产物
#
# 依赖: wget, sed
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
INPUT_DIR="${SCRIPT_DIR}/input"
OUTPUT_DIR="${PROJECT_ROOT}/dist"
VERSION_FILE="${SCRIPT_DIR}/version.txt"

# ── 读取版本号和注释头 ────────────────────────────────────────────
CURRENT_VERSION=$(cat "$VERSION_FILE" 2>/dev/null || echo "0.1")
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

# ── 变量校验 ────────────────────────────────────────────────────
INPUT_FILES=(
    "${INPUT_DIR}/direct.list"
    "${INPUT_DIR}/proxy.list"
    "${INPUT_DIR}/backhome.list"
    "${INPUT_DIR}/select.list"
    "${INPUT_DIR}/proxy_group.list"
    "${INPUT_DIR}/ruleset.list"
)

for f in "${INPUT_FILES[@]}"; do
    if [[ ! -f "$f" ]]; then
        echo "[Clash] ERROR: 缺少输入文件: $f"
        exit 1
    fi
done

echo "[Clash] 开始构建 (版本 ${CURRENT_VERSION})..."

# ── 下载上游基础配置 ────────────────────────────────────────────
UPSTREAM_URL="https://raw.githubusercontent.com/ACL4SSR/ACL4SSR/master/Clash/config/ACL4SSR_Online_Full.ini"
UPSTREAM_TMP="${SCRIPT_DIR}/output/acl4ssr_base.ini"

mkdir -p "${SCRIPT_DIR}/output"
wget -q -O "$UPSTREAM_TMP" "$UPSTREAM_URL"
if [[ ! -s "$UPSTREAM_TMP" ]]; then
    echo "[Clash] ERROR: 下载上游配置失败"
    exit 1
fi
echo "[Clash] 上游配置已下载"

# ── 生成版本注释头 ─────────────────────────────────────────────
HEADER_COMMENT="# 当前版本: ${CURRENT_VERSION}
# 更新时间: ${TIMESTAMP}
# 仓库: https://github.com/LAN-Cliv/ss-conf
# 管线: clash/subconf.sh
"

# ── 处理 ruleset.list — 注入到配置文件中 ──────────────────────
# 找到 ";设置规则标志位" 的行号，在其后插入 ruleset.list 内容
RULESET_FILE="${INPUT_DIR}/ruleset.list"
RULESET_INSERT_MARKER=";设置规则标志位"

# 读取 ruleset.list 内容（去掉空行）
RULESET_CONTENT=$(grep -v '^#' "$RULESET_FILE" | grep -v '^$' | sed 's/^/ruleset=/')

# 用 sed 在标记行后插入
sed -i "/^${RULESET_INSERT_MARKER}/r /dev/stdin" "$UPSTREAM_TMP" <<< "$RULESET_CONTENT"

# ── 处理 proxy_group.list — 注入到配置文件中 ──────────────────
PROXY_GROUP_FILE="${INPUT_DIR}/proxy_group.list"
PROXY_GROUP_INSERT_MARKER="custom_proxy_group=♻️ 自动选择"

PROXY_GROUP_CONTENT=$(grep -v '^#' "$PROXY_GROUP_FILE" | grep -v '^$' | sed 's/^/custom_proxy_group=/')

sed -i "/^${PROXY_GROUP_INSERT_MARKER}/r /dev/stdin" "$UPSTREAM_TMP" <<< "$PROXY_GROUP_CONTENT"

# ── 在 [Rule] 段落插入 DIY 规则 (direct.list + proxy.list + backhome.list + select.list) ──
RULE_INSERT_MARKER=";设置规则标志位"
DIY_RULE_CONTENT=$(cat "${INPUT_DIR}/direct.list" "${INPUT_DIR}/proxy.list" "${INPUT_DIR}/backhome.list" "${INPUT_DIR}/select.list" 2>/dev/null | grep -v '^#' | grep -v '^$' | sed 's/^/ruleset=/')

# 找到第一个 ruleset 行，在其前插入 DIY 规则（DIY 规则优先）
# 先把所有 DIY 规则写入临时文件
DIY_RULE_TMP="${SCRIPT_DIR}/output/diy_rules.tmp"
echo "$DIY_RULE_CONTENT" > "$DIY_RULE_TMP"

# 在规则集前插入 DIY 规则（保留一行空隙）
sed -i '/^ruleset=/i\\' "$UPSTREAM_TMP"
sed -i '/^ruleset=/r '"$DIY_RULE_TMP" "$UPSTREAM_TMP"

# ── 组装最终文件 ───────────────────────────────────────────────
FINAL_OUTPUT="${OUTPUT_DIR}/clash.conf"

# 写出版本注释头
echo -e "$HEADER_COMMENT" > "$FINAL_OUTPUT"

# 追加处理后的上游配置
cat "$UPSTREAM_TMP" >> "$FINAL_OUTPUT"

# ── 清理临时文件 ───────────────────────────────────────────────
rm -f "$UPSTREAM_TMP" "$DIY_RULE_TMP"

echo "[Clash] 构建完成: ${FINAL_OUTPUT}"
