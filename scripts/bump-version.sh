#!/usr/bin/env bash
#
# bump-version.sh — 版本号自增
#
# 用法：./bump-version.sh <版本文件路径>
#   读取文件中的 "主.次" 两段版本号，次版本 +1；满 10 进位到主版本（沿用
#   旧仓库规则，保证与历史版本号连续）。结果写回文件并打印到 stdout。
#
# 注意：仅当构建产物内容有变化时由 CI 调用，避免上游无更新时版本号空转。
set -euo pipefail

FILE="${1:?用法: bump-version.sh <版本文件路径>}"
[ -f "$FILE" ] || { echo "版本文件不存在：$FILE" >&2; exit 1; }

# 容错 Windows 编辑器带来的 CRLF
version="$(tr -d '\r' < "$FILE")"

major="${version%%.*}"
minor="${version##*.}"
if [[ ! "$major" =~ ^[0-9]+$ || ! "$minor" =~ ^[0-9]+$ ]]; then
    echo "版本号格式非法：$version（期望 主.次）" >&2
    exit 1
fi

minor=$((minor + 1))
if [ "$minor" -ge 10 ]; then
    major=$((major + 1))
    minor=0
fi

printf '%s.%s\n' "$major" "$minor" > "$FILE"
echo "$major.$minor"
