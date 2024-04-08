#!/bin/bash

pwd
ls


version_file="version.txt"

# 检查版本文件是否存在
if [ ! -f "$version_file" ]; then
    echo "版本文件 $version_file 不存在"
    exit 1
fi

# 读取版本号
version=$(cat "$version_file")
echo "当前版本号为：$version"

# 将版本号从字符串转换为浮点数，并增加0.1
new_version=$(echo "$version + 0.1" | bc)

# 将新版本号写入 version.txt
echo "$new_version" > "$version_file"

# 检查写入是否成功
if [ $? -eq 0 ]; then
    echo "版本号已更新为： $new_version"
else
    echo "写入新版本号时出错"
fi
