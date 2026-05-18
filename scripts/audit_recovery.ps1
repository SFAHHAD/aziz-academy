<#
.SYNOPSIS
  Aziz Academy - one-click audit recovery.

.DESCRIPTION
  Clears the stuck git index lock, makes a safety checkpoint commit of
  the current working tree, pushes to origin, then optionally executes
  the Phase-1 cleanup commits queued by the 2026-05-18 audit.

  Stages:
    1. Hard kill .git\index.lock if present.
    2. Checkpoint commit of every untracked + modified file on the
       current branch, tagged working-tree-YYYY-MM-DD.
    3. Push branch + tag to origin.
    4. (Optional, -DoCleanup) execute the audit cleanup commits.

  Every step is idempotent - re-running is safe.

.PARAMETER DoCleanup
  Switch. If set, runs the cleanup commits after the checkpoint.

.PARAMETER SkipPush
  Switch. If set, skips git push.

.EXAMPLE
  .\scripts\audit_recovery.ps1
.EXAMPLE
  .\scripts\audit_recovery.ps1 -DoCleanup
.EXAMPLE
  .\scripts\audit_recovery.ps1 -DoCleanup -SkipPush
#>

[CmdletBinding()]
param(
  [switch]$DoCleanup,
  [switch]$SkipPush
)

$ErrorActionPreference = 'Stop'
$ProgressPreference     = 'SilentlyContinue'

function Write-Step([string]$msg) {
  Write-Host ""
  Write-Host ("==== " + $msg + " ====") -ForegroundColor Cyan
}
function Write-OK([string]$msg)   { Write-Host ("  OK   " + $msg) -ForegroundColor Green }
function Write-Skip([string]$msg) { Write-Host ("  skip " + $msg) -ForegroundColor DarkGray }
function Write-Warn([string]$msg) { Write-Host ("  WARN " + $msg) -ForegroundColor Yellow }

# ---------- Sanity checks ----------
Write-Step "Sanity checks"
if (-not (Test-Path '.git')) {
  throw "Not inside a git repo. Run this from the Aziz Academy root."
}
$branch = (git rev-parse --abbrev-ref HEAD 2>$null).Trim()
if (-not $branch) { throw "git rev-parse failed." }
Write-OK ("Branch: " + $branch)
$today = (Get-Date -Format 'yyyy-MM-dd')

# ---------- 1. Kill stale index.lock ----------
Write-Step "1. Clear stuck .git\index.lock"
$lock = '.git\index.lock'
if (Test-Path $lock) {
  try {
    Remove-Item -LiteralPath $lock -Force -ErrorAction Stop
    Write-OK ("Removed " + $lock)
  } catch {
    Write-Warn ("Remove-Item failed: " + $_.Exception.Message)
    Write-Warn "Trying .NET File.Delete fallback..."
    [System.IO.File]::Delete((Resolve-Path $lock).Path)
    Write-OK "Removed via .NET"
  }
} else {
  Write-Skip "no lock present"
}

# ---------- 2. Checkpoint commit ----------
Write-Step "2. Checkpoint commit of working tree"
$dirty = (git status --porcelain).Length
if ($dirty -eq 0) {
  Write-Skip "tree is clean - nothing to checkpoint"
} else {
  git add -A
  $checkpointMsg = @"
checkpoint: pre-audit working tree $today

Safety snapshot before the 2026-05-18 audit cleanup.
The diff is large because about six weeks of feature work since the
April 20 commit had not been committed.

Triaging into a clean history happens in subsequent commits.
See AUDIT_PLAN.md / AUDIT_PROGRESS.md / FINDINGS.md.
"@
  git commit -m $checkpointMsg | Out-Null
  Write-OK "checkpoint commit created"
  git tag -f ("working-tree-" + $today)
  Write-OK ("tag working-tree-" + $today + " applied")
}

# ---------- 3. Push (optional) ----------
if (-not $SkipPush) {
  Write-Step "3. Push branch + tag"
  try {
    git push -u origin $branch
    Write-OK "branch pushed"
    git push origin ("working-tree-" + $today) 2>$null
    Write-OK "tag pushed"
    $preTag = "pre-audit-" + $today
    if (git tag | Select-String ("^" + [regex]::Escape($preTag) + "$")) {
      git push origin $preTag 2>$null
      Write-OK ("pre-audit tag pushed: " + $preTag)
    }
  } catch {
    Write-Warn ("push failed: " + $_.Exception.Message)
    Write-Warn "Continuing - local state is good; re-run with internet + auth."
  }
} else {
  Write-Skip "push skipped (-SkipPush)"
}

# ---------- 4. Cleanup commits ----------
if ($DoCleanup) {

  Write-Step "Q1. Untrack accidental web-build zip + analyzer dumps"
  $junk = @(
    'AzizAcademy_WebBuild.zip',
    'build.txt', 'build_log.txt',
    'analyze.txt', 'analyze_output.txt',
    'machine_analyze.txt', 'machine_analyze_utf8.txt'
  )
  $toRm = @()
  foreach ($f in $junk) {
    & git ls-files --error-unmatch -- $f 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) { $toRm += $f }
  }
  if ($toRm.Count -gt 0) {
    git rm -f -- $toRm | Out-Null
    $q1msg = @"
chore: untrack accidental web-build zip and analyzer dumps

These ~16MB+ were committed by mistake in 43070fe (Apr 6 2026).
The pre-audit tag preserves them in history if needed.
See FINDINGS.md F5 and AUDIT_PROGRESS.md Q1.
"@
    git commit -m $q1msg | Out-Null
    Write-OK ("Q1 committed (" + $toRm.Count + " files)")
  } else {
    Write-Skip "Q1 - nothing to untrack"
  }

  Write-Step "Q2. Move .py authoring scripts to scripts\authoring\"
  $authoring = @(
    'crop_v2.py','download_audio.py','extract_logo.py','fetch_logos.py',
    'fill_missing_capitals.py','fix_flags.py','fix_fun_facts.py',
    'generate_capitals.py','generate_logos.py','generate_sciences.py'
  )
  $existing = @()
  foreach ($f in $authoring) {
    if (Test-Path $f) { $existing += $f }
  }
  if ($existing.Count -gt 0) {
    if (-not (Test-Path 'scripts\authoring')) {
      New-Item -ItemType Directory -Path 'scripts\authoring' -Force | Out-Null
    }
    foreach ($f in $existing) {
      git mv -- $f ("scripts\authoring\" + $f) 2>$null
    }
    $q2msg = @"
chore: move root authoring scripts into scripts\authoring\

Keeps the repo root clean. CONTRIBUTING.md documents the new path.
"@
    git commit -m $q2msg | Out-Null
    Write-OK ("Q2 committed (" + $existing.Count + " files)")
  } else {
    Write-Skip "Q2 - .py scripts already moved"
  }

  Write-Step "Q3. Archive Aziz Academy.md -> docs\HISTORY.md"
  if (Test-Path 'Aziz Academy.md') {
    if (-not (Test-Path 'docs')) {
      New-Item -ItemType Directory -Path 'docs' -Force | Out-Null
    }
    git mv -- 'Aziz Academy.md' 'docs\HISTORY.md'
    $hist = Get-Content 'docs\HISTORY.md' -Raw
    $header = @"
> **Archived 2026-05-18.** This was the original v0.x README describing 8 modules.
> The current README is the source of truth and describes 130+ modules in v1.1.113.
> Kept here for historical context.


"@
    Set-Content -Path 'docs\HISTORY.md' -Value ($header + $hist) -Encoding UTF8
    git add 'docs\HISTORY.md'
    $q3msg = "docs: archive original v0.x README as docs\HISTORY.md"
    git commit -m $q3msg | Out-Null
    Write-OK "Q3 committed"
  } else {
    Write-Skip "Q3 - Aziz Academy.md already moved"
  }

  Write-Step "Q4. Remove empty lib\features\tangram\"
  if (Test-Path 'lib\features\tangram') {
    $count = (Get-ChildItem -Recurse -File 'lib\features\tangram' -ErrorAction SilentlyContinue).Count
    if ($count -eq 0) {
      Remove-Item 'lib\features\tangram' -Recurse -Force
      $q4msg = "chore: remove empty lib\features\tangram\ placeholder"
      git commit -am $q4msg 2>$null | Out-Null
      if ($LASTEXITCODE -eq 0) {
        Write-OK "Q4 committed"
      } else {
        Write-Skip "Q4 - tangram already untracked"
      }
    } else {
      Write-Warn ("Q4 - tangram has " + $count + " files; skipping")
    }
  } else {
    Write-Skip "Q4 - tangram already gone"
  }

  Write-Step "Q5. Stage audit deliverables"
  $deliverables = @(
    '.gitignore',
    '.github\workflows\flutter_ci.yml',
    'CONTRIBUTING.md',
    'pubspec.yaml',
    'assets\data\tajweed_basics.json',
    'AUDIT_PLAN.md',
    'AUDIT_PROGRESS.md',
    'FINDINGS.md',
    'docs\ARCHITECTURE.md',
    'analysis_options.proposed.yaml',
    'docs\notes\important.md',
    'docs\notes\points.md',
    'docs\notes\reply.md',
    'docs\notes\research.md',
    'scripts\audit_recovery.ps1'
  )
  foreach ($f in $deliverables) {
    if (Test-Path $f) { git add -- $f 2>$null }
  }
  $cachedCount = (git diff --cached --name-only).Length
  if ($cachedCount -gt 0) {
    $q5msg = @"
docs+chore: 2026-05-18 audit deliverables

Adds AUDIT_PLAN.md, AUDIT_PROGRESS.md, FINDINGS.md,
docs\ARCHITECTURE.md, analysis_options.proposed.yaml.

Fixes:
- pubspec.yaml: add missing assets\data\tajweed_basics.json (runtime bug).
- pubspec.yaml: dedupe aviation_history.json and classical_composers.json.
- assets\data\tajweed_basics.json: replace U+2192 arrows with ASCII ->.
- .gitignore: ignore root temp media, scratch text, lighthouse reports.
- .github\workflows\flutter_ci.yml: version + content audits.
- CONTRIBUTING.md: refresh stale l10n notes; document scripts\authoring\.

Moves Imprtant.txt, Points.txt, Reply.txt, Research.txt to docs\notes\.
"@
    git commit -m $q5msg | Out-Null
    Write-OK "Q5 committed"
  } else {
    Write-Skip "Q5 - nothing new to commit"
  }

  if (-not $SkipPush) {
    Write-Step "Final push"
    try {
      git push origin $branch
      Write-OK "pushed"
    } catch {
      Write-Warn ("push failed: " + $_.Exception.Message)
    }
  }
}

Write-Step "Done"
Write-Host ("  branch:   " + $branch)
$finalDirty = (git status --porcelain).Length
Write-Host ("  dirty:    " + $finalDirty + " entries")
Write-Host "  log:"
git --no-pager log --oneline -10
