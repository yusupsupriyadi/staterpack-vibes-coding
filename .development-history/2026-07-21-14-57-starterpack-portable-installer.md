# Starterpack portable + installer lintas-OS

**Tanggal:** 2026-07-21 14:57

## Ringkasan
Menjadikan repo ini starterpack AI coding yang portable: skill di-*vendor*, plus
installer + prompt agar pengguna bisa memasang config ke project mereka.

## Konteks sebelumnya
Belum ada history. Temuan awal: 14 dari 15 skill di `.claude/skills/` berupa
**symlink** ke `/c/Users/yusup/Project/.agents/skills/<nama>` (path spesifik mesin),
sehingga repo tidak portable saat di-clone orang lain. Hanya `graphify` yang punya
konten nyata.

## Perubahan
- **Materialize skills:** 14 symlink diganti file nyata (dereference `cp -RL`,
  konten dari `.agents/skills`). Terverifikasi `git ls-files -s` tidak lagi punya
  mode `120000`; total 15 `SKILL.md`.
- **Installer non-destruktif** (`install.sh` + `install.ps1`): copy skills
  (backup jika bentrok), merge `settings.json` (dedupe hook), append/refresh blok
  `CLAUDE.md` di antara penanda. Idempoten. Mendukung mode `--local` dan
  clone-otomatis (`curl|bash` / `irm|iex`).
- **Tes TDD** (`tests/test-install.sh`, `tests/test-install.ps1`): 4 skenario
  (fresh, idempotensi, non-destruktif CLAUDE.md, merge settings) — RED dulu, lalu
  GREEN. Keduanya PASS (exit 0).
- **Dokumentasi:** `README.md` (prompt copy-paste + one-liner), `NOTICE.md`
  (atribusi Superpowers + graphify), `.gitattributes` (LF untuk `*.sh`).

## Keputusan teknis
- `install.sh` memakai **node** (bukan `python3`) untuk merge JSON: `python3` di
  mesin dev = shim Store yang rusak, sedangkan node dijamin ada untuk pengguna
  Claude Code. Jalur umum (target belum punya settings.json) tetap `cp` biasa.
- `install.ps1` memakai JSON bawaan PowerShell (tanpa dependensi), tulis UTF-8
  tanpa BOM agar aman dibaca parser.

## Verifikasi
`bash tests/test-install.sh` → SEMUA LULUS (exit 0). `tests/test-install.ps1` →
SEMUA LULUS (exit 0). `bash -n install.sh` OK; parse `install.ps1` OK. Smoke test
fresh install: 15 skill, settings.json valid & identik sumber, blok CLAUDE.md rapi.

## Keterbatasan / tindak lanjut
- Lisensi upstream skill belum terverifikasi (tidak ada file lisensi di sumber) —
  dicatat di `NOTICE.md`.
- One-liner `curl|bash` / `irm|iex` baru bisa diuji end-to-end setelah push (butuh
  repo publik & file mentah di `master`).
