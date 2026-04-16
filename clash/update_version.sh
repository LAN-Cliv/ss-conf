#!/bin/bash
#
# clash/update_version.sh
# 自动递增版本号并写入 clash/version.txt
# 用法: ./update_version.sh
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION_FILE="${SCRIPT_DIR}/version.txt"

# 读取当前版本号，格式: X.Y
read_current_version() {
    if [[ -f "$VERSION_FILE" ]]; then
        cat "$VERSION_FILE"
    else
        echo "0.1"
    fi
}

# 递增版本号 (X.Y → X.Y+1)
increment_version() {
    local ver="$1"
    local major minor
    IFS='.' read -r major minor <<< "$ver"
    minor=$((minor + 1))
    echo "${major}.${minor}"
}

# 更新时间戳 (YYYY-MM-DD HH:MM:SS)
get_timestamp() {
    date "+%Y-%m-%d %H:%M:%S"
}

# 主逻辑
current_ver=$(read_current_version)
new_ver=$(increment_version "$current_ver")
timestamp=$(get_timestamp)

# 写入文件
echo "$new_ver" > "$VERSION_FILE"

echo "[Clash] 版本: ${current_ver} → ${new_ver}"
echo "[Clash] 更新时间: ${timestamp}"
