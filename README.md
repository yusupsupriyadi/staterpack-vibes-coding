# staterpack-vibes-coding

Starterpack konfigurasi **AI coding** untuk Claude Code. Berisi kumpulan _skill_
siap pakai + hook + panduan workflow (`CLAUDE.md`). Cukup tempel satu **prompt**
ke Claude Code di project Anda, dan semuanya terpasang secara otomatis.

---

## 🚀 Cara pakai tercepat — tempel prompt ini ke Claude Code

Buka project Anda dengan Claude Code, lalu tempel prompt berikut:

```text
Pasang starterpack AI coding dari
https://github.com/yusupsupriyadi/staterpack-vibes-coding ke project ini.

Deteksi OS saya lalu jalankan installer resminya terhadap folder project saat ini,
secara NON-DESTRUKTIF (jangan timpa CLAUDE.md / .claude/settings.json yang sudah ada
— installer akan append + merge + membuat backup):

- Windows (PowerShell):
  irm https://raw.githubusercontent.com/yusupsupriyadi/staterpack-vibes-coding/master/install.ps1 | iex

- macOS/Linux (bash):
  curl -fsSL https://raw.githubusercontent.com/yusupsupriyadi/staterpack-vibes-coding/master/install.sh | bash

Setelah selesai, ringkas file apa saja yang ditambahkan / di-merge / di-backup.
```

Claude akan mengeksekusi installer yang sesuai dengan sistem Anda dan memasang
konfigurasi ke folder project yang sedang aktif.

---

## 🧰 Cara manual (tanpa prompt)

**Windows (PowerShell):**

```powershell
irm https://raw.githubusercontent.com/yusupsupriyadi/staterpack-vibes-coding/master/install.ps1 | iex
```

**macOS / Linux (bash):**

```bash
curl -fsSL https://raw.githubusercontent.com/yusupsupriyadi/staterpack-vibes-coding/master/install.sh | bash
```

**Atau clone dulu lalu jalankan lokal** (bisa memilih folder target):

```bash
git clone https://github.com/yusupsupriyadi/staterpack-vibes-coding.git
# Windows:
powershell -ExecutionPolicy Bypass -File staterpack-vibes-coding/install.ps1 -Local -Target /path/ke/project
# macOS/Linux:
bash staterpack-vibes-coding/install.sh --local --target /path/ke/project
```

Opsi installer:

| Opsi | Keterangan |
|------|------------|
| `--target <dir>` / `-Target <dir>` | Folder project tujuan (default: folder saat ini) |
| `--local` / `-Local` | Pakai konten repo lokal (tanpa clone ulang) |
| `--ref <branch\|tag>` / `-Ref <...>` | Pasang dari branch/tag tertentu |

---

## 📦 Isi starterpack

Terpasang ke `<project>/.claude/skills/`, `<project>/.claude/settings.json`, dan
`<project>/CLAUDE.md`.

**15 skill:**

| Skill | Fungsi singkat |
|-------|----------------|
| `brainstorming` | Ubah ide → desain/spek sebelum ngoding |
| `writing-plans` | Susun rencana implementasi bertahap |
| `executing-plans` | Eksekusi rencana dengan checkpoint review |
| `subagent-driven-development` | Eksekusi rencana lewat subagent |
| `dispatching-parallel-agents` | Jalankan beberapa tugas independen paralel |
| `test-driven-development` | TDD — tes gagal dulu, baru implementasi |
| `systematic-debugging` | Debug berbasis bukti & akar masalah |
| `requesting-code-review` | Minta review sebelum merge |
| `receiving-code-review` | Tanggapi review dengan rigor teknis |
| `verification-before-completion` | Verifikasi sebelum klaim "selesai" |
| `using-git-worktrees` | Isolasi kerja lewat git worktree |
| `finishing-a-development-branch` | Rampungkan & integrasikan branch |
| `using-superpowers` | Pondasi: cara menemukan & memakai skill |
| `writing-skills` | Membuat / mengubah / menguji skill |
| `graphify` | Ubah input apa pun jadi knowledge graph |

**Hooks (`.claude/settings.json`):** integrasi graphify — mengarahkan pencarian
kode ke knowledge graph saat `graphify-out/graph.json` tersedia.

**Workflow (`CLAUDE.md`):** panduan wajib Superpowers (skill gate, TDD gate,
debugging gate, completion gate, dsb.).

---

## 🛡️ Perilaku non-destruktif

Installer tidak pernah menimpa pekerjaan Anda begitu saja:

- **Skills** — disalin ke `.claude/skills/`. Jika sudah ada skill bernama sama
  dengan isi berbeda, versi lama dipindah ke `.claude/.staterpack-backup-<timestamp>/`.
- **`.claude/settings.json`** — kalau belum ada, disalin; kalau sudah ada,
  di-**merge** (hook digabung + dedupe berdasarkan `matcher`+`command`) dan file
  lama di-backup ke `settings.json.bak`.
- **`CLAUDE.md`** (dan `.claude/CLAUDE.md`) — konten starterpack ditaruh di antara
  penanda:

  ```text
  <!-- >>> staterpack-vibes-coding >>> -->
  ... isi starterpack ...
  <!-- <<< staterpack-vibes-coding <<< -->
  ```

  Kalau file sudah ada tanpa penanda, blok di-**append** dan file lama di-backup ke
  `CLAUDE.md.bak`. Menjalankan installer lagi hanya **memperbarui** blok itu
  (idempoten — tidak ada duplikat).

---

## ✅ Syarat

- **git** (untuk metode `curl|bash` / `irm|iex` yang meng-clone repo).
- **Node.js** — dipakai `install.sh` untuk merge `settings.json` yang sudah ada
  (sudah tersedia bila Anda memakai Claude Code). `install.ps1` memakai JSON
  bawaan PowerShell, tanpa Node.
- **PowerShell 5.1+** (Windows) atau **bash** (macOS/Linux/Git Bash).
- **python3** — hanya diperlukan saat _runtime_ hook graphify aktif (opsional).

---

## 🧹 Uninstall

1. Hapus blok di antara penanda `staterpack-vibes-coding` pada `CLAUDE.md` dan
   `.claude/CLAUDE.md` (atau pulihkan dari `*.bak`).
2. Pulihkan `.claude/settings.json` dari `settings.json.bak` bila perlu.
3. Hapus folder skill yang tidak Anda inginkan di `.claude/skills/`.

---

## 🧪 Pengembangan

Tes installer:

```bash
bash tests/test-install.sh                                   # macOS/Linux/Git Bash
powershell -NoProfile -File tests/test-install.ps1           # Windows
```

---

## 🙏 Kredit

Skill dalam repo ini berasal dari proyek pihak ketiga (**Superpowers** dan
**graphify**). Lihat [`NOTICE.md`](NOTICE.md) untuk atribusi dan catatan lisensi.
