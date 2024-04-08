#!/bin/bash

version_file="version.txt"

# 读取版本号并删除回车符
version=$(cat "$version_file" | tr -d '\r')

# 将版本号拆分为主版本号和次版本号
major=$(echo "$version" | cut -d. -f1)
minor=$(echo "$version" | cut -d. -f2)

# 将次版本号加上0.1，并四舍五入至小数点后一位
minor=$(echo "$minor + 0.1" | bc)
minor=$(printf "%.1f" "$minor")

# 如果次版本号超过9，则主版本号加1，次版本号重置为0
if (( $(echo "$minor >= 10" | bc -l) )); then
    major=$((major + 1))
    minor=0
fi

# 组装新版本号
new_version="$major.$minor"

# 将新版本号写入 version.txt
echo "$new_version" > "$version_file"


echo "版本号已更新为： $new_version"
