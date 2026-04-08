# iOS release without a Mac (step-by-step)

You do **not** need a Mac on your desk. The **Mac runs on GitHub** (`macos-latest`) to build the `.ipa`. Your job is to complete Apple’s browser steps once, then paste secrets into GitHub.

**Bundle ID (fixed for this project):** `com.azizacademy.azizAcademy`  
**CI workflow:** `.github/workflows/release_stores.yml` → **Release — Play & TestFlight**

---

## Phase 0 — One-time checklist

| # | Item | You |
|---|------|-----|
| 1 | Paid **Apple Developer Program** | Confirm |
| 2 | **App ID** registered for `com.azizacademy.azizAcademy` | Done in Identifiers |
| 3 | **App record** in App Store Connect (same bundle ID) | Create if missing |
| 4 | **GitHub** repo is this project, Actions enabled | Confirm |

---

## Phase 1 — Apple Distribution certificate (`.p12`) without Mac

Apple’s docs assume Keychain on macOS. On **Windows**, use **OpenSSL** (install [Git for Windows](https://git-scm.com/download/win) — it includes `openssl.exe` — or [Win32 OpenSSL](https://slproweb.com/products/Win32OpenSSL.html)).

### 1.1 Generate CSR + private key

From the project folder in **PowerShell**:

```powershell
cd "path\to\Aziz Academy"
.\scripts\win_apple_distribution_cert.ps1 -Step Csr -OutputDir "$env:USERPROFILE\Desktop\apple_aziz_release"
```

The script prints the **exact** `openssl` commands if OpenSSL is missing.

You get:

- `CertificateSigningRequest.certSigningRequest` — upload this to Apple.
- `private.key` — **keep secret**; you need it to build `.p12`.

### 1.2 Create the certificate on Apple

1. Open [Certificates, Identifiers & Profiles → Certificates](https://developer.apple.com/account/resources/certificates/list).
2. **+** → **Apple Distribution** → Continue.
3. Upload your **CSR** file → Continue → **Download** the `.cer` (often named `distribution.cer`).

### 1.3 Build `.p12` (certificate + private key)

Still in PowerShell (same folder as `private.key` and the downloaded `.cer`):

```powershell
.\scripts\win_apple_distribution_cert.ps1 -Step P12 `
  -CerPath "$env:USERPROFILE\Desktop\apple_aziz_release\ios_distribution.cer" `
  -KeyPath "$env:USERPROFILE\Desktop\apple_aziz_release\private.key" `
  -P12Path "$env:USERPROFILE\Desktop\apple_aziz_release\AppleDistribution.p12" `
  -P12Password "use-a-strong-password-you-will-remember"
```

Choose a **strong** password — you will use it twice as GitHub secrets (`IOS_DISTRIBUTION_CERTIFICATE_PASSWORD`).

**Keep** `private.key` and `.p12` off the repo and out of chat. Back them up somewhere safe (password manager / encrypted disk).

---

## Phase 2 — App Store provisioning profile

1. [Profiles → +](https://developer.apple.com/account/resources/profiles/list) → **App Store** (distribution).
2. Select **App ID** `com.azizacademy.azizAcademy`.
3. Select the **Apple Distribution** certificate you just created.
4. Name the profile something clear, e.g. `Aziz Academy App Store` — **copy this exact name** (GitHub secret `IOS_PROVISIONING_PROFILE_NAME`).
5. **Download** the `.mobileprovision` file.

**Team ID:** 10 characters — copy from [Membership](https://developer.apple.com/account#MembershipDetailsCard) (not the long account number in App Store Connect). GitHub secret: `IOS_TEAM_ID`.

---

## Phase 3 — App Store Connect API (upload)

1. [App Store Connect → Users and Access → Integrations → App Store Connect API](https://appstoreconnect.apple.com/access/integrations/api).
2. Copy **Issuer ID** (UUID at the top). GitHub secret: `APP_STORE_CONNECT_ISSUER_ID`.
3. Confirm your key exists; **Key ID** for `AuthKey_SWKQYRLMSP.p8` is `SWKQYRLMSP`. GitHub secret: `APP_STORE_CONNECT_KEY_ID` = `SWKQYRLMSP`.
4. Base64-encode the **entire** `.p8` file (no line breaks in the secret):

```powershell
.\scripts\encode_file_base64.ps1 -Path "C:\path\to\AuthKey_SWKQYRLMSP.p8" -CopyToClipboard
```

Paste into GitHub secret: `APP_STORE_CONNECT_API_KEY_BASE64`.

---

## Phase 4 — GitHub repository secrets

Repo → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**.

Use `docs/github_actions_secrets_checklist.txt` as a copy-paste checklist.

| Secret name | What to paste |
|-------------|----------------|
| `IOS_TEAM_ID` | 10-char Team ID from Membership |
| `IOS_PROVISIONING_PROFILE_NAME` | Exact profile name from Phase 2 (e.g. `Aziz Academy App Store`) |
| `IOS_DISTRIBUTION_CERTIFICATE_BASE64` | Base64 of `AppleDistribution.p12` (`encode_file_base64.ps1`) |
| `IOS_DISTRIBUTION_CERTIFICATE_PASSWORD` | Password you used for `.p12` |
| `IOS_PROVISIONING_PROFILE_BASE64` | Base64 of `.mobileprovision` |
| `APP_STORE_CONNECT_ISSUER_ID` | Issuer UUID |
| `APP_STORE_CONNECT_KEY_ID` | `SWKQYRLMSP` |
| `APP_STORE_CONNECT_API_KEY_BASE64` | Base64 of full `.p8` |

---

## Phase 5 — Run the release workflow

1. Push the latest code to **GitHub** (`main` or `master`).
2. **Actions** → **Release — Play & TestFlight** → **Run workflow**.
3. Set **run_ios** = `true`. If you are not ready for Android, set **run_android** = `false`.
4. Run workflow.

Wait for the **ios_testflight** job to finish. Then **App Store Connect** → your app → **TestFlight** — the build should appear after processing (often 5–20 minutes).

---

## Phase 6 — After the first build

- **Export compliance** (encryption): already declared in `Info.plist` (`ITSAppUsesNonExemptEncryption` = false) for standard HTTPS; answer prompts in App Store Connect if asked.
- **App Privacy** / **Kids** category: complete questionnaires as required for your audience.
- **Screenshots & metadata** before submitting to App Review.

---

## Troubleshooting

| Problem | What to try |
|---------|-------------|
| **Signing failed** on CI | Team ID wrong; profile name must match **exactly**; `.p12` must match the Distribution cert used in the profile. |
| **altool** upload fails | Issuer ID / Key ID / base64 `.p8` wrong; key role must **App Manager** or **Admin**. |
| **No build in TestFlight** | Wait for processing; check email for Apple errors; verify bundle ID matches App Store Connect app. |

---

## What you never commit

- `.p8`, `.p12`, `private.key`, `.mobileprovision`, `key.properties`, `upload-keystore.jks`, or any **base64** of those in source files.

All of those belong only in **GitHub Actions secrets** (or your private vault).
