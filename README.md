# ss-conf

> 自用代理软件配置 — Shadowrocket + Clash 双管线

## 结构

```
ss-conf/
├── shadowrocket/        # Shadowrocket 管线
│   ├── script.sh        # 构建脚本
│   ├── update_version.sh
│   ├── version.txt
│   └── input/           # DIY 规则输入
│       ├── rule.list
│       ├── proxy_group.list
│       └── host.list
│
├── clash/               # Clash 管线
│   ├── subconf.sh       # 构建脚本
│   ├── update_version.sh
│   ├── version.txt
│   └── input/           # DIY 规则输入
│       ├── direct.list
│       ├── proxy.list
│       ├── backhome.list
│       ├── select.list
│       ├── proxy_group.list
│       └── ruleset.list
│
└── dist/                # 自动化构建产物（CDN 直链来源）
    ├── shadowrocket.conf
    └── clash.conf
```

## 使用方式

### Shadowrocket

```
https://raw.githubusercontent.com/LAN-Cliv/ss-conf/main/dist/shadowrocket.conf
```

### Clash

```
https://raw.githubusercontent.com/LAN-Cliv/ss-conf/main/dist/clash.conf
```

### 镜像加速（可选）

```
# Shadowrocket
https://mirror.ghproxy.com/https://raw.githubusercontent.com/LAN-Cliv/ss-conf/main/dist/shadowrocket.conf

# Clash
https://mirror.ghproxy.com/https://raw.githubusercontent.com/LAN-Cliv/ss-conf/main/dist/clash.conf
```

## 维护

- DIY 规则分别在 `shadowrocket/input/` 和 `clash/input/` 目录下维护
- GitHub Actions 每週三 03:00（北京时间）自动构建并推送更新
- 手动触发：在 GitHub Actions 页面点击 `Clash CI` 或 `Shadowrocket CI` → `Run workflow`
