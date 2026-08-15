# 🌸 KHOLO

**One calm home for body, baby, and everyday care.**

KHOLO is a privacy-first Flutter app that helps you track your menstrual cycle, pregnancy journey, baby care, and wellness — all stored privately on your device.

---

## ✨ Features

| Feature | Description |
|---------|-------------|
| 🩸 **Cycle tracking** | Phase-aware calendar, fertile window estimation, period prediction |
| 🤰 **Pregnancy support** | Week-by-week journey, symptom log, due date countdown |
| 👶 **Baby care** | Feeding, sleep, and milestone tracking for multiple babies |
| 🛍️ **Care shop** | Curated wellness essentials, cart & checkout |
| 📊 **Insights** | Hormone charts, mood trends, symptom patterns |
| 🔒 **Private by default** | All health data stays on your device — never uploaded |
| 🌙 **Dark mode** | Full dark theme with KHOLO brand accent preservation |
| 🔔 **Smart reminders** | Local notifications for period day, fertile window, daily log |
| 📥 **OTA updates** | In-app update banner + one-tap APK install from GitHub Releases |
| 🤚 **Biometric lock** | Fingerprint / face / PIN app lock |
| 📤 **Data export** | CSV export of your cycle logs via share sheet |

---

## 🏗️ Tech Stack

- **Flutter** 3.x / Dart 3.5+
- **Riverpod** (state management)
- **GoRouter** (navigation)
- **Shared Preferences** (local persistence)
- **flutter_local_notifications** (cycle reminders)
- **local_auth** (biometric lock)
- **share_plus** (CSV export)
- **dio + open_filex** (OTA update download & install)
- **package_info_plus** (version detection)

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK ≥ 3.5.0
- Android Studio or VS Code with Flutter extension
- Android device / emulator (Android 6.0+)

### Run locally
```bash
git clone https://github.com/Blackproxya2z/kholo-app.git
cd kholo-app
flutter pub get
flutter run
```

### Build release APK
```bash
flutter build apk --release
```

---

## 📦 OTA Update System

KHOLO includes a built-in OTA update system. When a new version is released:

1. Build a new APK: `flutter build apk --release`
2. Create a GitHub Release in this repo and upload the APK
3. Update [`kholo-releases/version.json`](https://github.com/Blackproxya2z/kholo-releases) with:
   ```json
   {
     "latestVersion": "1.1.0",
     "versionCode": 2,
     "releaseNotes": "• New features\n• Bug fixes",
     "apkUrl": "https://github.com/Blackproxya2z/kholo-app/releases/download/v1.1.0/kholo.apk",
     "forceUpdate": false
   }
   ```
4. Users already on the app will see the update banner on their next app open!

---

## 🔒 Privacy

KHOLO is designed with privacy as a first principle:
- All health data (cycle logs, baby profiles, pregnancy data) is stored **locally on the device only**
- No data is sent to external servers or analytics platforms
- The app only requires internet access for the optional OTA update check and shop features

---

## 📱 Screenshots

_Coming soon_

---

## 👨‍💻 Developed by

**Jain Azmain** — [@Blackproxya2z](https://github.com/Blackproxya2z)

---

## 📄 License

This project is proprietary software. All rights reserved.
