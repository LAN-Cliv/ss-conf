#!/bin/bash

# 下载文件
wget -p https://raw.githubusercontent.com/ACL4SSR/ACL4SSR/master/Clash/config/ACL4SSR_Online_Full.ini -O clashconf.ini

# 提取信息
ruleset_file="ruleset.list"
proxy_group_file="proxy_group.list"

# 如果版本号文件不存在，创建并设置版本号为1.0
version_file="version.txt"
if [ ! -f "$version_file" ]; then
    echo "1.0" > "$version_file"
fi

# 读取当前版本号
current_version=$(cat "$version_file")

# 更新版本号
next_version=$(awk '{print $1 + 0.1}' <<< "$current_version")

# 添加版本号注释
sed -i "1i #当前版本号为：${next_version}" clashconf.ini

# 更新版本号文件
echo "$next_version" > "$version_file"

echo "配置已更新，当前版本号为：${next_version}"



# 修改配置文件
# 在插入内容
sed -i '0,/^;设置规则标志位/ { /^;设置规则标志位/ r '"$ruleset_file"'
}' clashconf.ini

# 插入内容
sed -i "/custom_proxy_group=♻️ 自动选择\`url-test\`.\*\`http:\/\/www.gstatic.com\/generate_204\`300,,50/r $proxy_group_file" clashconf.ini


# 定义原始文本和替换文本
original_text="♻️ 自动选择\`url-test\`.*\`http"
replacement_text="♻️ 自动选择\`url-test\`(^(?!.*(回家|home|back)).*)\`http"

# 使用sed命令在文件中进行替换
sed -i "s/${original_text}/${replacement_text}/g" clashconf.ini


# 替换的字符串
replace_str="https://raw.gitmirror.com"

# 使用 sed 直接在原文件上进行替换
sed -i "s|https://raw.githubusercontent.com|${replace_str}|g" clashconf.ini

echo "配置已更新"
