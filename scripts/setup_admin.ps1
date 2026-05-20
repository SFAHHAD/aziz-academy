<#
.SYNOPSIS
  Aziz Academy admin setup — guides you through Supabase migration + admin
  bootstrap with zero hidden steps. You stay in control of credentials at
  every step; this script just copies SQL to your clipboard and opens the
  right pages.

.DESCRIPTION
  Run from the repo root after applying the audit commits. The script:
    1. Copies migration #1 (qbank_drafts) to clipboard, opens Supabase SQL Editor.
    2. Waits for you to paste + run + confirm.
    3. Repeats for migration #2 (feature_flags).
    4. Opens the Supabase Auth Users page so you can create your admin user.
    5. Asks you for the user UID (which you paste from the dashboard).
    6. Copies the INSERT statement for admin_users to clipboard for you to run.

  Nothing here logs in for you, sends credentials, or stores secrets. You
  click; the script just queues the next thing for you to click.

.EXAMPLE
  .\scripts\setup_admin.ps1
#>

[CmdletBinding()]
param(
  [string]$SupabaseProjectId = "pwdhwhpnwrlzrerrdqvg"
)

$ErrorActionPreference = 'Stop'

function Step([string]$title) {
  Write-Host ""
  Write-Host ("==== " + $title + " ====") -ForegroundColor Cyan
}

function Press([string]$msg = "Press Enter when done") {
  Read-Host $msg | Out-Null
}

function CopyToClip([string]$text) {
  $text | Set-Clipboard
}

function OpenUrl([string]$url) {
  Start-Process $url
}

# Sanity
$repoRoot = Resolve-Path .
$mig1 = Join-Path $repoRoot "supabase/migrations/2026_05_18_qbank_drafts.sql"
$mig2 = Join-Path $repoRoot "supabase/migrations/2026_05_18b_feature_flags.sql"

if (-not (Test-Path $mig1)) { throw "Missing $mig1 — run from repo root." }
if (-not (Test-Path $mig2)) { throw "Missing $mig2 — run from repo root." }

$sqlEditor = "https://app.supabase.com/project/$SupabaseProjectId/sql/new"
$authUsers = "https://app.supabase.com/project/$SupabaseProjectId/auth/users"

Write-Host ""
Write-Host "Aziz Academy — admin setup wizard" -ForegroundColor Green
Write-Host "Project: $SupabaseProjectId"
Write-Host "All credentials stay in your browser; this script never sees them."
Write-Host ""

# ---------------------------------------------------------------------------
Step "1 / 4 — Apply qbank_drafts migration"
Write-Host "  Copying migration #1 (qbank_drafts) to your clipboard..." -ForegroundColor Yellow
CopyToClip (Get-Content $mig1 -Raw)
Write-Host "  ✓ On clipboard."
Write-Host "  Opening Supabase SQL Editor in your default browser..." -ForegroundColor Yellow
OpenUrl $sqlEditor
Write-Host ""
Write-Host "  In the SQL Editor that just opened:"
Write-Host "    a) Paste (Ctrl+V) — should fill the editor with ~7 KB of SQL."
Write-Host "    b) Click Run (or Ctrl+Enter)."
Write-Host "    c) Wait for 'Success' / no errors."
Press "  Press Enter once migration #1 finished successfully"

# ---------------------------------------------------------------------------
Step "2 / 4 — Apply feature_flags migration"
Write-Host "  Copying migration #2 (feature_flags) to your clipboard..." -ForegroundColor Yellow
CopyToClip (Get-Content $mig2 -Raw)
Write-Host "  ✓ On clipboard. Same SQL Editor — clear, paste, Run."
Write-Host "  (Or open a New query if you closed the tab.)"
Press "  Press Enter once migration #2 finished successfully"

# ---------------------------------------------------------------------------
Step "3 / 4 — Create your admin auth user"
Write-Host "  Opening Supabase Auth → Users in your browser..." -ForegroundColor Yellow
OpenUrl $authUsers
Write-Host ""
Write-Host "  In the page that just opened:"
Write-Host "    a) Click 'Add user' → 'Create new user'."
Write-Host "    b) Email: pick the email you want as your admin login."
Write-Host "    c) Password: type a NEW strong password (do NOT reuse one from elsewhere)."
Write-Host "    d) ✓ Check 'Auto Confirm User?' (skips the confirmation email)."
Write-Host "    e) Click 'Create user'."
Write-Host "    f) On the user list, click the new row to expand it."
Write-Host "    g) Copy the User UID (long uuid like a1b2c3d4-...)."
Write-Host ""
$uid = Read-Host "  Paste the User UID here"
$uid = $uid.Trim()
if ($uid -notmatch '^[0-9a-fA-F-]{36}$') {
  throw "That doesn't look like a UUID. Expected 36-char hex like a1b2c3d4-...."
}
$email = Read-Host "  Paste the same admin email for the audit row"
$email = $email.Trim()
if ($email -notmatch '^[^@\s]+@[^@\s]+\.[^@\s]+$') {
  throw "That doesn't look like an email."
}

# ---------------------------------------------------------------------------
Step "4 / 4 — Insert your admin_users row"
$insertSql = @"
-- Bootstrap row for $email (auth uid: $uid)
insert into public.admin_users (uid, email)
  values ('$uid', '$email')
  on conflict (uid) do update set email = excluded.email;

-- Verify
select * from public.admin_users;
-- Should show your single row.
"@
CopyToClip $insertSql
Write-Host "  ✓ INSERT statement on clipboard. Same SQL Editor → New query → paste → Run."
OpenUrl $sqlEditor
Press "  Press Enter once the INSERT showed your row in the result"

# ---------------------------------------------------------------------------
Step "Done"
Write-Host "  Your admin account is set up." -ForegroundColor Green
Write-Host ""
Write-Host "  Next:"
Write-Host "    1. Sign into the app with the same email + password you just used."
Write-Host "    2. Navigate to /x9k2-admin-portal."
Write-Host "    3. You should see the Q-Bank CRUD + Feature Flags sections unlocked."
Write-Host ""
Write-Host "  If anything looks off, the audit log in qbank_audit will tell you who did what."
