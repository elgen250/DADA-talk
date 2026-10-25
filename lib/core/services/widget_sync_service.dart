import 'package:home_widget/home_widget.dart';

class WidgetSyncService {
  static final WidgetSyncService instance = WidgetSyncService._internal();
  WidgetSyncService._internal();

  static const String appGroupId = 'group.com.vava.translator';
  static const String widgetName = 'VAVAWidget';

  Future<void> init() async {
    try {
      await HomeWidget.setAppGroupId(appGroupId);
    } catch (_) {}
  }

  Future<void> syncLatestTranslation({
    required String sourceText,
    required String translatedText,
    required String sourceLang,
    required String targetLang,
  }) async {
    try {
      await HomeWidget.saveWidgetData<String>('latest_source', sourceText);
      await HomeWidget.saveWidgetData<String>('latest_translated', translatedText);
      await HomeWidget.saveWidgetData<String>('latest_source_lang', sourceLang);
      await HomeWidget.saveWidgetData<String>('latest_target_lang', targetLang);
      await HomeWidget.updateWidget(name: widgetName, iOSName: widgetName);
    } catch (_) {}
  }

  Future<void> syncProStatus(bool isPro) async {
    try {
      await HomeWidget.saveWidgetData<bool>('is_pro_user', isPro);
      await HomeWidget.updateWidget(name: widgetName, iOSName: widgetName);
    } catch (_) {}
  }

  Future<void> syncDailyPhrase({
    required String phrase,
    required String translation,
  }) async {
    try {
      await HomeWidget.saveWidgetData<String>('daily_phrase', phrase);
      await HomeWidget.saveWidgetData<String>('daily_phrase_translation', translation);
      await HomeWidget.updateWidget(name: widgetName, iOSName: widgetName);
    } catch (_) {}
  }
}

