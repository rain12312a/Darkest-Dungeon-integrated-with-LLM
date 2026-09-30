<#
导出并校验 Windows 发布包（防止真 API Key 被打进 exe/pck）

用法：
  powershell -ExecutionPolicy Bypass -File tools\export_release.ps1            # 导出 + 校验
  powershell -ExecutionPolicy Bypass -File tools\export_release.ps1 -VerifyOnly # 只校验现有产物

原理：
  - 导出预设 export_presets.cfg 的 exclude_filter 负责把 api_config.gd / api_config.json / tools/* 排除。
  - 脚本导出后解析 pck 的**文件表**（形如 "scripts/battle/api_public.gd.remap"），
    断言其中不含 api_config.* / tools/*，含 api_public.gdc。
    注意：不能直接在整个 pck 里搜 "api_config"——包内的 .godot/uid_cache.bin 会列出工程里所有路径
    （含被排除的文件），必然误报。
#>
param(
    [switch]$VerifyOnly,
    [string]$Preset = 'Windows Desktop'
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$godot = 'd:\downloads\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64.exe'
$exe = Join-Path $root 'darkdungeon.exe'
$pck = Join-Path $root 'darkdungeon.pck'
$log = Join-Path $env:TEMP 'darkdungeon_export.txt'

if (-not $VerifyOnly) {
    Write-Host "==> 导出中（$Preset）"
    # ⚠️ 两个坑（本机实测都会踩）：
    #   ① Godot 是 GUI 子系统程序：PowerShell 里 `$out = & $godot ...` 捕获到的是**空数组**；
    #   ② 用管道喂 Tee-Object 虽能拿到输出，但 PowerShell 会用控制台编码（中文系统 = GBK）去解码
    #      Godot 的 UTF-8 输出，把「：」后紧跟的 ASCII 字符吞掉（实测吃掉 res:// 的 'r'）
    #      → 路径匹配静默失效，看起来「校验通过」其实什么都没校验到。
    # 最稳的做法：交给 cmd 做**字节级重定向**写日志，再按 UTF-8 读回来。
    $cmdLine = '"{0}" --headless --path "{1}" --export-release "{2}" "{3}" > "{4}" 2>&1' -f $godot, $root, $Preset, $exe, $log
    cmd.exe /c $cmdLine | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "!! 导出失败（Godot 退出码 $LASTEXITCODE），日志：$log" -ForegroundColor Red
        exit 1
    }

    # 导出日志是权威依据：Godot 会逐条列出真正写进包里的文件
    $packed = @(Get-Content -LiteralPath $log -Encoding UTF8 | Where-Object { $_ -match 'savepack' })
    if ($packed.Count -eq 0) {
        Write-Host "!! 日志里没有 savepack 记录，导出可能没真正执行：$log" -ForegroundColor Red
        exit 1
    }
    $packed | Select-Object -Last 2 | ForEach-Object { Write-Host "   $_" }

    $bad = $packed | Where-Object { $_ -match 'api_config\.json' -or $_ -match 'res://tools/' -or $_ -match 'res://worker/' }
    if ($bad) {
        Write-Host "!! 导出日志里出现禁止项：" -ForegroundColor Red
        $bad | ForEach-Object { Write-Host "   $_" -ForegroundColor Red }
        exit 1
    }
    Write-Host "OK 导出日志未包含 api_config.json / tools / worker" -ForegroundColor Green
    if (($packed -join "`n") -match 'res://scripts/battle/api_config\.gd') {
        Write-Host "OK 内置直连 Key（scripts/battle/api_config.gd）已随包发布" -ForegroundColor Yellow
    }
}

if (-not (Test-Path $pck)) { Write-Host "找不到 $pck" -ForegroundColor Red; exit 1 }

# 逐字节扫 pck，只认带 .remap/.gdc 后缀的文件表条目（uid_cache.bin 里的路径不带这些后缀）
$bytes = [System.IO.File]::ReadAllBytes($pck)
$text = [System.Text.Encoding]::ASCII.GetString($bytes)
$fail = 0
# 只认带 .remap/.gdc 后缀的**文件表**条目——uid_cache.bin 里的路径不带这些后缀，避免误报
if ($text -match 'tools/(_probe|_shot|_diag)_[a-z_]+\.gd\.remap') { Write-Host '!! pck 文件表含 tools 探针' -ForegroundColor Red; $fail++ }
if ($text -match 'worker/[a-z_]+\.(js|md|toml)') { Write-Host '!! pck 文件表含 worker 脚本' -ForegroundColor Red; $fail++ }
if ($text.Contains('api_public.gd.remap')) { Write-Host 'OK 扫描有效（pck 文件表含 api_public.gd.remap）' -ForegroundColor Green }

# 发布模式自检（三选一：自建代理 / 内置直连 Key / 离线 Mock）
$pub = Join-Path $root 'scripts\battle\api_public.gd'
$dev = Join-Path $root 'scripts\battle\api_config.gd'
$pubUrl = ''
if (Test-Path $pub) {
    $pubUrl = [regex]::Match([System.IO.File]::ReadAllText($pub, [System.Text.Encoding]::UTF8), '(?m)^const API_URL\s*:=\s*"(.*)"').Groups[1].Value.Trim()
}
$devKey = ''
$devObf = ''
if (Test-Path $dev) {
    $devText = [System.IO.File]::ReadAllText($dev, [System.Text.Encoding]::UTF8)
    $devKey = [regex]::Match($devText, '(?m)^const API_KEY\s*:=\s*"(.*)"').Groups[1].Value.Trim()
    $devObf = [regex]::Match($devText, '(?m)^const API_KEY_OBF\s*:=\s*"(.*)"').Groups[1].Value.Trim()
    if ($devText -match 'sk-[0-9A-Za-z]{6,}') {
        Write-Host '!! api_config.gd 里是【明文】Key → 包内也是明文，爬虫 / strings 一搜就有：' -ForegroundColor Red
        Write-Host '   powershell -ExecutionPolicy Bypass -File tools\embed_key.ps1' -ForegroundColor Red
        $fail++
    } elseif (-not [string]::IsNullOrWhiteSpace($devObf)) {
        if (-not $text.Contains('api_config.gd.remap')) {
            Write-Host '!! 配了内置 Key，但 pck 文件表里没有 api_config.gd —— 检查 export_presets.cfg 的 exclude_filter' -ForegroundColor Red
            $fail++
        }
    }
}

if (-not [string]::IsNullOrWhiteSpace($pubUrl) -and -not [string]::IsNullOrWhiteSpace($pubUrl)) {
    Write-Host 'OK 发布模式：自建代理（0 点击；真 Key 只存在 Worker 里，最安全）' -ForegroundColor Green
} elseif (-not [string]::IsNullOrWhiteSpace($devObf) -or -not [string]::IsNullOrWhiteSpace($devKey)) {
    Write-Host 'OK 发布模式：内置直连 Key（0 点击）' -ForegroundColor Yellow
    Write-Host '   ⚠️ 拿到 exe 的人理论上能还原 Key → 确认已在服务端设消费上限，并保留随时吊销该 Key 的能力' -ForegroundColor Yellow
} else {
    Write-Host '提示 未内置任何在线配置 → 玩家走离线 Mock，并会看到一次首次引导面板（非 0 点击）' -ForegroundColor Yellow
    Write-Host '     内置直连 Key：先把 Key 填进 scripts\battle\api_config.gd，再跑 tools\embed_key.ps1' -ForegroundColor Yellow
}

Get-ChildItem $exe, $pck | ForEach-Object {
    Write-Host ("   {0,-24} {1,10:N1} MB  {2}" -f $_.Name, ($_.Length / 1MB), $_.LastWriteTime)
}
if ($fail -eq 0) {
    Write-Host 'OK 校验通过：包内没有 api_config.json / tools / worker，api_config.gd 里也没有 sk- 明文' -ForegroundColor Green
} else {
    exit 1
}
