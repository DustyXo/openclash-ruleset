# openclash-ruleset

OpenClash 自定义规则集仓库，配合覆写模块实现节点订阅转换——用你自己的策略分组和分流规则替代订阅自带的配置。

## 快速开始

1. Fork 本仓库，修改 `rules/*.list` 添加你需要的域名
2. 上传 `config/my-groups.yaml` 到路由器 `/etc/openclash/config/`
3. 在 LuCI **服务 → OpenClash → 覆写设置** 新建模块，内容同 `overwrite/my-overwrite.conf`
4. 设置环境变量 `EN_KEY` = 你的订阅 URL
5. Commit → Apply → 重启内核

## 文件结构

```
openclash-ruleset/
├── config/my-groups.yaml          # 独立配置文件（策略分组 + 规则）
├── overwrite/my-overwrite.conf    # 覆写模块（告诉 OpenClash 用 my-groups.yaml）
├── rules/
│   └── dev.list                   # 开发者域名规则集
├── .github/workflows/build-mrs.yml # 自动编译 .list → .mrs
└── README.md
```

## 架构

```
┌─────────────────────────┐
│ my-overwrite.conf       │  ← LuCI 覆写模块
│  CONFIG_FILE            │  → 指向 my-groups.yaml
│  [Overwrite]            │  → 替换订阅 URL
└────────┬────────────────┘
         ▼
┌─────────────────────────┐
│ my-groups.yaml          │  ← 独立配置文件
│  proxy-providers        │    引用订阅节点
│  proxy-groups           │    策略分组（地区组 + 服务组）
│  rule-providers         │    规则集来源（本仓库 + MetaCubeX 官方）
│  rules                  │    分流规则
└────────┬────────────────┘
         ▼
┌─────────────────────────┐
│ Mihomo 内核             │  → 运行生效
└─────────────────────────┘
```

### 策略组设计

- **5 个地区节点组**：香港/美国/日本/新加坡/台湾（url-test 自动选最优）
- **自动选择**：所有节点中测速选最优
- **全球直连**：DIRECT
- **服务组**：即时通讯、社交媒体、GitHub、AI 服务、谷歌/苹果/微软服务、国外流媒体、TikTok、游戏平台、测速工具 等
- **手动选择** + **漏网之鱼**：Select 类型，可手动切换节点

### 规则集来源

| 来源 | 数量 | 更新方式 |
|------|------|----------|
| MetaCubeX 官方 | 41 个 .mrs | 每 24 小时自动拉取 |
| 本仓库 | dev.list | 每 24 小时自动拉取 |
| 本仓库 | custom_direct/proxy.list | 每 24 小时自动拉取 |

## 规则文件格式

用 `classical` + `text` 格式，每行一条规则：

```
DOMAIN-SUFFIX,bitbucket.org
DOMAIN-SUFFIX,docker.io
DOMAIN-KEYWORD,github
IP-CIDR,1.2.3.0/24
```

修改 `rules/*.list` 后 push，GitHub Actions 自动编译 `.mrs`。

## 自定义规则

在 LuCI **服务 → OpenClash → 覆写设置 → 规则** 中添加：

```
- DOMAIN-SUFFIX,brew.sh,GitHub
- DOMAIN-SUFFIX,gitlab.com,GitHub
```

## DNS 配置

DNS 由 LuCI 页面设置管理，覆写模块不干预。推荐：

1. **插件设置 → DNS 设置**：自定义 DNS 开启，追加上游 DNS 开启
2. **覆写设置 → DNS 设置**：Nameserver 添加运营商 DNS（如 `dhcp://`），Fallback 清空
