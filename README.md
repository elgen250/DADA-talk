# DADA Flutter 🌐📱
> **100% On-Device Neural Translation, Speech Recognition, OCR & Conversational AI Coach for iOS & Android**

[![Build iOS IPA](https://github.com/DADA-translator/DADA-translator/actions/workflows/build-ipa.yml/badge.svg)](https://github.com/DADA-translator/DADA-translator/actions)
[![Flutter](https://img.shields.io/badge/Flutter-3.24%2B-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.5%2B-0175C2?logo=dart)](https://dart.dev)
[![Target OS](https://img.shields.io/badge/Target_OS-iOS_18%2B_%2F_Android-black?logo=apple)](https://apple.com)
[![Privacy](https://img.shields.io/badge/Privacy-100%25_On--Device-success)](https://github.com)

---

## 🌟 Overview & Zero-Cost Architecture
**DADA Flutter** operates completely offline on the user's device without requiring any paid external cloud translation API subscriptions.

- **100% On-Device Neural Translation:** Powered by `google_mlkit_translation` & `google_mlkit_language_id` with downloadable offline language models.
- **Offline Speech-to-Text (STT):** Local speech recognition via `speech_to_text`.
- **Text-to-Speech (TTS):** Native device speech synthesis via `flutter_tts`.
- **Live Vision OCR:** Real-time text extraction and translation bounding box overlays via `google_mlkit_text_recognition` and `camera`.
- **Shared App Group:** Shared container (`group.com.DADA.translator`) for `DADAWidget` (WidgetKit) and `DADAKeyboard` (UIInputViewController) integration via `home_widget`.
- **Zero Issues Guarantee:** Verified with `flutter analyze` (**0 issues found**) and automated unit/widget tests.

---

## 🌍 Supported 19 Core Languages
| Flag | Language | Native Name | Code | Flag | Language | Native Name | Code |
| :---: | :--- | :--- | :---: | :---: | :--- | :--- | :---: |
| 🇸🇦 | Arabic | العربية | `ar` | 🇰🇷 | Korean | 한국어 | `ko` |
| 🇺🇸 | English | English | `en` | 🇮🇳 | Hindi | हिन्दी | `hi` |
| 🇪🇸 | Spanish | Español | `es` | 🇹🇷 | Turkish | Türkçe | `tr` |
| 🇫🇷 | French | Français | `fr` | 🇻🇳 | Vietnamese | Tiếng Việt | `vi` |
| 🇩🇪 | German | Deutsch | `de` | 🇹🇭 | Thai | ไทย | `th` |
| 🇮🇹 | Italian | Italiano | `it` | 🇮🇩 | Indonesian | Bahasa Indonesia | `id` |
| 🇵🇹 | Portuguese | Português | `pt` | 🇳🇱 | Dutch | Nederlands | `nl` |
| 🇷🇺 | Russian | Русский | `ru` | 🇵🇱 | Polish | Polski | `pl` |
| 🇨🇳 | Chinese | 简体中文 | `zh` | 🇺🇦 | Ukrainian | Українська | `uk` |
| 🇯🇵 | Japanese | 日本語 | `ja` | | | | |

---

## 📱 Screen Map & Feature Breakdown

1. **Onboarding Flow (`OnboardingScreen`)**:
   - 4 Sequential Introduction Pages: 19 Languages, Live Camera OCR, 100% Offline & Private, Interactive Coach James.
2. **Paywall (`PaywallScreen`)**:
   - Yearly plan (\$39.99/year - \$0.77/week `BEST VALUE`) with 3-day free trial.
   - Weekly plan (\$4.99/week `MOST POPULAR`).
   - Restores and persists `isProUser` in `group.com.DADA.translator`.
3. **Text Translate Tab (`TextTranslateScreen`)**:
   - Real-time neural translation, auto language detection, swap languages, mic input, TTS playback, favorite toggle, and SQLite history save.
4. **Live Talk Tab (`LiveTalkScreen`)**:
   - Split-screen face-to-face conversation with 180° rotation mode. Dual push-to-talk mic buttons and automatic spoken translation.
5. **Camera OCR Tab (`CameraOcrScreen`)**:
   - Real-time camera viewfinder with "Hold steady" reticle, shutter capture, gallery image picker, OCR text block recognition, and translated text drawers.
6. **Phrases & Coach Tab (`PhrasesCoachScreen`)**:
   - Curated phrasebook categorized into Casual, Travel, and Academic.
   - **Interactive Coach James:** Step-by-step roleplay dialogues (e.g., Airport, Café, Hotel) with speech recognition pronunciation scoring and XP rewards.
7. **History Tab (`HistoryScreen`)**:
   - 3-Way Segmented Control: `Text`, `Talk`, and `Lessons`.
   - Favorites filter, swipe-to-delete, and full history wipe.
8. **Settings Modal (`SettingsScreen`)**:
   - Offline Language Packs manager (Installed / Download status, download/delete local models).
   - Apple iOS DADA Keyboard setup walkthrough.
   - WidgetKit sync status (`group.com.DADA.translator`).
   - Theme toggle (Dark / Light / System) and interface locale (Arabic RTL / English LTR).

---

## 🛠️ Verification & Build Instructions

### Local Verification
```bash
# 1. Install dependencies
flutter pub get

# 2. Strict static analysis (0 errors guarantee)
flutter analyze

# 3. Automated smoke tests
flutter test
```

### iOS Release Build (Unsigned IPA)
```bash
# Build the release .app
flutter build ios --release --no-codesign

# Package into IPA
mkdir -p Payload
cp -r build/ios/iphoneos/Runner.app Payload/
zip -r -y DADATranslator-Flutter-Release.ipa Payload
```

---

## 📄 License
Proprietary © 2026 DADA Flutter. All rights reserved.
