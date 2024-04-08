#!/bin/bash

# 读取版本号
version=$(cat version.txt)
echo "当前版本号为：$version"
# 将版本号从字符串转换为浮点数，并增加0.1
new_version=$(echo "$version + 0.1" | bc)

# 将新版本号写入 version.txt
echo "$new_version" > version.txt

echo "版本号已更新为： $new_version"
