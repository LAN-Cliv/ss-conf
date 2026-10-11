#!/usr/bin/env bash
#
# lib.sh — 构建脚本公共函数库
#
# 被 build-clash.sh / build-shadowrocket.sh 通过 `source` 引入，不单独执行。
# 引入方式：source "$(dirname "$0")/lib.sh"

# 任何命令失败、引用未定义变量、管道中途失败都立即终止构建，
# 防止把残缺配置当成 "Automatically update" 提交上去。
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[1]:-${BASH_SOURCE[0]}}")/.." && pwd)"

# ---------------------------------------------------------------- 日志

log()  { printf '\033[32m[build]\033[0m %s\n' "$*"; }
warn() { printf '\033[33m[warn ]\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[31m[error]\033[0m %s\n' "$*" >&2; exit 1; }

# ---------------------------------------------------------------- 下载

# raw.githubusercontent.com 直连；中国大陆等网络环境自动回退镜像。
# 数组为空字符串时表示"不走镜像"，永远第一个尝试。
GH_RAW_BASE="https://raw.githubusercontent.com"
GH_MIRRORS=(
    ""
    "https://gh-proxy.com/"
    "https://ghfast.top/"
)

# fetch <路径或完整URL> <保存路径>
#   参数 1 可以是：
#     - raw 相对路径：owner/repo/branch/file，自动拼 raw.githubusercontent.com
#     - 完整 URL（http/https 开头）：原样使用（镜像前缀仍会叠加，用于加速
#       raw.githubusercontent.com 之外的 GitHub 域名时需自行斟酌）
fetch() {
    local src="$1" dest="$2" i mirror url
    for i in "${!GH_MIRRORS[@]}"; do
        mirror="${GH_MIRRORS[$i]}"
        case "$src" in
            http*) url="${mirror}${src}" ;;
            *)     url="${mirror}${GH_RAW_BASE}/${src}" ;;
        esac
        # -f：4xx/5xx 视为失败；-sS：静默但保留错误；超时防止 CI 卡死
        if curl -fsSL --connect-timeout 8 --max-time 120 "$url" -o "$dest" &&
            [ -s "$dest" ]; then
            log "下载成功（通道 $i）：$url"
            return 0
        fi
        warn "下载失败（通道 $i），尝试下一通道：$url"
    done
    die "全部下载通道均失败：$src"
}

# ---------------------------------------------------------------- 校验

# assert_contains <文件> <grep 模式> <说明>
#   构建产物中必须存在指定内容，否则视为注入失败，立即报错退出。
assert_contains() {
    local file="$1" pattern="$2" desc="$3"
    grep -q -- "$pattern" "$file" ||
        die "产物校验失败：$file 中未找到「$desc」（模式：$pattern）"
}

# assert_not_contains <文件> <grep 模式> <说明>
assert_not_contains() {
    local file="$1" pattern="$2" desc="$3"
    grep -q -- "$pattern" "$file" &&
        die "产物校验失败：$file 中不应存在「$desc」（模式：$pattern）"
    return 0
}

# ---------------------------------------------------------------- 注入

# insert_after_first <目标文件> <锚点ERE> <待插入文件>
#   在目标文件中【首次】匹配锚点 ERE 的行之后插入另一文件的全部内容，原位修改。
#   注意：上游模板中 ";设置规则标志位" 出现两次（头部说明 + 真实规则区），
#   与旧版 subconf.sh 的 `0,/锚点/ r 文件` 行为保持一致，只插第一处。
insert_after_first() {
    local target="$1" anchor="$2" snippet="$3" tmp
    grep -Eq -- "$anchor" "$target" || die "上游模板中未找到锚点：$anchor"
    tmp="$(mktemp)"
    # 锚点通过环境变量传入而非 awk -v：-v 会对值做反斜杠转义处理，
    # 会破坏 ^\[Rule\] 这类正则锚点；ENVIRON 原样透传。
    ANCHOR="$anchor" SNIPPET_FILE="$snippet" awk '
        !done && $0 ~ ENVIRON["ANCHOR"] {
            print
            while ((getline line < ENVIRON["SNIPPET_FILE"]) > 0) print line
            close(ENVIRON["SNIPPET_FILE"])
            done = 1
            next
        }
        { print }
    ' "$target" > "$tmp"
    mv "$tmp" "$target"
}
