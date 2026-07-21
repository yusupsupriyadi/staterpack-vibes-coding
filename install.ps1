# ============================================================================
# staterpack-vibes-coding — installer (Windows PowerShell 5.1+)
#
# Menyalin konfigurasi starterpack (skills + .claude/settings.json + CLAUDE.md)
# ke project target secara NON-DESTRUKTIF:
#   - skills        : disalin; jika ada versi berbeda -> versi lama di-backup
#   - settings.json : di-merge (hook digabung + dedupe), backup .bak dibuat
#   - CLAUDE.md     : blok starterpack di-append/diperbarui di antara penanda
#
# Pemakaian:
#   irm https://raw.githubusercontent.com/yusupsupriyadi/staterpack-vibes-coding/master/install.ps1 | iex
#   powershell -File install.ps1 [-Target <dir>] [-Local] [-Ref <branch|tag>]
# ============================================================================
[CmdletBinding()]
param(
  [string]$Target = (Get-Location).Path,
  [switch]$Local,
  [string]$Ref = ""
)

$ErrorActionPreference = 'Stop'
$RepoUrl   = "https://github.com/yusupsupriyadi/staterpack-vibes-coding.git"
$MarkBegin = '<!-- >>> staterpack-vibes-coding >>> -->'
$MarkEnd   = '<!-- <<< staterpack-vibes-coding <<< -->'

function Info($m) { Write-Host "  $m" }
function Die($m)  { Write-Host "error: $m" -ForegroundColor Red; exit 1 }

# Tulis teks sebagai UTF-8 tanpa BOM (agar aman dibaca parser JSON/Claude Code)
function WriteText($path, $text) {
  $dir = Split-Path -Parent $path
  if ($dir -and -not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
  [System.IO.File]::WriteAllText($path, $text, (New-Object System.Text.UTF8Encoding($false)))
}

function HasContent($root) { Test-Path -LiteralPath (Join-Path $root '.claude/skills/graphify/SKILL.md') }

# Bandingkan dua folder berdasarkan daftar file relatif + hash isi
function DirsEqual($a, $b) {
  $fa = @(Get-ChildItem -LiteralPath $a -Recurse -File -ErrorAction SilentlyContinue)
  $fb = @(Get-ChildItem -LiteralPath $b -Recurse -File -ErrorAction SilentlyContinue)
  if ($fa.Count -ne $fb.Count) { return $false }
  $rel = { param($root, $f) $f.FullName.Substring($root.Length).TrimStart('\','/').Replace('\','/') }
  $mapA = @{}; foreach ($f in $fa) { $mapA[(& $rel $a $f)] = (Get-FileHash -LiteralPath $f.FullName -Algorithm MD5).Hash }
  foreach ($f in $fb) {
    $r = & $rel $b $f
    if (-not $mapA.ContainsKey($r)) { return $false }
    if ($mapA[$r] -ne (Get-FileHash -LiteralPath $f.FullName -Algorithm MD5).Hash) { return $false }
  }
  return $true
}

function HookKey($e) {
  $m = if ($e.PSObject.Properties['matcher']) { [string]$e.matcher } else { '' }
  $h = if ($e.PSObject.Properties['hooks']) { ($e.hooks | ConvertTo-Json -Depth 30 -Compress) } else { '[]' }
  "$m $h"
}

# --- tentukan Target --------------------------------------------------------
if ([string]::IsNullOrWhiteSpace($Target)) { Die "-Target kosong" }
if (-not (Test-Path -LiteralPath $Target)) { New-Item -ItemType Directory -Path $Target -Force | Out-Null }
$Target = (Resolve-Path -LiteralPath $Target).Path

# --- tentukan sumber konten (lokal vs clone) --------------------------------
$ScriptDir = $PSScriptRoot
$Src = $null
$TmpClone = $null

if ($Local) {
  if ($ScriptDir -and (HasContent $ScriptDir)) { $Src = $ScriptDir }
  else { Die "-Local dipakai tapi konten repo tak ditemukan di '$ScriptDir'" }
}
elseif ($ScriptDir -and (HasContent $ScriptDir)) {
  $Src = $ScriptDir
}
else {
  if (-not (Get-Command git -ErrorAction SilentlyContinue)) { Die "butuh 'git' untuk mengunduh starterpack" }
  $TmpClone = Join-Path ([System.IO.Path]::GetTempPath()) ("sp-" + [Guid]::NewGuid().ToString('N').Substring(0,8))
  Info "mengunduh starterpack dari $RepoUrl ..."
  # git menulis progres ke stderr; di PS 5.1 dgn EAP=Stop itu jadi error terminating.
  # Turunkan EAP sementara + --quiet, lalu andalkan $LASTEXITCODE.
  $prevEAP = $ErrorActionPreference
  $ErrorActionPreference = 'SilentlyContinue'
  if ($Ref) { & git clone --quiet --depth 1 --branch $Ref $RepoUrl $TmpClone 2>&1 | Out-Null }
  else      { & git clone --quiet --depth 1 $RepoUrl $TmpClone 2>&1 | Out-Null }
  $cloneCode = $LASTEXITCODE
  $ErrorActionPreference = $prevEAP
  if (($cloneCode -ne 0) -or -not (HasContent $TmpClone)) { Die "gagal clone repo starterpack" }
  $Src = $TmpClone
}

$Ts = (Get-Date).ToString('yyyyMMdd-HHmmss')
$script:BackupDir = $null
function EnsureBackupDir {
  if (-not $script:BackupDir) {
    $script:BackupDir = Join-Path $Target ".claude/.staterpack-backup-$Ts"
    New-Item -ItemType Directory -Path $script:BackupDir -Force | Out-Null
  }
}

Write-Host "staterpack-vibes-coding installer"
Write-Host "  sumber : $Src"
Write-Host "  target : $Target`n"

try {
  # --- 1. skills ------------------------------------------------------------
  Write-Host "[1/3] skills"
  $skillsSrc = Join-Path $Src '.claude/skills'
  $skillsDst = Join-Path $Target '.claude/skills'
  New-Item -ItemType Directory -Path $skillsDst -Force | Out-Null
  $copied = 0; $skipped = 0; $backed = 0
  foreach ($d in @(Get-ChildItem -LiteralPath $skillsSrc -Directory)) {
    $dest = Join-Path $skillsDst $d.Name
    if (Test-Path -LiteralPath $dest) {
      if (DirsEqual $dest $d.FullName) { $skipped++; continue }
      EnsureBackupDir
      $bdest = Join-Path $script:BackupDir $d.Name
      if (Test-Path -LiteralPath $bdest) { Remove-Item -LiteralPath $bdest -Recurse -Force }
      Copy-Item -LiteralPath $dest -Destination $bdest -Recurse -Force
      Remove-Item -LiteralPath $dest -Recurse -Force
      $backed++
    }
    Copy-Item -LiteralPath $d.FullName -Destination $dest -Recurse -Force
    $copied++
  }
  Info "disalin=$copied, dilewati(identik)=$skipped, di-backup=$backed"

  # --- 2. settings.json -----------------------------------------------------
  Write-Host "[2/3] .claude/settings.json"
  $srcSettings  = Join-Path $Src '.claude/settings.json'
  $destSettings = Join-Path $Target '.claude/settings.json'
  if (Test-Path -LiteralPath $srcSettings) {
    if (-not (Test-Path -LiteralPath $destSettings)) {
      New-Item -ItemType Directory -Path (Split-Path -Parent $destSettings) -Force | Out-Null
      Copy-Item -LiteralPath $srcSettings -Destination $destSettings -Force
      Info "settings.json disalin (baru)"
    }
    else {
      Copy-Item -LiteralPath $destSettings -Destination "$destSettings.bak" -Force
      $dst = Get-Content -LiteralPath $destSettings -Raw | ConvertFrom-Json
      $sc  = Get-Content -LiteralPath $srcSettings  -Raw | ConvertFrom-Json
      if ($null -eq $dst.hooks) { $dst | Add-Member -NotePropertyName hooks -NotePropertyValue ([PSCustomObject]@{}) -Force }
      foreach ($ev in $sc.hooks.PSObject.Properties.Name) {
        $existing = @()
        if ($dst.hooks.PSObject.Properties[$ev]) { $existing = @($dst.hooks.$ev) }
        else { $dst.hooks | Add-Member -NotePropertyName $ev -NotePropertyValue @() -Force }
        $keys = @{}; foreach ($e in $existing) { $keys[(HookKey $e)] = $true }
        $merged = @($existing)
        foreach ($e in @($sc.hooks.$ev)) {
          $k = HookKey $e
          if (-not $keys.ContainsKey($k)) { $merged += $e; $keys[$k] = $true }
        }
        $dst.hooks.$ev = $merged
      }
      WriteText $destSettings (($dst | ConvertTo-Json -Depth 30) + "`n")
      Info "settings.json di-merge (backup: settings.json.bak)"
    }
  }

  # --- 3. CLAUDE.md ---------------------------------------------------------
  Write-Host "[3/3] CLAUDE.md"
  function MergeMarked($srcFile, $destFile) {
    if (-not (Test-Path -LiteralPath $srcFile)) { return }
    $rel = $destFile.Substring($Target.Length).TrimStart('\', '/').Replace('\', '/')
    $body  = Get-Content -LiteralPath $srcFile -Raw
    $block = "$MarkBegin`n$body`n$MarkEnd"
    if (-not (Test-Path -LiteralPath $destFile)) {
      WriteText $destFile ($block + "`n")
      Info "$rel dibuat"
    }
    elseif ((Get-Content -LiteralPath $destFile -Raw).Contains($MarkBegin)) {
      $s = Get-Content -LiteralPath $destFile -Raw
      $i = $s.IndexOf($MarkBegin)
      $j = $s.IndexOf($MarkEnd)
      if ($i -ge 0 -and $j -ge $i) {
        $before = $s.Substring(0, $i)
        $after  = $s.Substring($j + $MarkEnd.Length)
        $new = ($before.TrimEnd() + "`n`n" + $block + "`n" + $after.TrimStart()).Trim() + "`n"
        WriteText $destFile $new
        Info "$rel blok starterpack diperbarui"
      }
    }
    else {
      Copy-Item -LiteralPath $destFile -Destination "$destFile.bak" -Force
      $existing = Get-Content -LiteralPath $destFile -Raw
      WriteText $destFile ($existing.TrimEnd() + "`n`n" + $block + "`n")
      Info "$rel blok starterpack di-append (backup: $rel.bak)"
    }
  }
  MergeMarked (Join-Path $Src 'CLAUDE.md')          (Join-Path $Target 'CLAUDE.md')
  MergeMarked (Join-Path $Src '.claude/CLAUDE.md')  (Join-Path $Target '.claude/CLAUDE.md')

  Write-Host "`nSelesai. Starterpack terpasang di: $Target"
  if ($script:BackupDir) { Write-Host "Backup skill lama: $script:BackupDir" }
  exit 0
}
finally {
  if ($TmpClone -and (Test-Path -LiteralPath $TmpClone)) {
    Remove-Item -LiteralPath $TmpClone -Recurse -Force -ErrorAction SilentlyContinue
  }
}
