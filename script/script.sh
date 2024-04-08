#!/bin/bash

# 下载文件
wget https://johnshall.github.io/Shadowrocket-ADBlock-Rules-Forever/lazy_group.conf -O diy.conf

# 提取信息
rule_file="rule.list"
proxy_group_file="proxy_group.list"
host_file="host.list"

# 获取版本号文件
version_file="version.txt"

# 读取当前版本号
current_version=$(cat "$version_file")

# 添加版本号注释
sed -i "1i #当前版本号为：${current_version}" diy.conf
echo "配置已更新，当前版本号为：${current_version}"

# 修改配置文件

# 删除局域网相关的192.168.0.0/16
sed -i 's/192\.168\.0\.0\/16,//' diy.conf

# 在 [Rule] 下插入内容
sed -i "/\[Rule\]/r $rule_file" diy.conf

# 在 [Proxy Group] 下插入内容
sed -i "/\[Proxy Group\]/r $proxy_group_file" diy.conf

# 在 [Host] 下插入内容
sed -i "/\[Host\]/r $host_file" diy.conf
