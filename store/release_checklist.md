# Release Checklist — Aziz Academy

## Android (signed APK / AAB)

1. Place keystore at `android/keystore.jks` (do NOT commit).
2. Create `android/key.properties` (gitignored):
   ```
   storePassword=...
   keyPassword=...
   keyAlias=upload
   storeFile=../keystore.jks
   ```
3. Confirm `android/app/build.gradle.kts` reads `key.properties` for
   `signingConfigs.release`. If not, wire it.
4. Build:
   ```
   flutter build appbundle --release
   ```
   Output: `build/app/outputs/bundle/release/app-release.aab` — upload to Play Console.
5. Sanity check: install the APK form on a real device and run through
   onboarding → home → 1 quiz → trophy room → certificate share.

## iOS (App Store ipa)

Currently untested on this dev machine (Windows). On a Mac:
```
flutter build ios --release
cd ios && pod install
open Runner.xcworkspace
# Archive → Distribute → App Store Connect
```

Required: paid Apple Developer account, App Store Connect entry, provisioning
profile. The app contains no IAP, no third-party SDKs, no permissions
beyond standard share/file-write — review should be smooth.

## Web (Vercel)

```
flutter build web --release --pwa-strategy=offline-first
bash scripts/post_build_strip.sh    # remove canvaskit chromium variants
vercel deploy --prod --yes
```
Lives at https://aziz-academy.com.

## Final pre-release verification

- [ ] `flutter analyze` clean
- [ ] `flutter test` passes 100%
- [ ] `python scripts/validate_quiz_packs.py` clean
- [ ] Web Lighthouse: Perf ≥ 0.70, Accessibility ≥ 0.90, BP ≥ 0.80, SEO ≥ 0.90
- [ ] Manual UX walk: language switch (EN ↔ AR), onboarding, daily challenge,
      Brain Boost champion mode, certificate share, parent dashboard PIN
- [ ] CHANGELOG.md updated for the release version
- [ ] Version bumped in `pubspec.yaml`
- [ ] Privacy policy URL reachable: https://aziz-academy.com/privacy
- [ ] Store listings refreshed in `store/listing_en.md`, `store/listing_ar.md`
