#!/usr/bin/env bash
#
# build-shadowrocket.sh — 构建 Shadowrocket 订阅配置（小火箭"回家"配置）
#
# 用法：./build-shadowrocket.sh <版本号> [输出文件]
#   版本号    形如 14.4，写入产物首行注释
#   输出文件  默认 $REPO_ROOT/conf/diy.conf（订阅 URL 路径，勿改）
#
# 流程：下载 johnshall 懒人配置（含策略组/去广告/规则注释的完整模板）
#       → 从 skip-proxy 与 tun-excluded-routes 中剔除 192.168.0.0/16
#         （关键：不加这一步，回家流量会被客户端本地直连绕过，永远进不了隧道）
#       → 在 [Rule] / [Proxy Group] / [Host] 三个段落头部注入自定义内容
#       → 校验后写入版本号
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

VERSION="${1:?用法: build-shadowrocket.sh <版本号> [输出文件]}"
OUT="${2:-$REPO_ROOT/conf/diy.conf}"
SRC="$REPO_ROOT/src/shadowrocket"

# 上游模板（raw 路径可走镜像；johnshall.github.io Pages 直连不稳定时也可用）
UPSTREAM="johnshall/Shadowrocket-ADBlock-Rules-Forever/master/lazy_group.conf"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

log "下载上游模板：$UPSTREAM"
fetch "$UPSTREAM" "$WORK/base.conf"

log "skip-proxy / tun-excluded-routes 剔除 192.168.0.0/16（保证回家流量进隧道）..."
sed -i 's/192\.168\.0\.0\/16,//g' "$WORK/base.conf"
assert_not_contains "$WORK/base.conf" '192\.168\.0\.0/16' 'skip-proxy 残留内网段'

log "注入自定义规则/策略组/Host..."
insert_after_first "$WORK/base.conf" '^\[Rule\]'        "$SRC/rules.list"
insert_after_first "$WORK/base.conf" '^\[Proxy Group\]' "$SRC/proxy-group.list"
insert_after_first "$WORK/base.conf" '^\[Host\]'        "$SRC/host.list"

log "校验产物完整性..."
assert_contains "$WORK/base.conf" 'DOMAIN-KEYWORD,liviter.top,BACKHOME' '回家域名规则'
assert_contains "$WORK/base.conf" 'IP-CIDR,192.168.50.0/24,BACKHOME'    '回家网段规则'
assert_contains "$WORK/base.conf" '^BACKHOME = select'                  'BACKHOME 策略组'
assert_contains "$WORK/base.conf" '^\*\.liviter\.top=server:223\.5\.5\.5' 'liviter Host 解析'

log "写入版本号：$VERSION"
sed -i "1i #当前版本号为：${VERSION}" "$WORK/base.conf"

mkdir -p "$(dirname "$OUT")"
mv "$WORK/base.conf" "$OUT"
log "已生成 $OUT（v$VERSION）"
