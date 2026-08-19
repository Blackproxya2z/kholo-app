# 🌸 KHOLO PROJECT CONTEXT & MASTER GUIDE FOR ANTIGRAVITY

This repository contains the complete production codebase for **KHOLO — A calm home for body, baby, and everyday care.**

---

## 📍 Project Location & Environment
- **Primary Development Root:** `D:\Kholo APP\flutter_application_1`
- **Backup / Secondary Root:** `C:\Users\Jain\Desktop\Kholo APP\flutter_application_1`
- **App Package Name:** `app.kholo.care`
- **Flutter Version:** Flutter 3.24+ / Dart 3.5+
- **GitHub Repository:** `Blackproxya2z/kholo-app`
- **Releases CDN Repository:** `Blackproxya2z/kholo-releases`

---

## 🏗️ Core Architecture Overview

1. **State Management:** Riverpod 2.5 (`ProviderScope`, `StateNotifierProvider`)
2. **Routing:** `GoRouter` with persistent bottom navigation shell (`KholoBottomNav`)
3. **Core Features:**
   - 🌸 **Bloom Health Hub:** Curated 8-category health discovery magazine, search engine, bookmarks & daily streaks (`lib/features/bloom/`)
   - 🧠 **AI Health Guide:** Bilingual conversational health companion with clinical citations (`lib/core/services/bloom_ai_guide_service.dart`)
   - 🩸 **Cycle Tracking:** Cycle phase engine, fertility window & symptoms logging (`lib/features/cycle/`)
   - 🤰 **Pregnancy Tracker:** Week-by-week fetal growth, milestones & maternal tips (`lib/features/pregnancy/`)
   - 👶 **Baby Care:** Feeding, sleep, milestone logging & growth charts (`lib/features/baby/`)
   - ✨ **AI Skin Scan:** Real-time dermatology & skincare analyzer (`lib/features/skin_scan/`)
   - 🛍️ **Shop & Checkout:** Integrated care essentials store (`lib/features/shop/`, `lib/features/cart/`, `lib/features/checkout/`)
4. **Update & Delivery System:**
   - Single Source of Truth: `UpdateService` (`lib/core/services/update_service.dart`)
   - Smart deduplication (Zero repeated notifications on app open)
   - Resumable streaming APK download with live progress (%)
   - Streaming cryptographic SHA-256 validation before launching Android Package Installer
   - 100% On-Device Data Preservation guarantee

---

## 🚀 How to Make & Deploy an Update

Whenever the user asks to update the app or release a new version:

1. **Increment Version:**
   Update `version` in `pubspec.yaml` (e.g. `1.4.3+25`).
2. **Execute Automated 1-Click Pipeline:**
   ```powershell
   powershell -ExecutionPolicy Bypass -File scripts\publish_release.ps1
   ```
   *This automatically builds the signed release APK, calculates SHA-256 and file size, updates `version.json`, creates the GitHub Release tag, uploads the APK, and syncs the CDN.*
3. **Verify Tests & Analysis:**
   ```bash
   flutter analyze
   flutter test
   ```

---

## 🛡️ Zero Data Loss Guarantee
Local user preferences, cycle logs, pregnancy milestones, baby records, and bookmarks are stored via `LocalStorageService` / `SharedPreferences` and are preserved across all app updates.
