#!/bin/bash

# 下载文件
wget -p https://raw.githubusercontent.com/ACL4SSR/ACL4SSR/master/Clash/config/ACL4SSR_Online_Full.ini -O clashconf.ini

# 提取信息
ruleset_file="ruleset.list"
proxy_group_file="proxy_group.list"

# 检查文件是否存在
for file in "$ruleset_file" "$proxy_group_file"; do
    if [ ! -f "$file" ]; then
        echo "文件 $file 不存在"
        exit 1
    fi
done

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
sed -i "s/${original_text}/${replacement_text}/g" "$ruleset_file"

#给github raw加速
sed -i 's|https://raw.githubusercontent|https://mirror.ghproxy.com/https://raw.githubusercontent|g' "$ruleset_file"

echo "配置已更新"
