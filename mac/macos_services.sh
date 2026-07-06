#!/bin/bash
# ============================================================
# macOS 后台服务管理 — 最终版
# 针对 macOS 15.7 Sequoia + Intel i9
# ============================================================
#
# ⚠️  已知风险（已验证）：
#
# com.apple.inputanalyticsd 已从列表中移除（已验证在 macOS 15.7 上
# 参与蓝牙键盘类型识别，关闭后无线键盘符号映射异常）
#
# com.apple.suggestd, com.apple.DictationIM, com.apple.proactived
# 已从列表中移除（与输入法/键盘框架有耦合，为安全起见保留）
#
# 重启建议：关闭任何 Level 1-2 的服务后建议重启电脑使更改生效
# ============================================================

set -euo pipefail

USER_UID=501

declare -a SERVICES=()

# Level 1: 广告追踪 + 分析上报 (0-8)
SERVICES+=("com.apple.ap.adprivacyd|广告隐私管理|零风险")
SERVICES+=("com.apple.ap.promotedcontentd|推广内容引擎|零风险")
SERVICES+=("com.apple.analyticsagent|分析数据上报|零风险，等同系统关'共享分析'")
SERVICES+=("com.apple.geoanalyticsd|地理位置分析|零风险")
SERVICES+=("com.apple.diagnostics_agent|诊断数据收集|零风险")
SERVICES+=("com.apple.diagnosticextensionsd|诊断扩展服务|零风险")
SERVICES+=("com.apple.diagnosticspushd|诊断推送服务|零风险")
SERVICES+=("com.apple.feedbackd|反馈收集助手|零风险")
#
# ⚠️  以下为 system domain 的零风险 telemetry daemon，不在本脚本管理范围内
#     如需关闭，请手动执行对应命令（重启后失效，需再次禁用）：
#
#   # 系统分析上报（等同系统设置关"共享分析"）
#   sudo launchctl disable system/com.apple.analyticsd
#   sudo launchctl disable system/com.apple.ecosystemanalyticsd
#
#   # 无线诊断数据上报（WirelessDiagnostics.framework）
#   sudo launchctl disable system/com.apple.awdd
#
#   # RTC 通信报告
#   sudo launchctl disable system/com.apple.rtcreportingd
#
#   # 网络症状诊断上报
#   sudo launchctl disable system/com.apple.symptomsd
#   sudo launchctl disable system/com.apple.symptomsd-diag
#
#   # 音频分析上报
#   sudo launchctl disable system/com.apple.audioanalyticsd
#
#   # WiFi 分析上报
#   sudo launchctl disable system/com.apple.wifianalyticsd
#
#   # USB-C 遥测上报
#   sudo launchctl disable system/com.apple.usbctelemetryd
#
#   # BridgeOS 报告（仅 T2/M1+ Mac，iMac20,2 无此硬件但 daemon 仍在运行）
#   sudo launchctl disable system/com.apple.bosreporter
#   sudo launchctl disable system/com.apple.boswatcher
#
#   # GateKeeper 状态日志上报（shell 脚本，每周跑一次）
#   sudo launchctl disable system/com.apple.gkreport
#
#   # 系统诊断统计（spindump/tailspind — 崩溃日志统计）
#   sudo launchctl disable system/com.apple.spindump
#   sudo launchctl disable system/com.apple.tailspind
#   sudo launchctl disable system/com.apple.revisiond
#
#   # 诊断服务
#   sudo launchctl disable system/com.apple.diagnosticd
#   sudo launchctl disable system/com.apple.diagnosticservicesd
#   sudo launchctl disable system/com.apple.signpost.signpost_reporter
#   sudo launchctl disable system/com.apple.CrashReporterSupportHelper
#   sudo launchctl disable system/com.apple.osanalytics.osanalyticshelper
#   sudo launchctl disable system/com.apple.logd_reporter
#
#   # 系统完整性保护报告
#   sudo launchctl disable system/com.apple.csrutil.report
#
#   恢复方法：sudo launchctl enable system/com.apple.xxx

# Level 2: Siri 全家桶 (9-24)
SERVICES+=("com.apple.siriactionsd|Siri 动作处理|关掉后 Siri 不可用")
SERVICES+=("com.apple.siriknowledged|Siri 知识引擎|Siri 依赖项")
SERVICES+=("com.apple.siriinferenced|Siri 推理引擎|Siri 依赖项")
SERVICES+=("com.apple.sirittsd|Siri 语音合成|Siri 依赖项")
SERVICES+=("com.apple.SiriTTSTrainingAgent|Siri 语音训练|Siri 依赖项")
SERVICES+=("com.apple.siri-distributed-evaluation|Siri 分布式评估|Siri 依赖项")
SERVICES+=("com.apple.siri.context.service|Siri 上下文服务|Siri 依赖项")
SERVICES+=("com.apple.assistant_service|Siri 助理服务|Siri 依赖项")
SERVICES+=("com.apple.assistant_cdmd|Siri 跨设备同步|Siri 依赖项")
SERVICES+=("com.apple.assistantd|Siri 守护进程|Siri 依赖项")
SERVICES+=("com.apple.parsecd|Siri 建议解析|Siri 依赖项")
SERVICES+=("com.apple.parsec-fbf|Siri 建议反馈|Siri 依赖项")
SERVICES+=("com.apple.corespeechd|核心语音识别|语音识别依赖")
SERVICES+=("com.apple.SpeechRecognitionCore.brokerd|语音识别核心|语音识别依赖")

# Level 3: Apple 智能 / ML 引擎 (25-42)
SERVICES+=("com.apple.intelligenceplatformd|Apple Intelligence 平台|Sequoia AI，Intel 上效果有限")
SERVICES+=("com.apple.generativeexperiencesd|生成式 AI 体验|Sequoia 新服务")
SERVICES+=("com.apple.textunderstandingd|文本理解引擎|AI 文本分析")
SERVICES+=("com.apple.ciphermld|加密 ML 模型|ML 推理服务")
SERVICES+=("com.apple.naturallanguaged|自然语言处理|NLP 服务")
SERVICES+=("com.apple.translationd|系统翻译服务|关掉后右键翻译不可用")
SERVICES+=("com.apple.duetexpertd|设备协同学习|跨设备行为分析")
SERVICES+=("com.apple.ContextStoreAgent|上下文数据收集|行为上下文记录")
SERVICES+=("com.apple.knowledge-agent|知识图谱代理|学习用户习惯")
SERVICES+=("com.apple.knowledgeconstructiond|知识图谱构建|知识库构建")
SERVICES+=("com.apple.mlhostd|ML 运行时主机|机器学习服务")
SERVICES+=("com.apple.mlruntimed|ML 运行时守护|机器学习服务")
SERVICES+=("com.apple.metrickitd|性能指标收集|App 性能数据")
SERVICES+=("com.apple.milod|位置学习|'我在哪'位置引擎")
SERVICES+=("com.apple.photoanalysisd|照片场景分析|关掉后照片人物/场景分类失效")
SERVICES+=("com.apple.recentsd|最近项目|最近使用记录")

# Level 4: 系统 App 后台 (43-50)
SERVICES+=("com.apple.newsd|新闻 App 后台|关掉后新闻不更新")
SERVICES+=("com.apple.sportsd|体育比分后台|关掉后体育不更新")
SERVICES+=("com.apple.watchlistd|关注列表|关注列表功能")
SERVICES+=("com.apple.tipsd|提示 App 后台|系统提示功能")
SERVICES+=("com.apple.shazamd|Shazam 听歌识曲|控制中心 Shazam 按钮失效")
SERVICES+=("com.apple.homeenergyd|家庭能源数据|关掉后家庭 App 能源不更新")
SERVICES+=("com.apple.replayd|屏幕录制相关|关掉后录屏可能不可用")
SERVICES+=("com.apple.noticeboard.agent|公告板服务|通知中心")

# Level 5: 媒体/商店/游戏 (51-61)
SERVICES+=("com.apple.appstorecomponentsd|App Store 组件|商店组件服务")
SERVICES+=("com.apple.amsaccountsd|Apple 媒体账户|Apple Music/TV 账户")
SERVICES+=("com.apple.amsengagementd|Apple 媒体互动分析|媒体使用分析")
SERVICES+=("com.apple.amsondevicestoraged|Apple 设备存储|媒体离线缓存")
SERVICES+=("com.apple.storeaccountd|商店账户服务|商店账户")
SERVICES+=("com.apple.storeassetd|商店资源下载|商店资源管理")
SERVICES+=("com.apple.storedownloadd|商店下载管理|商店下载")
SERVICES+=("com.apple.storelegacy|旧版商店兼容|旧商店服务")
SERVICES+=("com.apple.storeuid|商店 UI 服务|商店界面代理")
SERVICES+=("com.apple.gamed|Game Center|关掉后游戏中心不可用")
SERVICES+=("com.apple.gamecontroller.gamecontrolleragentd|游戏手柄支持|游戏手柄驱动")

# Level 6: 其他非必要 (62-70)
SERVICES+=("com.apple.betaenrollmentagent|Beta 版注册|Beta 计划注册")
SERVICES+=("com.apple.appleseed.seedusaged|Seed 使用数据|Beta 使用统计")
SERVICES+=("com.apple.assessmentagent|评估代理|系统评估")
SERVICES+=("com.apple.avatarsd|头像同步|iMessage 头像")
SERVICES+=("com.apple.askpermissiond|跨设备权限|权限询问")
SERVICES+=("com.apple.backgroundassets.user|后台资源下载|后台下载资源")
SERVICES+=("com.apple.bookassetd|图书资源|图书 App 资源")
SERVICES+=("com.apple.bookdatastored|图书数据|图书 App 数据")
SERVICES+=("com.apple.ckdiscretionaryd|CloudKit 按需同步|CloudKit 后台同步")

TOTAL=${#SERVICES[@]}

LVL_START=(0  8  22  40  48  59)
LVL_END=(  8  22  40  48  59  $TOTAL)
LVL_NAMES=(
  "广告追踪 + 分析上报"
  "Siri 全家桶"
  "Apple 智能 / ML 引擎"
  "系统 App 后台"
  "媒体 / 商店 / 游戏"
  "其他非必要服务"
)

get_label() { echo "${1%%|*}"; }
get_desc()  { local r="${1#*|}"; echo "${r%%|*}"; }
get_risk()  { local r="${1#*|}"; r="${r#*|}"; echo "${r%%|*}"; }

is_disabled() {
  local label="$1"
  # 先查 print-disabled 列表（服务即使没加载也能查到）
  if launchctl print-disabled "gui/$USER_UID" 2>/dev/null | grep -q "\"$label\" => disabled"; then
    return 0
  fi
  # 备选: 查 print（服务已加载时）
  if launchctl print "gui/$USER_UID/$label" 2>/dev/null | grep -q "disabled = 1"; then
    return 0
  fi
  return 1
}

disable_one() {
  local label="$1" desc="$2" risk="$3"
  if is_disabled "$label"; then printf "  ⏭  已关闭: %s (%s)\n" "$label" "$desc"; return; fi
  if launchctl disable "gui/$USER_UID/$label" 2>/dev/null; then
    printf "  ✅ 已关闭: %s (%s)\n" "$label" "$desc"
  else
    printf "  ❌ 失败: %s\n" "$label"
  fi
}

enable_one() {
  local label="$1" desc="$2"
  if ! is_disabled "$label"; then printf "  ⏭  已启用: %s (%s)\n" "$label" "$desc"; return; fi
  if launchctl enable "gui/$USER_UID/$label" 2>/dev/null; then
    printf "  ✅ 已恢复: %s (%s)\n" "$label" "$desc"
  else
    printf "  ❌ 恢复失败: %s\n" "$label"
  fi
}

parse_nums() {
  local input="$1" max="${2:-999}" part n s e
  local result=""
  local IFS=','
  for part in $input; do
    part="$(echo "$part" | xargs)"
    if [[ "$part" =~ ^([0-9]+)-([0-9]+)$ ]]; then
      s="${BASH_REMATCH[1]}"; e="${BASH_REMATCH[2]}"
      for ((n=s; n<=e && n<=max; n++)); do result="$result $n"; done
    elif [[ "$part" =~ ^[0-9]+$ ]] && [ "$part" -ge 1 ] && [ "$part" -le "$max" ]; then
      result="$result $part"
    fi
  done
  echo "$result" | tr ' ' '\n' | sort -n -u | tr '\n' ' '
}

case "${1:-}" in
  status)
    echo "=== macOS 后台服务状态 ==="
    for ((i=0; i<TOTAL; i++)); do
      svc="${SERVICES[$i]}"
      label="$(get_label "$svc")"
      desc="$(get_desc "$svc")"
      st="$(is_disabled "$label" && echo "已禁用" || echo "启用中")"
      lv=1; for ((l=0; l<6; l++)); do [ "$i" -ge "${LVL_START[$l]}" ] && [ "$i" -lt "${LVL_END[$l]}" ] && { lv=$((l+1)); break; }; done
      echo "L$lv $st $label ($desc)"
    done
    ;;

  enable|restore)
    for ((i=0; i<TOTAL; i++)); do
      svc="${SERVICES[$i]}"
      enable_one "$(get_label "$svc")" "$(get_desc "$svc")"
    done
    ;;

  *)
    # 一次性查询所有服务状态并缓存
    declare -a DISABLED_CACHE
    for ((i=0; i<TOTAL; i++)); do
      label="$(get_label "${SERVICES[$i]}")"
      if is_disabled "$label"; then
        DISABLED_CACHE[$i]=1
      else
        DISABLED_CACHE[$i]=0
      fi
    done

    # 计算各级别的禁用计数
    LVL_DISABLED=(0 0 0 0 0 0)
    for ((i=0; i<TOTAL; i++)); do
      if [ "${DISABLED_CACHE[$i]}" -eq 1 ]; then
        for ((l=0; l<6; l++)); do
          [ "$i" -ge "${LVL_START[$l]}" ] && [ "$i" -lt "${LVL_END[$l]}" ] && { LVL_DISABLED[$l]=$((LVL_DISABLED[$l] + 1)); break; }
        done
      fi
    done

    while true; do
      clear
      echo "===== macOS 服务管理 (macOS $(sw_vers -productVersion)) ====="
      echo ""
      for ((l=0; l<6; l++)); do
        lvl=$((l+1))
        name="${LVL_NAMES[$l]}"
        total_lvl=$((LVL_END[l] - LVL_START[l]))
        d=${LVL_DISABLED[$l]}
        if [ "$d" -eq 0 ]; then        st="🟢全部启用"
        elif [ "$d" -eq "$total_lvl" ]; then st="🔴全部关闭"
        else                            st="🟡${d}/${total_lvl}"
        fi
        printf "  %d  %s  %s\n" "$lvl" "$name" "$st"
      done
      echo ""
      echo "  s. 查看所有服务状态"
      echo "  a. 恢复所有服务"
      echo "  q. 退出"
      echo ""
      echo "  进入层级: 1, 1-3, 1,3,5"
      echo "  直接关闭: d1-6, d1,3,5, d1-3"
      echo ""
      printf "> "
      read -r choice

      case "$choice" in
        s|S)
          clear
          echo "===== 所有服务状态 ====="
          echo ""
          for ((i=0; i<TOTAL; i++)); do
            svc="${SERVICES[$i]}"
            label="$(get_label "$svc")"
            desc="$(get_desc "$svc")"
            if [ "${DISABLED_CACHE[$i]}" -eq 1 ]; then st="已禁用"; else st="启用中"; fi
            lv=1; for ((l=0; l<6; l++)); do [ "$i" -ge "${LVL_START[$l]}" ] && [ "$i" -lt "${LVL_END[$l]}" ] && { lv=$((l+1)); break; }; done
            echo "L$lv $st $label ($desc)"
          done
          echo ""
          printf "按回车返回..."
          read -r
          ;;

        a|A)
          echo ""
          printf "确认恢复所有服务？(y/n): "
          read -r confirm
          if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
            echo ""
            for ((i=0; i<TOTAL; i++)); do
              svc="${SERVICES[$i]}"
              label="$(get_label "$svc")"
              desc="$(get_desc "$svc")"
              if [ "${DISABLED_CACHE[$i]}" -eq 1 ]; then
                enable_one "$label" "$desc"
                DISABLED_CACHE[$i]=0
              fi
            done
            for ((l=0; l<6; l++)); do LVL_DISABLED[$l]=0; done
          fi
          echo ""
          printf "按回车返回..."
          read -r
          ;;

        q|Q) echo "退出"; exit 0 ;;

        d*)
          raw="${choice#d}"
          nums=$(parse_nums "$raw" 6)
          if [ -z "$nums" ]; then echo "无效"; sleep 1; continue; fi
          echo ""
          printf "确认关闭？(y/n): "
          read -r confirm
          if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
            echo ""
            for n in $nums; do
              l=$((n-1))
              echo "--- ${LVL_NAMES[$l]} ---"
              for ((i=LVL_START[l]; i<LVL_END[l]; i++)); do
                svc="${SERVICES[$i]}"
                label="$(get_label "$svc")"
                desc="$(get_desc "$svc")"
                risk="$(get_risk "$svc")"
                if [ "${DISABLED_CACHE[$i]}" -eq 0 ]; then
                  disable_one "$label" "$desc" "$risk"
                  DISABLED_CACHE[$i]=1
                fi
              done
              LVL_DISABLED[$l]=$((LVL_END[l] - LVL_START[l]))
            done
            echo "完成"
          fi
          echo ""
          printf "按回车返回..."
          read -r
          ;;

        *)
          nums=$(parse_nums "$choice" 6)
          if [ -z "$nums" ]; then echo "无效"; sleep 1; continue; fi
          for n in $nums; do
            l=$((n-1))
            while true; do
              clear
              name="${LVL_NAMES[$l]}"
              start_idx=${LVL_START[$l]}; end_idx=${LVL_END[$l]}
              echo "===== Level $n: $name ====="
              echo ""
              printf "%-4s %-8s %-44s %s\n" "序号" "状态" "服务名" "描述"
              for ((i=start_idx; i<end_idx; i++)); do
                svc="${SERVICES[$i]}"
                label="$(get_label "$svc")"
                desc="$(get_desc "$svc")"
                if [ "${DISABLED_CACHE[$i]}" -eq 1 ]; then st="已禁用"; else st="启用中"; fi
                idx=$((i - start_idx + 1))
                printf "%-4d %-8s %-44s %s\n" "$idx" "$st" "$label" "$desc"
              done
              echo ""
              echo "  1-$((end_idx - start_idx)) 切换服务 (支持: 3 或 1,3,5 或 3-7)"
              echo "  a. 关闭全部 | b. 恢复全部 | 0. 返回"
              echo ""
              printf "> "
              read -r action

              case "$action" in
                a|A)
                  echo ""
                  printf "确认关闭全部？(y/n): "
                  read -r confirm
                  if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
                    echo ""
                    for ((i=start_idx; i<end_idx; i++)); do
                      svc="${SERVICES[$i]}"
                      label="$(get_label "$svc")"
                      desc="$(get_desc "$svc")"
                      risk="$(get_risk "$svc")"
                      if [ "${DISABLED_CACHE[$i]}" -eq 0 ]; then
                        disable_one "$label" "$desc" "$risk"
                        DISABLED_CACHE[$i]=1
                      fi
                    done
                    LVL_DISABLED[$l]=$((end_idx - start_idx))
                  fi
                  echo ""
                  printf "按回车返回..."
                  read -r
                  ;;
                b|B)
                  echo ""
                  for ((i=start_idx; i<end_idx; i++)); do
                    svc="${SERVICES[$i]}"
                    label="$(get_label "$svc")"
                    desc="$(get_desc "$svc")"
                    if [ "${DISABLED_CACHE[$i]}" -eq 1 ]; then
                      enable_one "$label" "$desc"
                      DISABLED_CACHE[$i]=0
                    fi
                  done
                  LVL_DISABLED[$l]=0
                  echo ""
                  printf "按回车返回..."
                  read -r
                  ;;
                0) break ;;
                *)
                  sub_nums=$(parse_nums "$action" $((end_idx - start_idx)))
                  if [ -z "$sub_nums" ]; then echo "无效"; sleep 1; continue; fi
                  echo ""
                  for idx in $sub_nums; do
                    i=$((start_idx + idx - 1))
                    svc="${SERVICES[$i]}"
                    label="$(get_label "$svc")"
                    desc="$(get_desc "$svc")"
                    risk="$(get_risk "$svc")"
                    if [ "${DISABLED_CACHE[$i]}" -eq 1 ]; then
                      enable_one "$label" "$desc"
                      DISABLED_CACHE[$i]=0
                      LVL_DISABLED[$l]=$((LVL_DISABLED[$l] - 1))
                    else
                      disable_one "$label" "$desc" "$risk"
                      DISABLED_CACHE[$i]=1
                      LVL_DISABLED[$l]=$((LVL_DISABLED[$l] + 1))
                    fi
                  done
                  echo ""
                  printf "按回车返回..."
                  read -r
                  ;;
              esac
            done
          done
          ;;
      esac
    done
    ;;
esac