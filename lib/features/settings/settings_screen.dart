import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/languages.dart';
import '../../core/services/purchase_service.dart';
import '../../core/services/settings_service.dart';
import '../../core/services/translation_service.dart';
import '../../core/theme/app_theme.dart';
import '../paywall/paywall_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final Map<String, bool> _downloadedModels = {};
  final Set<String> _downloadingCodes = {};
  bool _isLoadingPacks = true;

  @override
  void initState() {
    super.initState();
    _checkDownloadedModels();
  }

  Future<void> _checkDownloadedModels() async {
    setState(() => _isLoadingPacks = true);
    for (final lang in kSupportedLanguages) {
      final isDownloaded =
          await TranslationService.instance.isModelDownloaded(lang.code);
      _downloadedModels[lang.code] = isDownloaded;
    }
    if (mounted) {
      setState(() => _isLoadingPacks = false);
    }
  }

  Future<void> _toggleDownload(AppLanguage lang) async {
    final isDownloaded = _downloadedModels[lang.code] ?? false;

    setState(() => _downloadingCodes.add(lang.code));

    if (isDownloaded) {
      await TranslationService.instance.deleteModel(lang.code);
      _downloadedModels[lang.code] = false;
    } else {
      await TranslationService.instance.downloadModel(lang.code);
      _downloadedModels[lang.code] = true;
    }

    if (mounted) {
      setState(() => _downloadingCodes.remove(lang.code));
    }
  }

  void _showKeyboardGuide() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _KeyboardGuideSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final settings = ref.watch(settingsProvider);
    final purchase = ref.watch(purchaseProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات وحزم اللغات'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // Pro Status Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: purchase.isPro
                      ? [const Color(0xFF00C48C), const Color(0xFF00A374)]
                      : [const Color(0xFF5B4DFB), const Color(0xFF7D5FFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      purchase.isPro
                          ? Icons.verified_rounded
                          : Icons.workspace_premium_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          purchase.isPro
                              ? 'VAVA Pro مفعل (مدى الحياة/سنوي)'
                              : 'ترقية إلى VAVA Pro',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          purchase.isPro
                              ? 'جميع حزم الترجمة وجميع مزايا الكاميرا والمدرب مفعلة'
                              : 'افتح جميع حزم اللغات الـ 19 دون إنترنت بالكامل',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!purchase.isPro)
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const PaywallScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        minimumSize: Size.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'ترقية',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Section 1: Appearance & Language
            _buildSectionHeader('المظهر ولغة التطبيق (Appearance)'),
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : AppTheme.lightSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                ),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.dark_mode_rounded),
                    title: const Text('الوضع الليلي (Dark Mode)'),
                    trailing: DropdownButton<ThemeMode>(
                      value: settings.themeMode,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(
                            value: ThemeMode.system, child: Text('النظام')),
                        DropdownMenuItem(
                            value: ThemeMode.light, child: Text('نهاري')),
                        DropdownMenuItem(
                            value: ThemeMode.dark, child: Text('ليلي')),
                      ],
                      onChanged: (mode) {
                        if (mode != null) {
                          ref
                              .read(settingsProvider.notifier)
                              .setThemeMode(mode);
                        }
                      },
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                  ),
                  ListTile(
                    leading: const Icon(Icons.translate_rounded),
                    title: const Text('لغة واجهة التطبيق (RTL/LTR)'),
                    trailing: DropdownButton<String>(
                      value: settings.locale.languageCode,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(
                            value: 'ar', child: Text('العربية (RTL)')),
                        DropdownMenuItem(
                            value: 'en', child: Text('English (LTR)')),
                      ],
                      onChanged: (lang) {
                        if (lang != null) {
                          ref
                              .read(settingsProvider.notifier)
                              .setLocale(Locale(lang));
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Section 2: iOS Extensions & Widgets
            _buildSectionHeader('ملحقات iOS والويدجت (Extensions)'),
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : AppTheme.lightSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                ),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.keyboard_rounded),
                    title: const Text('لوحة مفاتيح الترجمة (VAVAKeyboard)'),
                    subtitle: const Text('خطوات التفعيل في إعدادات iOS'),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    onTap: _showKeyboardGuide,
                  ),
                  Divider(
                    height: 1,
                    color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                  ),
                  ListTile(
                    leading: const Icon(Icons.widgets_rounded),
                    title: const Text('مزامنة ويدجت الشاشة (WidgetKit)'),
                    subtitle: const Text('App Group: group.com.vava.translator'),
                    trailing: const Icon(Icons.check_circle_rounded,
                        color: AppTheme.accentColor, size: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Section 3: Offline Language Packs Manager
            _buildSectionHeader(
                'مدير حزم اللغات بدون إنترنت (Offline Models)'),
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : AppTheme.lightSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                ),
              ),
              child: _isLoadingPacks
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: kSupportedLanguages.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color:
                            isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                        indent: 56,
                      ),
                      itemBuilder: (context, index) {
                        final lang = kSupportedLanguages[index];
                        final isDownloaded =
                            _downloadedModels[lang.code] ?? false;
                        final isBusy = _downloadingCodes.contains(lang.code);

                        return ListTile(
                          leading: Text(
                            lang.flag,
                            style: const TextStyle(fontSize: 26),
                          ),
                          title: Text(
                            '${lang.nativeName} (${lang.name})',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(
                            isDownloaded ? 'مثبت محلياً (~35 MB)' : 'غير مثبت',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDownloaded
                                  ? AppTheme.accentColor
                                  : (isDark ? Colors.white38 : Colors.black38),
                            ),
                          ),
                          trailing: isBusy
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                )
                              : IconButton(
                                  onPressed: () => _toggleDownload(lang),
                                  icon: Icon(
                                    isDownloaded
                                        ? Icons.delete_outline_rounded
                                        : Icons.download_rounded,
                                    color: isDownloaded
                                        ? AppTheme.dangerColor
                                        : AppTheme.primaryColor,
                                  ),
                                  tooltip: isDownloaded
                                      ? 'حذف الحزمة'
                                      : 'تنزيل الحزمة',
                                ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, right: 4, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }
}

class _KeyboardGuideSheet extends StatelessWidget {
  const _KeyboardGuideSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final steps = const [
      'افتح إعدادات الآيفون (Settings).',
      'انتقل إلى: عام (General) > لوحة المفاتيح (Keyboard).',
      'اضغط على: لوحات المفاتيح (Keyboards) > إضافة لوحة مفاتيح جديدة...',
      'اختر "VAVA Translator" من قائمة لوحات المفاتيح الخارجية.',
      'اضغط على VAVA Translator وقم بتفعيل "السماح بالوصول الكامل" (Allow Full Access).',
      'الآن في أي تطبيق دردشة أو ملاحظات، اضغط مطولاً على أيقونة الكرة الأرضية 🌐 للترجمة الفورية!',
    ];

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'تفعيل لوحة مفاتيح VAVA',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: steps.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, idx) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${idx + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        steps[idx],
                        style: const TextStyle(fontSize: 14, height: 1.4),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
