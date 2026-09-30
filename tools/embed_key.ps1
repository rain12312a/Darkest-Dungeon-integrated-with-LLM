<#
把 DeepSeek 真 Key 写进 scripts/battle/api_config.gd —— 以**混淆形式**（XOR+Base64）存放，
这样 exe / pck / 仓库里都搜不到 "sk-" 明文，能挡掉 GitHub 密钥扫描、自动化爬虫、`strings | grep sk-`。

用法：
  powershell -ExecutionPolicy Bypass -File tools\embed_key.ps1                    # 自动读取当前 api_config.gd 里的明文 Key 并转成混淆形式
  powershell -ExecutionPolicy Bypass -File tools\embed_key.ps1 -Key "sk-xxxx"     # 指定 Key
  powershell -ExecutionPolicy Bypass -File tools\embed_key.ps1 -DryRun            # 只打印混淆串，不改文件

⚠️ 混淆不是加密：拿到 exe 且愿意动手的人仍能还原出来。发布前请务必做到：
   1. 给这个 Key 在服务端设**消费上限**（DeepSeek 控制台 → 额度设置）
   2. 用**独立于日常使用的 Key**，一旦被盗用可以单独吊销（旧 exe 会自动降级为离线 Mock，不会坏）
   3. api_config.gd 已加入 .gitignore —— 千万不要手动 git add 它
#>
param(
	[string]$Key,
	[switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$target = Join-Path $root 'scripts\battle\api_config.gd'
$SALT = 'darkdungeon-2026'   # 必须与 LLMClient.gd 的 KEY_SALT 完全一致

if (-not (Test-Path $target)) {
	Write-Host "找不到 $target" -ForegroundColor Red
	exit 1
}

$content = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)

function Get-Const([string]$text, [string]$name) {
	$m = [regex]::Match($text, '(?m)^const\s+' + $name + '\s*:=\s*"(.*)"\s*$')
	if ($m.Success) { return $m.Groups[1].Value }
	return ''
}

if ([string]::IsNullOrWhiteSpace($Key)) {
	$Key = Get-Const $content 'API_KEY'
	if ([string]::IsNullOrWhiteSpace($Key)) {
		Write-Host 'api_config.gd 里没有明文 Key —— 请用 -Key 指定，或先把 Key 填进 API_KEY' -ForegroundColor Red
		exit 1
	}
	Write-Host '已从 api_config.gd 读取到明文 Key，转为混淆形式…'
} elseif ($Key -notmatch '^sk-') {
	Write-Host "提示：这个 Key 不以 sk- 开头（$($Key.Substring(0, [Math]::Min(6, $Key.Length)))…），确认是 DeepSeek Key 吗？" -ForegroundColor Yellow
}

# 与 GDScript 端一致的算法：UTF-8 字节循环 XOR 盐 → Base64
$saltBytes = [System.Text.Encoding]::UTF8.GetBytes($SALT)
$rawBytes = [System.Text.Encoding]::UTF8.GetBytes($Key.Trim())
$out = New-Object byte[] $rawBytes.Length
for ($i = 0; $i -lt $rawBytes.Length; $i++) {
	$out[$i] = $rawBytes[$i] -bxor $saltBytes[$i % $saltBytes.Length]
}
$blob = [Convert]::ToBase64String($out)

# 自校验：解回来必须与原文一致
$back = New-Object byte[] $out.Length
for ($i = 0; $i -lt $out.Length; $i++) {
	$back[$i] = $out[$i] -bxor $saltBytes[$i % $saltBytes.Length]
}
$decoded = [System.Text.Encoding]::UTF8.GetString($back)
if ($decoded -ne $Key.Trim()) {
	Write-Host '自校验失败：解码结果与原文不一致，已中止（不要使用这个串）' -ForegroundColor Red
	exit 1
}

$masked = $decoded.Substring(0, 6) + '••••••' + $decoded.Substring($decoded.Length - 4)
Write-Host "混淆串（自校验通过，还原为 $masked）：" -ForegroundColor Green
Write-Host "  $blob"

if ($DryRun) {
	Write-Host '（-DryRun：未修改任何文件）' -ForegroundColor Yellow
	exit 0
}

$url = Get-Const $content 'API_URL'
$model = Get-Const $content 'MODEL'
if ([string]::IsNullOrWhiteSpace($url)) { $url = 'https://api.deepseek.com/v1/chat/completions' }
if ([string]::IsNullOrWhiteSpace($model)) { $model = 'deepseek-chat' }

$new = @"
# API 配置文件 —— 已加入 .gitignore，**不会**提交到 Git；但它**会**被打进 exe/pck（内置直连 Key）
#
# Key 以混淆形式存放（由 tools\embed_key.ps1 生成），目的是让包里搜不到 "sk-" 明文，
# 挡掉 GitHub 密钥扫描 / 自动化爬虫 / strings 扫描。
#
# ⚠️ 混淆不是加密：拿到 exe 的人理论上仍可还原。发布前务必：
#   1. 服务端设消费上限   2. 用可随时吊销的独立 Key   3. 别把本文件 git add
# 想换回明文：直接把上面 API_KEY 填上即可（API_KEY_OBF 会自动被忽略）。

const API_KEY := ""
const API_KEY_OBF := "$blob"
const API_URL := "$url"
const MODEL := "$model"
"@
[System.IO.File]::WriteAllText($target, $new, (New-Object System.Text.UTF8Encoding($false)))

Write-Host ""
Write-Host "已写入 $target" -ForegroundColor Green
Select-String -Path $target -Pattern '^const ' | ForEach-Object { '   ' + $_.Line }
Write-Host ""
Write-Host "确认 $target 处于 .gitignore 保护下：" -NoNewline
Push-Location $root
$ignored = git check-ignore -q 'scripts/battle/api_config.gd'; $code = $LASTEXITCODE
Pop-Location
if ($code -eq 0) { Write-Host ' 是 ✅' -ForegroundColor Green } else { Write-Host ' 否 ❌（有被提交的风险！）' -ForegroundColor Red }
Write-Host "下一步：powershell -ExecutionPolicy Bypass -File tools\export_release.ps1"
