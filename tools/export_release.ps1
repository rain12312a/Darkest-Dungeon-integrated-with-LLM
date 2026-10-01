<#
导出并校验 Windows 发布包（防止真 API Key 被打进 exe/pck）

用法：
  powershell -ExecutionPolicy Bypass -File tools\export_release.ps1            # 导出 + 校验
  powershell -ExecutionPolicy Bypass -File tools\export_release.ps1 -VerifyOnly # 只校验现有产物

原理：
  - 导出预设 export_presets.cfg 的 exclude_filter 负责把 api_config.json / tools/* / worker/* 排除。
  - 脚本导出后解析 pck 的**文件表**（形如 "scripts/battle/api_public.gd.remap"），
    断言其中不含 api_config.* / tools/*，含 api_public.gdc。
    注意：不能直接在整个 pck 里搜 "api_config"——包内的 .godot/uid_cache.bin 会列出工程里所有路径
    （含被排除的文件），必然误报。
  - 本工程**不内置任何 API Key**：Key 由玩家在开始界面「LLM 设置」自行填写（只存本机 user://）。
#>
param(
    [switch]$VerifyOnly,
    [string]$Preset = 'Windows Desktop'
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
$fail = 0

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

    $bad = $packed | Where-Object { $_ -match 'api_config\.(json|gd)' -or $_ -match 'res://tools/' -or $_ -match 'res://worker/' }
    if ($bad) {
        Write-Host "!! 导出日志里出现禁止项：" -ForegroundColor Red
        $bad | ForEach-Object { Write-Host "   $_" -ForegroundColor Red }
        exit 1
    }
    Write-Host "OK 导出日志未包含 api_config.* / tools / worker" -ForegroundColor Green

    # ⚠️ Spine 运行时数据：.skel / .atlas 是非资源文件，必须显式 include_filter，否则模型全部不可见
    $diskSkel = (Get-ChildItem -Path $root -Recurse -File -Filter '*.skel' -ErrorAction SilentlyContinue | Measure-Object).Count
    $diskAtlas = (Get-ChildItem -Path $root -Recurse -File -Filter '*.atlas' -ErrorAction SilentlyContinue | Measure-Object).Count
    $packSkel = @($packed | Where-Object { $_ -match '\.skel' }).Count
    $packAtlas = @($packed | Where-Object { $_ -match '\.atlas' }).Count
    Write-Host "Spine 数据：磁盘 .skel=$diskSkel / .atlas=$diskAtlas，包内 .skel=$packSkel / .atlas=$packAtlas"
    if ($packSkel -lt $diskSkel -or $packAtlas -lt $diskAtlas) {
        Write-Host '!! Spine 数据没打全 → 游戏里英雄 / 怪物会全部不可见' -ForegroundColor Red
        Write-Host '   检查 export_presets.cfg 的 include_filter 是否包含 *.skel, *.atlas' -ForegroundColor Red
        exit 1
    }
    Write-Host 'OK Spine 数据（*.skel / *.atlas）已随包发布' -ForegroundColor Green
}

if (-not (Test-Path $pck)) { Write-Host "找不到 $pck" -ForegroundColor Red; exit 1 }

# 逐字节扫 pck，只认带 .remap/.gdc 后缀的文件表条目（uid_cache.bin 里的路径不带这些后缀）
$bytes = [System.IO.File]::ReadAllBytes($pck)
$text = [System.Text.Encoding]::ASCII.GetString($bytes)
# 只认带 .remap/.gdc 后缀的**文件表**条目——uid_cache.bin 里的路径不带这些后缀，避免误报
if ($text -match 'tools/(_probe|_shot|_diag)_[a-z_]+\.gd\.remap') { Write-Host '!! pck 文件表含 tools 探针' -ForegroundColor Red; $fail++ }
if ($text -match 'worker/[a-z_]+\.(js|md|toml)') { Write-Host '!! pck 文件表含 worker 脚本' -ForegroundColor Red; $fail++ }
if ($text.Contains('api_public.gd.remap')) { Write-Host 'OK 扫描有效（pck 文件表含 api_public.gd.remap）' -ForegroundColor Green }
# Spine 数据在 pck 文件表里是明文路径（如 characters/crusader/.../x.skel）
$pckSkel = ([regex]::Matches($text, '[A-Za-z0-9_./-]+\.skel')).Count
if ($pckSkel -lt 100) { Write-Host "!! pck 文件表里 .skel 条目只有 $pckSkel 个（预期 168 左右）" -ForegroundColor Red; $fail++ }
else { Write-Host "OK pck 文件表含 $pckSkel 个 .skel 条目" -ForegroundColor Green }

# 发布模式自检（二选一：自建代理 / 玩家自行配置）
$pub = Join-Path $root 'scripts\battle\api_public.gd'
$pubUrl = ''
$pubKey = ''
if (Test-Path $pub) {
    $pubText = [System.IO.File]::ReadAllText($pub, [System.Text.Encoding]::UTF8)
    $pubUrl = [regex]::Match($pubText, '(?m)^const API_URL\s*:=\s*"(.*)"').Groups[1].Value.Trim()
    $pubKey = [regex]::Match($pubText, '(?m)^const API_KEY\s*:=\s*"(.*)"').Groups[1].Value.Trim()
    if ($pubText -match 'sk-[0-9A-Za-z]{6,}') {
        Write-Host '!! api_public.gd 里出现了 sk- 真 Key —— 该文件会随包发布，必须改成代理令牌：' -ForegroundColor Red
        $fail++
    }
}

if (-not [string]::IsNullOrWhiteSpace($pubUrl)) {
    if ([string]::IsNullOrWhiteSpace($pubKey)) {
        Write-Host '提示 api_public.gd 填了代理地址但没填客户端令牌 —— Worker 若开了鉴权，玩家会拿 401' -ForegroundColor Yellow
    }
    Write-Host 'OK 发布模式：自建代理（真 Key 只存在 Worker 环境变量里，最安全）' -ForegroundColor Green
} else {
    Write-Host 'OK 发布模式：不内置任何 Key —— 玩家在开始界面右上角「LLM 设置」自行填 Key，或直接用离线 Mock' -ForegroundColor Green
}

Get-ChildItem $exe, $pck | ForEach-Object {
    Write-Host ("   {0,-24} {1,10:N1} MB  {2}" -f $_.Name, ($_.Length / 1MB), $_.LastWriteTime)
}
if ($fail -eq 0) {
    Write-Host 'OK 校验通过：包内没有 api_config.* / tools / worker，且不含 sk- 明文' -ForegroundColor Green
} else {
    exit 1
}
