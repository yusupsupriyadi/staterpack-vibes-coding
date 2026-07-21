#!/usr/bin/env bash
# Tes untuk install.sh (starterpack-vibes-coding).
# Dijalankan lewat: bash tests/test-install.sh
# Menguji: fresh install, idempotensi, non-destruktif (CLAUDE.md), merge settings.json.
set -u

REPO="$(cd "$(dirname "$0")/.." && pwd)"
INSTALL="$REPO/install.sh"
MARK_BEGIN='<!-- >>> staterpack-vibes-coding >>> -->'
FAILURES=0

pass() { echo "  PASS: $1"; }
fail() { echo "  FAIL: $1"; FAILURES=$((FAILURES + 1)); }

assert_file() { if [ -f "$1" ]; then pass "ada file: ${1#"$WORK/"}"; else fail "tidak ada file: ${1#"$WORK/"}"; fi; }
assert_eq()   { if [ "$1" = "$2" ]; then pass "$3 (=$1)"; else fail "$3 (dapat '$1', harusnya '$2')"; fi; }
assert_grep() { if grep -qF "$2" "$1" 2>/dev/null; then pass "$3"; else fail "$3"; fi; }

# Hitung jumlah SKILL.md di sebuah folder .claude/skills
count_skills() { find "$1/.claude/skills" -name SKILL.md 2>/dev/null | wc -l | tr -d ' '; }
# Hitung jumlah entri hooks.PreToolUse di settings.json (pakai node)
count_pretooluse() {
  node -e 'const fs=require("fs");let s={};try{s=JSON.parse(fs.readFileSync(process.argv[1],"utf8"))}catch(e){};process.stdout.write(String(((s.hooks||{}).PreToolUse||[]).length))' "$1" 2>/dev/null
}
# Hitung kemunculan penanda BEGIN di CLAUDE.md
count_marker() { grep -cF "$MARK_BEGIN" "$1" 2>/dev/null | tr -d ' '; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
echo "Workdir: $WORK"
echo "Installer: $INSTALL"
echo

# ---------------------------------------------------------------------------
echo "== Skenario 1: fresh install ke folder kosong =="
T1="$WORK/fresh"; mkdir -p "$T1"
bash "$INSTALL" --local --target "$T1" >/dev/null 2>&1
assert_file "$T1/.claude/skills/graphify/SKILL.md"
assert_eq "$(count_skills "$T1")" "15" "jumlah SKILL.md tersalin"
assert_file "$T1/.claude/settings.json"
assert_grep "$T1/.claude/settings.json" "graphify" "settings.json memuat hook graphify"
assert_file "$T1/CLAUDE.md"
assert_eq "$(count_marker "$T1/CLAUDE.md")" "1" "penanda starterpack ada tepat 1x di CLAUDE.md"
assert_eq "$(count_pretooluse "$T1/.claude/settings.json")" "2" "PreToolUse punya 2 entri graphify"
echo

# ---------------------------------------------------------------------------
echo "== Skenario 2: idempotensi (jalankan lagi, tak boleh duplikat) =="
bash "$INSTALL" --local --target "$T1" >/dev/null 2>&1
assert_eq "$(count_marker "$T1/CLAUDE.md")" "1" "penanda tetap 1x setelah re-install"
assert_eq "$(count_pretooluse "$T1/.claude/settings.json")" "2" "PreToolUse tetap 2 entri setelah re-install"
assert_eq "$(count_skills "$T1")" "15" "jumlah SKILL.md tetap 15 setelah re-install"
echo

# ---------------------------------------------------------------------------
echo "== Skenario 3: non-destruktif terhadap CLAUDE.md milik user =="
T2="$WORK/existing-claude"; mkdir -p "$T2"
printf 'CATATAN SAYA SENDIRI YANG UNIK\n' > "$T2/CLAUDE.md"
bash "$INSTALL" --local --target "$T2" >/dev/null 2>&1
assert_grep "$T2/CLAUDE.md" "CATATAN SAYA SENDIRI YANG UNIK" "teks user tetap ada di CLAUDE.md"
assert_eq "$(count_marker "$T2/CLAUDE.md")" "1" "blok starterpack di-append (1x)"
assert_file "$T2/CLAUDE.md.bak"
echo

# ---------------------------------------------------------------------------
echo "== Skenario 4: merge settings.json dengan hook milik user =="
T3="$WORK/existing-settings"; mkdir -p "$T3/.claude"
cat > "$T3/.claude/settings.json" <<'JSON'
{
  "hooks": {
    "PreToolUse": [
      { "matcher": "Write", "hooks": [ { "type": "command", "command": "echo HOOK_MILIK_USER" } ] }
    ]
  }
}
JSON
bash "$INSTALL" --local --target "$T3" >/dev/null 2>&1
assert_grep "$T3/.claude/settings.json" "HOOK_MILIK_USER" "hook milik user tetap ada setelah merge"
assert_grep "$T3/.claude/settings.json" "graphify" "hook graphify ditambahkan saat merge"
assert_eq "$(count_pretooluse "$T3/.claude/settings.json")" "3" "PreToolUse = 1 user + 2 graphify"
assert_file "$T3/.claude/settings.json.bak"
# idempotensi merge
bash "$INSTALL" --local --target "$T3" >/dev/null 2>&1
assert_eq "$(count_pretooluse "$T3/.claude/settings.json")" "3" "PreToolUse tetap 3 setelah re-install (dedupe)"
echo

# ---------------------------------------------------------------------------
echo "==================================================="
if [ "$FAILURES" -eq 0 ]; then
  echo "SEMUA TES LULUS ✅"
  exit 0
else
  echo "ADA $FAILURES TES GAGAL ❌"
  exit 1
fi
