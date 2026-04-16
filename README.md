# 自用小火箭回家规则 && Clash 自定义规则

---

## 订阅地址

### Shadowrocket（ssconf）

```
https://raw.githubusercontent.com/LAN-Cliv/ss-conf/main/conf/diy.conf
```

> 推荐使用代理加速：
> ```
> https://mirror.ghproxy.com/https://raw.githubusercontent.com/LAN-Cliv/ss-conf/main/conf/diy.conf
> ```

### Clash（clashconf）

```
https://raw.githubusercontent.com/LAN-Cliv/ss-conf/main/conf/clashconf.ini
```

> 推荐使用代理加速：
> ```
> https://mirror.ghproxy.com/https://raw.githubusercontent.com/LAN-Cliv/ss-conf/main/conf/clashconf.ini
> ```

---

## 如何添加自定义模块

Clash 配置采用**规则 + 策略组**两层结构，添加新模块需要完成以下三步：

### 第一步：创建规则文件

在 `clashconf/` 目录下新建一个 `.list` 文件，文件名即模块名。

例如，创建 `amazon.list`：

```bash
# 示例内容
DOMAIN-SUFFIX,amazon.com
DOMAIN-SUFFIX,amazon.co.uk
DOMAIN-SUFFIX,amazon.co.jp
```

### 第二步：在 ruleset.list 中引用新规则

打开 `clashconf/ruleset.list`，在适当位置新增一行：

```plaintext
ruleset={Emoji+规则名},https://raw.githubusercontent.com/LAN-Cliv/ss-conf/main/clashconf/{规则名}.list
```

> **格式说明**
> - `{Emoji+规则名}` — 显示名称，带 Emoji 便于在客户端中识别
> - `{规则名}.list` — 需与第一步创建的文件名保持一致
> - 规则行**从上到下**优先级递减，建议将自定义规则放在靠前位置

### 第三步：在 proxy_group.list 中新增策略组

打开 `clashconf/proxy_group.list`，新增策略组定义：

```plaintext
custom_proxy_group={Emoji+规则名}`select`[]🚀 节点选择`[]♻️ 自动选择`[]🇸🇬 狮城节点`[]🇭🇰 香港节点`[]🇨🇳 台湾节点`[]🇯🇵 日本节点`[]🇺🇲 美国节点`[]🇰🇷 韩国节点`[]🚀 手动切换`[]DIRECT
```

> **格式说明**
> - 第一个参数 `{Emoji+规则名}` 需与 ruleset.list 中保持一致
> - `select` 表示该组为手动选择策略组
> - `[]` 后的内容为可选的代理节点/策略组列表，用户点击时可直接切换

### 完整示例：添加 Amazon 购物模块

1. **创建文件** `clashconf/amazon.list`
   ```plaintext   DOMAIN-SUFFIX,amazon.com
   DOMAIN-SUFFIX,amazon.co.jp
   ```
2. **在 ruleset.list 中添加**
   ```plaintext
   ruleset=🛒 Amazon,https://raw.githubusercontent.com/LAN-Cliv/ss-conf/main/clashconf/amazon.list
   ```
3. **在 proxy_group.list 中添加**
   ```plaintext
   custom_proxy_group=🛒 Amazon`select`[]🚀 节点选择`[]♻️ 自动选择`[]🇸🇬 狮城节点`[]🇭🇰 香港节点`[]🇨🇳 台湾节点`[]🇯🇵 日本节点`[]🇺🇲 美国节点`[]🇰🇷 韩国节点`[]🚀 手动切换`[]DIRECT
   ```

---

## 项目结构

```
ss-conf/
├── clashconf/              # Clash 配置模块
│   ├── amazon.list         # 自定义：Amazon 购物
│   ├── backhome.list       # 自定义：回家规则
│   ├── direct.list         # 自定义：直连规则
│   ├── proxy.list          # 自定义：强制代理规则
│   ├── proxy_group.list    # 策略组定义
│   ├── ruleset.list        # 规则集引用
│   └── select.list         # 自定义：手动切换规则
├── conf/                   # 最终发布的配置文件
│   ├── clashconf.ini       # Clash 订阅输出
│   └── diy.conf            # Shadowrocket 订阅输出
└── script/                 # Shadowrocket 构建脚本
```

> 配置文件由 GitHub Actions 每周自动从上游规则拉取最新版本，并与自定义规则合并生成。详情参见 `.github/workflows/`。

---

## 上游数据源

| 平台 | 数据源 |
|------|--------|
| Shadowrocket | [johnshall/Shadowrocket-ADBlock-Rules-Forever](https://github.com/johnshall/Shadowrocket-ADBlock-Rules-Forever) |
| Clash | [ACL4SSR/ACL4SSR](https://github.com/ACL4SSR/ACL4SSR) |
