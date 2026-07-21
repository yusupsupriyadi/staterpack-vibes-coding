# Tes untuk install.ps1 (starterpack-vibes-coding).
# Dijalankan lewat: powershell -NoProfile -File tests/test-install.ps1
# Menguji: fresh install, idempotensi, non-destruktif (CLAUDE.md), merge settings.json.

$ErrorActionPreference = 'Stop'
$Repo    = Split-Path -Parent $PSScriptRoot
$Install = Join-Path $Repo 'install.ps1'
$MarkBegin = '<!-- >>> staterpack-vibes-coding >>> -->'
$script:Failures = 0

function Pass($m) { Write-Host "  PASS: $m" }
function Fail($m) { Write-Host "  FAIL: $m"; $script:Failures++ }
function AssertFile($p, $label) { if (Test-Path -LiteralPath $p) { Pass "ada file: $label" } else { Fail "tidak ada file: $label" } }
function AssertEq($actual, $expected, $label) {
  if ("$actual" -eq "$expected") { Pass "$label (=$actual)" } else { Fail "$label (dapat '$actual', harusnya '$expected')" }
}
function AssertGrep($p, $needle, $label) {
  if ((Test-Path -LiteralPath $p) -and ((Get-Content -LiteralPath $p -Raw) -like "*$needle*")) { Pass $label } else { Fail $label }
}
function CountSkills($root) {
  $d = Join-Path $root '.claude/skills'
  if (Test-Path -LiteralPath $d) { @(Get-ChildItem -LiteralPath $d -Recurse -Filter 'SKILL.md' -File).Count } else { 0 }
}
function CountPreToolUse($p) {
  if (-not (Test-Path -LiteralPath $p)) { return 0 }
  try { $j = Get-Content -LiteralPath $p -Raw | ConvertFrom-Json } catch { return 0 }
  if ($null -eq $j.hooks -or $null -eq $j.hooks.PreToolUse) { return 0 }
  @($j.hooks.PreToolUse).Count
}
function CountMarker($p) {
  if (-not (Test-Path -LiteralPath $p)) { return 0 }
  $c = Get-Content -LiteralPath $p -Raw
  ([regex]::Matches($c, [regex]::Escape($MarkBegin))).Count
}
function RunInstall($target) {
  & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $Install -Local -Target $target *> $null
}

$Work = Join-Path ([System.IO.Path]::GetTempPath()) ("sp-test-" + [Guid]::NewGuid().ToString('N').Substring(0,8))
New-Item -ItemType Directory -Path $Work -Force | Out-Null
Write-Host "Workdir: $Work"
Write-Host "Installer: $Install`n"

try {
  # -------------------------------------------------------------------------
  Write-Host "== Skenario 1: fresh install ke folder kosong =="
  $T1 = Join-Path $Work 'fresh'; New-Item -ItemType Directory -Path $T1 -Force | Out-Null
  RunInstall $T1
  AssertFile (Join-Path $T1 '.claude/skills/graphify/SKILL.md') '.claude/skills/graphify/SKILL.md'
  AssertEq (CountSkills $T1) 15 'jumlah SKILL.md tersalin'
  AssertFile (Join-Path $T1 '.claude/settings.json') '.claude/settings.json'
  AssertGrep (Join-Path $T1 '.claude/settings.json') 'graphify' 'settings.json memuat hook graphify'
  AssertFile (Join-Path $T1 'CLAUDE.md') 'CLAUDE.md'
  AssertEq (CountMarker (Join-Path $T1 'CLAUDE.md')) 1 'penanda starterpack ada tepat 1x di CLAUDE.md'
  AssertEq (CountPreToolUse (Join-Path $T1 '.claude/settings.json')) 2 'PreToolUse punya 2 entri graphify'
  Write-Host ""

  # -------------------------------------------------------------------------
  Write-Host "== Skenario 2: idempotensi (jalankan lagi, tak boleh duplikat) =="
  RunInstall $T1
  AssertEq (CountMarker (Join-Path $T1 'CLAUDE.md')) 1 'penanda tetap 1x setelah re-install'
  AssertEq (CountPreToolUse (Join-Path $T1 '.claude/settings.json')) 2 'PreToolUse tetap 2 entri setelah re-install'
  AssertEq (CountSkills $T1) 15 'jumlah SKILL.md tetap 15 setelah re-install'
  Write-Host ""

  # -------------------------------------------------------------------------
  Write-Host "== Skenario 3: non-destruktif terhadap CLAUDE.md milik user =="
  $T2 = Join-Path $Work 'existing-claude'; New-Item -ItemType Directory -Path $T2 -Force | Out-Null
  Set-Content -LiteralPath (Join-Path $T2 'CLAUDE.md') -Value 'CATATAN SAYA SENDIRI YANG UNIK' -Encoding utf8
  RunInstall $T2
  AssertGrep (Join-Path $T2 'CLAUDE.md') 'CATATAN SAYA SENDIRI YANG UNIK' 'teks user tetap ada di CLAUDE.md'
  AssertEq (CountMarker (Join-Path $T2 'CLAUDE.md')) 1 'blok starterpack di-append (1x)'
  AssertFile (Join-Path $T2 'CLAUDE.md.bak') 'CLAUDE.md.bak'
  Write-Host ""

  # -------------------------------------------------------------------------
  Write-Host "== Skenario 4: merge settings.json dengan hook milik user =="
  $T3 = Join-Path $Work 'existing-settings'; New-Item -ItemType Directory -Path (Join-Path $T3 '.claude') -Force | Out-Null
  $userSettings = @'
{
  "hooks": {
    "PreToolUse": [
      { "matcher": "Write", "hooks": [ { "type": "command", "command": "echo HOOK_MILIK_USER" } ] }
    ]
  }
}
'@
  Set-Content -LiteralPath (Join-Path $T3 '.claude/settings.json') -Value $userSettings -Encoding utf8
  RunInstall $T3
  AssertGrep (Join-Path $T3 '.claude/settings.json') 'HOOK_MILIK_USER' 'hook milik user tetap ada setelah merge'
  AssertGrep (Join-Path $T3 '.claude/settings.json') 'graphify' 'hook graphify ditambahkan saat merge'
  AssertEq (CountPreToolUse (Join-Path $T3 '.claude/settings.json')) 3 'PreToolUse = 1 user + 2 graphify'
  AssertFile (Join-Path $T3 '.claude/settings.json.bak') '.claude/settings.json.bak'
  RunInstall $T3
  AssertEq (CountPreToolUse (Join-Path $T3 '.claude/settings.json')) 3 'PreToolUse tetap 3 setelah re-install (dedupe)'
  Write-Host ""
}
finally {
  Remove-Item -LiteralPath $Work -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "==================================================="
if ($script:Failures -eq 0) {
  Write-Host "SEMUA TES LULUS (PASS)"
  exit 0
} else {
  Write-Host "ADA $($script:Failures) TES GAGAL (FAIL)"
  exit 1
}
