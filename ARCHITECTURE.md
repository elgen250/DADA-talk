# VAVA Translator — Flutter & Native iOS Architectural Blueprint

## 1. الهوية والمواصفات الأساسية (Project Identity)
- **App Name:** VAVA Translator
- **Bundle Identifier:** `com.vava.translator`
- **Keyboard Extension Bundle ID:** `com.vava.translator.keyboard`
- **Widget Extension Bundle ID:** `com.vava.translator.widget`
- **Shared App Group:** `group.com.vava.translator`
- **Target OS:** iOS 18.0+ (Primary) / Android Compatible
- **Framework:** Flutter (3.24+ / Dart 3.5+) + Native iOS Swift Bridges (`FlutterMethodChannel`)
- **State Management:** `flutter_riverpod`
- **Local Database:** `sqflite` / `drift` (stored in shared App Group container on iOS) + `shared_preferences_foundation`

---

## 2. مبدأ العمل الأساسي: 100% معالجة محلية (Zero-Cost On-Device Engine)
لا يعتمد التطبيق على أي خوادم ترجمة خارجية مدفوعة. تتم جميع العمليات محلياً:
1. **محرك الترجمة النصية (On-Device Translation):**
   - **الخيار الأول (Native iOS Bridge):** عبر `MethodChannel('com.vava.translator/engine')` يستدعي إطار `Translation.framework` الأصيل في iOS 18.
   - **الخيار المدمج (Cross-Platform On-Device):** استخدام `google_mlkit_translation` و `google_mlkit_language_id` للترجمة العصبية المحلية وتنزيل حزم اللغات للعمل بدون إنترنت 100%.
2. **التعرف الصوتي (STT):** حزمة `speech_to_text` مربوطة بـ `SFSpeechRecognizer` المحلي (`onDevice: true`).
3. **النطق الصوتي (TTS):** حزمة `flutter_tts` مربوطة بـ `AVSpeechSynthesizer` وأصوات النظام.
4. **ترجمة الكاميرا والصور (OCR):** حزمة `camera` + `image_picker` + `google_mlkit_text_recognition` (أو جسر `Vision.framework`) لاستخراج النصوص ومواقعها (`Bounding Boxes`) ورسم الترجمة فوق الصورة.

---

## 3. اللغات المدعومة (19 Core Languages)
العربية (`ar`)، الإنجليزية (`en`)، الإسبانية (`es`)، الفرنسية (`fr`)، الألمانية (`de`)، الإيطالية (`it`)، البرتغالية (`pt`)، الروسية (`ru`)، الصينية المبسطة (`zh`)، اليابانية (`ja`)، الكورية (`ko`)، الهندية (`hi`)، التركية (`tr`)، الفيتنامية (`vi`)، التايلاندية (`th`)، الإندونيسية (`id`)، الهولندية (`nl`)، البولندية (`pl`)، الأوكرانية (`uk`).

---

## 4. هيكل مجلدات المشروع (Clean Architecture Directory Tree)
```text
vava_translator/
├── ARCHITECTURE.md
├── pubspec.yaml
├── .github/workflows/build-ipa.yml
├── lib/
│   ├── main.dart
│   ├── core/
│   │   ├── theme/          # AppTheme (Light/Dark, RTL support, Modern UI)
│   │   ├── constants/      # Supported 19 languages, flags, codes
│   │   └── services/
│   │       ├── translation_service.dart   # On-Device Translation & Language Detection
│   │       ├── speech_service.dart        # STT & TTS Manager
│   │       ├── ocr_service.dart           # Camera & Gallery OCR Bounding Boxes
│   │       ├── database_service.dart      # SQLite in Shared App Group
│   │       ├── widget_sync_service.dart   # home_widget sync with iOS WidgetKit
│   │       └── purchase_service.dart      # StoreKit / Pro Subscription state
│   ├── models/
│   │   ├── translation_history_item.dart  # id, sourceText, translatedText, sourceLang, targetLang, timestamp, category (text/talk/lesson), isFavorite
│   │   ├── phrase_item.dart               # id, category (casual/travel/academic), sourceText, translatedText, flags
│   │   └── lesson_progress.dart           # id, scenarioTitle, completedSteps, totalSteps, score
│   └── features/
│       ├── onboarding/     # 4 Screens: Globe, Camera, Offline, Coach James
│       ├── paywall/        # Unlock VAVA Pro ($39.99/yr Best Value, $4.99/wk Most Popular, 3-day trial, Restore)
│       ├── home_shell/     # Bottom Navigation Bar Shell
│       ├── text_translate/ # Text input, auto-detect, swap, TTS, copy, favorite
│       ├── live_talk/      # Split-screen dual microphone conversation, live bubbles & auto-TTS
│       ├── camera_ocr/     # Live camera preview ("Hold steady"), capture, gallery picker, translated overlay boxes
│       ├── phrases_coach/  # Categorized phrases + Interactive AI Coach ("James") curated scenarios
│       ├── history/        # 3-Way Segmented Control (Text / Talk / Lesson) + Favorites filter + Swipe to delete
│       └── settings/       # Offline Language Packs manager (Download/Installed status), Keyboard setup guide, Widget settings, Theme/RTL toggle
└── ios/
    ├── Runner/             # Info.plist (Mic, Speech, Camera permissions), Runner.entitlements (group.com.vava.translator)
    ├── VAVAWidget/         # Native SwiftUI WidgetKit Extension (reads shared SQLite/UserDefaults via home_widget)
    └── VAVAKeyboard/       # Native UIInputViewController Keyboard Extension
```

---

## 5. خريطة الشاشات والوظائف التفصيلية (Screens & Features Spec)
- **Onboarding Flow:** 4 صفحات تعريفية متسلسلة (دعم اللغات، ترجمة الكاميرا، العمل دون إنترنت، المدرب التفاعلي James) مع زر تخطي.
- **Paywall (Unlock VAVA Pro):** عرض الباقة السنوية ($39.99/year - $0.77/week BEST VALUE) والأسبوعية ($4.99/week MOST POPULAR) مع تجربة مجانية 3 أيام وحفظ حالة `isProUser` في الحاوية المشتركة `group.com.vava.translator`.
- **Text Tab:** إدخال نصي ديناميكي، كشف تلقائي للغة، تبديل اللغات (Swap)، استماع صوتي (TTS)، نسخ، إضافة للمفضلة، وحفظ تلقائي في السجل.
- **Talk Tab (Live Split-Screen):** شاشة منقسمة لمتحدثين (أو وجهاً لوجه)، زر ميكروفون لكل طرف، تفريغ صوتي فوري في فقاعات دردشة، ترجمة ونطق تلقائي.
- **Camera Tab (Live OCR):** معاينة الكاميرا مع إرشاد ("Hold steady")، التقاط صورة أو استيراد من المعرض، استخراج النصوص ورسم صناديق الترجمة فوق أماكنها الأصلية.
- **Phrases & Coach Tab:**
  - مكتبة عبارات مصنفة: يومية (`Casual`)، سفر (`Travel`)، أكاديمية (`Academic`).
  - المدرب التفاعلي ("Hi, I'm James!"): محادثات سيناريو مسبقة الإعداد لتدريب المستخدم على النطق والترجمة محلياً وحفظ التقدم في `LessonProgress`.
- **History Tab:** مقسم ثلاثي (`Text` | `Talk` | `Lessons`) + فلتر المفضلة (`Favorites`) + حذف بالسحب أو مسح الكل (`Clear all`).
- **Settings Modal:** إدارة تنزيل حزم اللغات الـ 19 للعمل بدون إنترنت، شرح خطوات تفعيل لوحة المفاتيح (`VAVAKeyboard`)، إعدادات الويدجت، وتغيير اللغة/المظهر.

---

## 6. التكامل مع ملحقات iOS (App Extensions via group.com.vava.translator)
- استخدام حزمة `home_widget` لمزامنة العبارات اليومية وحالة الاشتراك بين Flutter وملحق `VAVAWidget` و `VAVAKeyboard` عبر `UserDefaults(suiteName: "group.com.vava.translator")`.
- ضبط جميع الأذونات في `ios/Runner/Info.plist`:
  - `NSMicrophoneUsageDescription`
  - `NSSpeechRecognitionUsageDescription`
  - `NSCameraUsageDescription`
  - `NSPhotoLibraryUsageDescription`
- ضبط `MinimumOSVersion` على `16.0` لدعم جميع أجهزة iOS الحديثة وواجهات البرمجة المتقدمة.

---

## 7. نماذج البيانات (Data Models)
1. **TranslationHistoryItem**:
   - `id`: int / String (معرف السجل)
   - `sourceText`: String (النص الأصلي)
   - `translatedText`: String (النص المترجم)
   - `sourceLang`: String (رمز لغة المصدر مثل 'en', 'ar')
   - `targetLang`: String (رمز لغة الهدف مثل 'ar', 'en')
   - `timestamp`: DateTime (تاريخ ووقت الترجمة)
   - `category`: String ('text', 'talk', 'lesson')
   - `isFavorite`: bool (حالة التفضيل)

2. **PhraseItem**:
   - `id`: String
   - `category`: String ('casual', 'travel', 'academic')
   - `sourceText`: String
   - `translatedText`: String
   - `sourceLang`: String
   - `targetLang`: String
   - `isFavorite`: bool

3. **LessonProgress**:
   - `id`: String
   - `scenarioTitle`: String
   - `completedSteps`: int
   - `totalSteps`: int
   - `score`: int
   - `isCompleted`: bool
