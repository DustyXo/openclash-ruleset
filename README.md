# OpenClash Ruleset

OpenClash 自定义规则集仓库，自动从 [MetaCubeX/meta-rules-dat](https://github.com/MetaCubeX/meta-rules-dat) 同步合并规则，减少 rule-provider 数量，提高加载效率。

## 目录结构

```
├── .github/workflows/
│   ├── sync-rules.yml        # 每天 UTC 4:00 拉取 MetaCubeX 合并规则 + 构建 .mrs
│   └── build-mrs.yml         # 手动更新 .domain.list 时自动构建 .mrs
├── rules/
│   ├── custom_direct.domain.list   # [自定义] 直连域名列表（已合并到 direct-all）
│   ├── custom_proxy.domain.list    # [自定义] 代理域名列表
│   ├── dev.domain.list             # [自定义] 开发相关域名列表（已合并到 github-all）
│   ├── direct-all.domain.list      # [合并] 国内直连 → 全球直连
│   ├── instant-messaging.domain.list   # [合并] 即时通讯
│   ├── social-media.domain.list        # [合并] 社交媒体
│   ├── ai-services.domain.list         # [合并] AI服务
│   ├── global-streaming.domain.list    # [合并] 国外流媒体
│   ├── game-platforms.domain.list      # [合并] 游戏平台
│   ├── github-all.domain.list          # [合并] GitHub + dev
│   ├── google-all.domain.list          # [合并] 谷歌服务
│   ├── gfw.domain.list              # GFW 列表
│   ├── paypal.domain.list           # PayPal
│   ├── apple.domain.list            # 苹果服务
│   ├── microsoft.domain.list        # 微软服务
│   ├── tiktok.domain.list           # TikTok
│   └── bahamut.domain.list          # Bahamut
├── my-groups.yaml       # OpenClash 主配置文件（策略组 + 规则）
└── README.md
```

## 规则合并对照

| 策略组 | 合并后的规则集 | 来源 |
|---|---|---|
| **全球直连** | `direct-all` | google-cn + category-games@cn + category-game-platforms-download + category-public-tracker + cn + private + geoip:cn + geoip:private + custom_direct |
| **即时通讯** | `instant-messaging` | category-communication + geoip:telegram |
| **社交媒体** | `social-media` | category-social-media-!cn + geoip:twitter + geoip:facebook |
| **AI服务** | `ai-services` | openai + google-gemini + category-ai-!cn |
| **国外流媒体** | `global-streaming` | youtube + netflix + disney + hbo + primevideo + apple-tvplus + spotify + category-emby + category-entertainment + geoip:netflix |
| **游戏平台** | `game-platforms` | steam + category-games |
| **GitHub** | `github-all` | github + dev |
| **谷歌服务** | `google-all` | google + geoip:google |
| **自定义代理** | `custom_proxy` | 手动维护 |

合并前：**39 个 rule-provider** → 合并后：**17 个 rule-provider**

## 工作流程

### 自动同步（每日）
`sync-rules.yml` 每天 UTC 4:00（北京时间 12:00）自动：
1. 从 MetaCubeX 下载对应 `.list` 文件
2. 按策略组合并、去重
3. 用 mihomo 内核构建 `.mrs` 文件
4. 提交推送至仓库

### 手动更新
1. 编辑 `rules/*.domain.list` 文件
2. 推送后 `build-mrs.yml` 自动构建 `.mrs` 文件
3. 路由器 OpenClash 下次更新规则时会拉取最新 `.mrs`

## 自定义规则说明

- `custom_direct.domain.list`：自定义直连域名（已合并到 `direct-all`）
- `custom_proxy.domain.list`：自定义代理域名（独立 rule-provider，未合并）
- `dev.domain.list`：开发者常用域名（已合并到 `github-all`）

编辑后推送即可，GitHub Actions 自动构建 `.mrs`。

## 策略组设计

- **5 个地区节点组**：香港 / 美国 / 日本 / 新加坡 / 台湾（url-test 自动选最优）
- **自动选择**：所有节点中测速选最优
- **全球直连**：DIRECT
- **服务组**：即时通讯、社交媒体、GitHub、AI服务、谷歌 / 苹果 / 微软服务、国外流媒体、TikTok、游戏平台、测速工具 等
- **手动选择** + **漏网之鱼**：Select 类型，可手动切换节点

## 使用方法

### OpenClash 路由器

1. 将 `my-groups.yaml` 上传到路由器 `/etc/openclash/config/` 目录
2. 在 LuCI **服务 → OpenClash → 覆写设置** 新建覆写模块，配置项写入：

```
# 覆写配置
config_file: my-groups.yaml

# 订阅地址（可选，也可在插件设置中配置）
# proxies:
#   - name: Sub-store
#     url: "你的订阅地址"
```

3. 保存后重启 OpenClash

### 自定义添加域名

1. 编辑对应 `.domain.list` 文件，添加域名（一行一个，支持 `+.` 前缀表示域名及子域名）
2. 推送至 GitHub
3. GitHub Actions 自动构建 `.mrs`
4. 路由器 OpenClash 24 小时内自动拉取更新，或手动触发更新

## 与 MetaCubeX 官方规则的关系

本仓库的大部分规则集内容源自 MetaCubeX 官方，优势在于：
- **合并去重**：多个相关规则集合并为一个，OpenClash 只需加载 17 个 rule-provider（原需 39 个）
- **每日同步**：自动跟踪上游更新
- **自定义混合**：可在合并规则中混入自定义域名（如 `custom_direct` 合并进 `direct-all`）