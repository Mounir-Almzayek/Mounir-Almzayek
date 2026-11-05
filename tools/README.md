# Repository About descriptions (November 2026)

Curated English **GitHub About / Description** text for the **29 repositories owned by `Mounir-Almzayek`** (27 public and 2 private).

## Purpose

- One concise sentence per repository: what it is, what it does, and the strongest evidenced technical element.
- Prefer the implemented project to unsupported commercial or performance claims.
- Mention experimental, academic, or exploratory status where applicable.
- Keep each description under 160 characters for compact display.
- Retain existing repository names, visibility, topics, and source code without changes.

Descriptions were reviewed against available repository metadata, README content, and selected source trees. In some older Flutter projects, the README remains the default generated Flutter template; the short descriptions therefore rely conservatively on available repository metadata and files, not invented measurements.

## Files

- [repository-about-descriptions.json](repository-about-descriptions.json) — 29 proposed descriptions, keyed by exact repository name.
- [apply-repo-descriptions.ps1](apply-repo-descriptions.ps1) — PowerShell 5.1+ preview, backup, authenticated batch update, and post-write verification.

## How to apply on Windows

1. Install GitHub CLI if needed: `winget install --id GitHub.cli --exact`.
2. Sign in to the intended account with `gh auth login` (must authenticate as `Mounir-Almzayek`).
3. Clone this profile repository or open an existing local copy.
4. Preview and inspect every proposed change:

   ```powershell
   powershell -NoProfile -File .\tools\apply-repo-descriptions.ps1
   ```

5. Apply after reviewing:

   ```powershell
   powershell -NoProfile -File .\tools\apply-repo-descriptions.ps1 -Apply
   ```

The script checks the account, reads all existing descriptions before any writes, saves a local JSON backup under Documents/GitHub-Description-Backups, edits **only** descriptions, and verifies each new value. It does not change any repo visibility or expose private repository contents.

**Connection limitation:** The currently connected GitHub actions allow editing source files but do not expose the REST `PATCH /repos/{owner}/{repo}` action needed to change repository *About* metadata. Committing this manifest does **not** update About descriptions until the CLI application is run.

[GitHub CLI reference](https://cli.github.com/manual/gh_repo_edit)
