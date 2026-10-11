#!/usr/bin/env bash
#
# build-clash.sh — 构建 Clash 订阅配置
#
# 用法：./build-clash.sh <版本号> [输出文件]
#   版本号    形如 16.3，写入产物首行注释，客户端借此感知订阅更新
#   输出文件  默认 $REPO_ROOT/conf/clashconf.ini（订阅 URL 路径，勿改）
#
# 流程：下载 ACL4SSR 上游模板
#       → 在 ";设置规则标志位" 首个锚点后注入自定义 ruleset 引用
#       → 在 "♻️ 自动选择" 策略组后注入自定义策略组
#       → 给 "♻️ 自动选择" 加排除正则（回家/内网节点不参与自动测速）
#       → 校验关键内容后写入版本号
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

VERSION="${1:?用法: build-clash.sh <版本号> [输出文件]}"
OUT="${2:-$REPO_ROOT/conf/clashconf.ini}"
SRC="$REPO_ROOT/src/clash"

# 上游模板：ACL4SSR 全量分组在线版
UPSTREAM="ACL4SSR/ACL4SSR/master/Clash/config/ACL4SSR_Online_Full.ini"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

log "下载上游模板：$UPSTREAM"
fetch "$UPSTREAM" "$WORK/base.ini"

log "注入自定义 ruleset（src/clash/ruleset.list）..."
insert_after_first "$WORK/base.ini" '^;设置规则标志位' "$SRC/ruleset.list"

log "注入自定义策略组（src/clash/proxy-group.list）..."
insert_after_first "$WORK/base.ini" '^custom_proxy_group=♻️ 自动选择' "$SRC/proxy-group.list"

log "「♻️ 自动选择」排除回家/内网节点（与旧版行为一致）..."
# 上游正则 .* 会把回家用的 wireguard/内网节点也卷进自动测速，
# 这里沿用旧版排除正则：节点名含 回家|内网|home|Home|back 的不参与。
sed -i \
    's#^custom_proxy_group=♻️ 自动选择`url-test`.*`http#custom_proxy_group=♻️ 自动选择`url-test`(^(?!.*(回家|内网|home|Home|back)).*)`http#' \
    "$WORK/base.ini"

log "校验产物完整性..."
# 注意：断言 pattern 刻意不含 4 字节 emoji（非 BMP 字符）——
# Windows 上的 ugrep 在非交互脚本中无法用此类 pattern 匹配，GNU grep 无此问题。
# 组名用其 BMP 部分（中文名）区分，语义等价。
assert_contains "$WORK/base.ini" '^ruleset=.*DIY直连,'          'DIY直连 ruleset'
assert_contains "$WORK/base.ini" '^ruleset=.*Amazon,'           'Amazon ruleset'
assert_contains "$WORK/base.ini" '^custom_proxy_group=.*自建节点`fallback' '自建节点策略组'
assert_contains "$WORK/base.ini" '(^(?!.*(回家|内网|home|Home|back)).*)'   '自动选择排除正则'
assert_not_contains "$WORK/base.ini" 'src/clash/'                          '残留本地路径'

log "写入版本号：$VERSION"
# 与旧版格式保持一致：首行 "#当前版本号为：x.y"
sed -i "1i #当前版本号为：${VERSION}" "$WORK/base.ini"

mkdir -p "$(dirname "$OUT")"
mv "$WORK/base.ini" "$OUT"
log "已生成 $OUT（v$VERSION）"
