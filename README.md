# ss-conf — 自用 Shadowrocket「回家」规则 & Clash 自定义规则

一套由 GitHub Actions 定期自动构建的代理订阅配置：

- **Shadowrocket（小火箭）**：基于 johnshall 懒人配置，注入回家规则、自定义策略组与 Host 解析，可随时访问家庭内网。
- **Clash**：基于 ACL4SSR 全量模板，注入自定义规则集（直连 / 强制代理 / 手动切换 / 回家 / Amazon）与对应策略组。

---

## 订阅地址

### Shadowrocket（ssconf）

```
https://raw.githubusercontent.com/LAN-Cliv/ss-conf/main/conf/diy.conf
```

> 直连不稳可用镜像加速：
> ```
> https://gh-proxy.com/https://raw.githubusercontent.com/LAN-Cliv/ss-conf/main/conf/diy.conf
> ```

### Clash（clashconf）

```
https://raw.githubusercontent.com/LAN-Cliv/ss-conf/main/conf/clashconf.ini
```

> 直连不稳可用镜像加速：
> ```
> https://gh-proxy.com/https://raw.githubusercontent.com/LAN-Cliv/ss-conf/main/conf/clashconf.ini
> ```

> [!IMPORTANT]
> 2026-10-11 重构后，自定义规则的在线路径从 `clashconf/*.list` 迁移到
> `rules/clash/*.list`。**请在客户端重新更新一次订阅**，否则旧规则文件路径
> 仍会被引用（旧文件已删除，会 404）。

---

## 项目结构

```
ss-conf/
├── .github/workflows/update.yml   # 自动构建 + 变更检测 + 版本号自增（单 workflow，无 push 竞态）
├── scripts/                       # 构建脚本（本地与 CI 共用）
│   ├── lib.sh                     #   公共函数：下载(带镜像回退)、锚点注入、产物校验
│   ├── build-clash.sh             #   生成 conf/clashconf.ini
│   ├── build-shadowrocket.sh      #   生成 conf/diy.conf
│   └── bump-version.sh            #   版本号自增（主.次，次满 10 进位）
├── src/                           # 构建时【内联】进订阅的片段（改完需触发 CI 重新构建）
│   ├── clash/
│   │   ├── ruleset.list           #   自定义 ruleset 引用（含在线 URL）
│   │   └── proxy-group.list       #   自定义策略组定义
│   └── shadowrocket/
│       ├── rules.list             #   注入 [Rule] 段首（优先级最高）
│       ├── proxy-group.list       #   注入 [Proxy Group] 段首
│       └── host.list              #   注入 [Host] 段首
├── rules/                         # 客户端【运行时在线拉取】的规则，URL 必须保持稳定
│   └── clash/
│       ├── direct.list            #   DIY直连
│       ├── proxy.list             #   DIY代理
│       ├── select.list            #   DIY手动
│       ├── backhome.list          #   快点回家
│       └── amazon.list            #   Amazon 购物
├── versions/                      # 两个订阅各自的版本号（CI 自动维护）
│   ├── clash.txt
│   └── shadowrocket.txt
└── conf/                          # 构建产物（CI 自动生成，勿手改）
    ├── clashconf.ini              #   Clash 订阅
    └── diy.conf                   #   Shadowrocket 订阅
```

**`src/` 与 `rules/` 的区别**（也是本仓库最重要的概念）：

| | `src/` | `rules/clash/` |
|---|---|---|
| 注入方式 | 构建时文本内联进订阅文件 | 客户端运行时按 URL 在线拉取 |
| 生效时机 | 客户端更新订阅后 | 客户端刷新规则后，**无需重新构建** |
| URL 稳定性 | 无要求 | **文件名不可随意改动**（ruleset.list 里有硬编码引用） |

---

## 如何添加 Clash 自定义模块

以添加 Netflix 模块为例，共三步：

### 第一步：创建在线规则文件

新建 `rules/clash/netflix.list`（文件名即模块名，创建后不可改名）：

```plaintext
DOMAIN-SUFFIX,netflix.com
DOMAIN-SUFFIX,nflxvideo.net
```

### 第二步：在 src/clash/ruleset.list 中引用

```plaintext
ruleset=🎬 Netflix,https://raw.githubusercontent.com/LAN-Cliv/ss-conf/main/rules/clash/netflix.list
```

> 规则**从上到下优先级递减**，加在 `src/clash/ruleset.list` 里越靠前越优先。

### 第三步：在 src/clash/proxy-group.list 中新增策略组

```plaintext
custom_proxy_group=🎬 Netflix`select`[]🚀 节点选择`[]♻️ 自动选择`[]🇸🇬 狮城节点`[]🇭🇰 香港节点`[]🇨🇳 台湾节点`[]🇯🇵 日本节点`[]🇺🇲 美国节点`[]🇰🇷 韩国节点`[]🚀 手动切换`[]DIRECT
```

> 组名 `🎬 Netflix` 必须与 ruleset.list 中的完全一致。

### 触发构建

push 到 main 后在 GitHub Actions 手动触发 `auto update`（或等到周三凌晨自动构建）。构建脚本会校验锚点与注入结果，任何一步失败都会中断而不会提交残缺配置。

---

## 如何添加 Shadowrocket 自定义规则

Shadowrocket 侧规则是构建时内联的，直接编辑：

- `src/shadowrocket/rules.list` — 追加一行规则，如 `DOMAIN-SUFFIX,example.com,BACKHOME`
- `src/shadowrocket/host.list` — 追加域名解析
- `src/shadowrocket/proxy-group.list` — 策略组（一般不用动）

然后触发构建即可。

---

## 本地构建与测试

```bash
# 生成两个订阅（版本号取自 versions/ 目录）
./scripts/build-clash.sh "$(cat versions/clash.txt)"
./scripts/build-shadowrocket.sh "$(cat versions/shadowrocket.txt)"
```

脚本无 wget 依赖，仅需 `bash` + `curl` + `sed` + `awk`；下载自动尝试直连 → gh-proxy.com → ghfast.top，中国大陆网络可直接运行。

---

## 自动更新机制

GitHub Actions 每周三北京时间 03:00 运行一次（`.github/workflows/update.yml`）：

1. 用当前版本号试构建两个订阅；
2. 与仓库中现有产物逐字节对比，**无变化则不提交**（版本号不空转）；
3. 有变化的订阅独立提升版本号并重建（客户端靠首行版本号感知更新）；
4. 以 `chore(auto): clash vX.Y / shadowrocket vA.B` 格式提交，commit message 可回溯。

## 上游数据源

| 平台 | 数据源 |
|------|--------|
| Shadowrocket | [johnshall/Shadowrocket-ADBlock-Rules-Forever](https://github.com/johnshall/Shadowrocket-ADBlock-Rules-Forever) |
| Clash | [ACL4SSR/ACL4SSR](https://github.com/ACL4SSR/ACL4SSR) |

## 2026-10-11 重构修复记录

- `rules/clash/proxy.list`、`direct.list`：全角 `＃PT站点` → 正常 `#` 注释（全角井号不被解析为注释，会导致整份规则集告警）。
- `rules/clash/proxy.list`：`SRC-IP-CIDR,3.163.125.108/32` → `IP-CIDR`（SRC 匹配客户端源 IP，写公网地址永远无法命中，属失效规则）。
- 构建脚本全面加 `set -euo pipefail` + 产物校验：上游下载失败、锚点丢失时直接报错，不再提交残缺配置。
- 消除双 workflow 同时 push 的竞态；版本号只在内容变化时提升；commit message 携带版本号。
- README 中已失效的 `mirror.ghproxy.com` 加速链接更新为 `gh-proxy.com`。
