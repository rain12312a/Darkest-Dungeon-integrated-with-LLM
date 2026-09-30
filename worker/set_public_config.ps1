<#
把「自建代理地址 + 可公开的客户端令牌」写进 scripts/battle/api_public.gd
—— 这是 **0 点击路线** 的最后一步：填好 → 重新导出 → 玩家双击 exe、点 START 就直接开局（在线 LLM）。

用法：
  powershell -ExecutionPolicy Bypass -File worker\set_public_config.ps1 -Url "https://darkdungeon-llm.你的账号.workers.dev" -Token "dd-7f3a91c2e5b4"
  powershell -ExecutionPolicy Bypass -File worker\set_public_config.ps1 -Clear     # 清空 → 公开版回到离线 Mock

⚠️ 这里只能填「客户端令牌」（你自己随便生成的随机串，会随 exe 公开，等价于一把门锁）；
   绝对不要填 DeepSeek 真 Key（sk- 开头）—— 那等于把 Key 公开，脚本会直接拒绝。
#>
param(
	[string]$Url,
	[string]$Token,
	[string]$Model = 'deepseek-chat',
	[switch]$Clear
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$target = Join-Path $root 'scripts\battle\api_public.gd'
if (-not (Test-Path $target)) {
	Write-Host "找不到 $target" -ForegroundColor Red
	exit 1
}

if ($Clear) {
	$Url = ''
	$Token = ''
	$Model = 'deepseek-chat'
} else {
	if ([string]::IsNullOrWhiteSpace($Url) -or [string]::IsNullOrWhiteSpace($Token)) {
		Write-Host '用法：-Url <代理地址> -Token <客户端令牌>    或    -Clear' -ForegroundColor Red
		exit 1
	}
	if ($Token -match '^sk-') {
		Write-Host '拒绝：Token 看起来是 DeepSeek 真 Key（sk- 开头）。' -ForegroundColor Red
		Write-Host '真 Key 只能放进 Worker 的环境变量 DEEPSEEK_API_KEY；这里要填 CLIENT_TOKEN。' -ForegroundColor Red
		exit 1
	}
	if ($Url -notmatch '^https?://') {
		Write-Host 'Url 必须以 http(s):// 开头（Cloudflare Worker 地址或你绑定的自有域名）' -ForegroundColor Red
		exit 1
	}
}

$content = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
$content = [regex]::Replace($content, '(?m)^const API_URL :=.*$', 'const API_URL := "' + $Url.Replace('$', '$$') + '"')
$content = [regex]::Replace($content, '(?m)^const API_KEY :=.*$', 'const API_KEY := "' + $Token.Replace('$', '$$') + '"')
$content = [regex]::Replace($content, '(?m)^const MODEL :=.*$', 'const MODEL := "' + $Model.Replace('$', '$$') + '"')
[System.IO.File]::WriteAllText($target, $content, (New-Object System.Text.UTF8Encoding($false)))

Write-Host "已写入 $target ：" -ForegroundColor Green
Select-String -Path $target -Pattern '^const ' | ForEach-Object { '   ' + $_.Line }
Write-Host ''
if ($Clear) {
	Write-Host '下一步：重新导出 —— 公开版将走离线 Mock，玩家首次点 START 会看到引导面板。'
} else {
	Write-Host '下一步：先用 curl 自测代理（见 worker\README.md），然后重新导出：'
	Write-Host '        powershell -ExecutionPolicy Bypass -File tools\export_release.ps1'
}
