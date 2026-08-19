# KHOLO Backend & Admin Control Operations Guide

This guide describes how administrators can manage updates, broadcast announcements, toggle dynamic feature flags, and trigger emergency maintenance without requiring an application rebuild or re-release.

---

## 1. Firebase Remote Config Control Panel

The KHOLO client polls and activates Firebase Remote Config parameters periodically and on app resume.

### Remote Config Parameters Schema

| Parameter Name | Data Type | Default Value | Description |
| :--- | :--- | :--- | :--- |
| `latest_version` | String | `"1.3.0"` | Current stable version tag (e.g., `"1.3.1"`). |
| `version_code` | Integer | `20` | Monotonic build number (e.g., `21`). |
| `force_update` | Boolean | `false` | If `true`, enforces a blocking mandatory update screen. |
| `optional_update` | Boolean | `true` | If `true`, shows a non-blocking in-app notification banner. |
| `release_notes` | String | `"🌸 নতুন KHOLO আপডেট!..."` | Release highlights in Bengali & English. |
| `apk_url` | String | `"https://github.com/..."` | Direct HTTPS CDN download link for the release APK. |
| `apk_sha256` | String | `""` | SHA-256 cryptographic signature for tamper protection. |
| `maintenance_mode` | Boolean | `false` | If `true`, displays a temporary calm maintenance screen. |
| `maintenance_message`| String | `"KHOLO is undergoing scheduled maintenance..."` | Message displayed during maintenance. |
| `feature_flags` | JSON | *(See below)* | Granular feature toggles. |
| `announcements` | JSON | *(See below)* | Active broadcast banners across the app. |

---

## 2. Dynamic Feature Flags (`feature_flags`)

Configure feature availability instantly by editing the JSON payload in Firebase Console:

```json
{
  "ai_skin_scan_enabled": true,
  "baby_care_enabled": true,
  "pregnancy_journey_enabled": true,
  "cycle_tracker_enabled": true,
  "shop_enabled": true,
  "fertility_insights_enabled": true,
  "teleconsultation_enabled": false
}
```

---

## 3. Dynamic Announcements (`announcements`)

Publish time-sensitive alerts, clinical tips, or celebration banners to all users instantly:

```json
[
  {
    "id": "festive_greeting_2026",
    "title": "🌸 Special Wellness Update",
    "message": "Stay hydrated and discover our new cycle nutrition guidelines.",
    "type": "info",
    "isDismissible": true
  }
]
```

---

## 4. Emergency Maintenance Workflow

If backend maintenance or database restructuring is needed:
1. Open Firebase Console -> **Remote Config**.
2. Set `maintenance_mode` to `true`.
3. Set `maintenance_message` to your desired advisory.
4. Click **Publish changes**.
5. All connected active apps will switch to the calm maintenance state within the cache refresh window.
6. When complete, set `maintenance_mode` back to `false` and republish.

---

## 5. Publishing an In-App OTA Update

1. Build the signed release APK:
   ```bash
   flutter build apk --release
   ```
2. Compute the cryptographic SHA-256 checksum:
   ```powershell
   Get-FileHash -Algorithm SHA256 build/app/outputs/flutter-apk/app-release.apk
   ```
3. Upload the APK to your GitHub Releases or Firebase Storage CDN.
4. Update `version.json` on GitHub and Firebase Remote Config:
   - `latest_version`: `"1.3.1"`
   - `version_code`: `21`
   - `apk_url`: `"https://cdn.kholo.care/releases/v1.3.1/app-release.apk"`
   - `apk_sha256`: `"<sha256_hash_here>"`
   - `force_update`: `false` (or `true` for critical security patch)
5. Send FCM Broadcast notification via topic `kholo_updates`:
   - Payload:
     ```json
     {
       "payload": "kholo_update",
       "latest_version": "1.3.1",
       "version_code": 21,
       "force_update": "false",
       "title": "🌸 নতুন KHOLO আপডেট উপলব্ধ",
       "body": "নতুন ফিচার এবং অপ্টিমাইজেশন উপভোগ করতে ট্যাপ করুন।"
     }
     ```
