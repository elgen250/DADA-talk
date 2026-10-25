import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/languages.dart';
import '../../core/services/database_service.dart';
import '../../core/services/speech_service.dart';
import '../../core/services/translation_service.dart';
import '../../core/services/widget_sync_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/language_selector_sheet.dart';
import '../../models/translation_history_item.dart';

class TextTranslateScreen extends ConsumerStatefulWidget {
  const TextTranslateScreen({super.key});

  @override
  ConsumerState<TextTranslateScreen> createState() =>
      _TextTranslateScreenState();
}

class _TextTranslateScreenState extends ConsumerState<TextTranslateScreen> {
  final TextEditingController _inputController = TextEditingController();
  AppLanguage _sourceLang = kSupportedLanguages[1]; // English
  AppLanguage _targetLang = kSupportedLanguages[0]; // Arabic

  String _translatedText = '';
  bool _isLoading = false;
  bool _isAutoDetect = true;
  bool _isFavorited = false;
  bool _isRecording = false;

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _handleTranslate(String text) async {
    final query = text.trim();
    if (query.isEmpty) {
      setState(() {
        _translatedText = '';
        _isFavorited = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      String effectiveSource = _sourceLang.code;
      if (_isAutoDetect) {
        final detected =
            await TranslationService.instance.identifyLanguage(query);
        final detectedLang = getAppLanguageByCode(detected);
        if (detectedLang.code != _sourceLang.code) {
          setState(() => _sourceLang = detectedLang);
        }
        effectiveSource = detectedLang.code;
      }

      final result = await TranslationService.instance.translate(
        text: query,
        sourceCode: effectiveSource,
        targetCode: _targetLang.code,
      );

      setState(() {
        _translatedText = result;
        _isLoading = false;
        _isFavorited = false;
      });

      // Save to SQLite
      await DatabaseService.instance.insertHistory(
        TranslationHistoryItem(
          sourceText: query,
          translatedText: result,
          sourceLang: effectiveSource,
          targetLang: _targetLang.code,
          timestamp: DateTime.now(),
          category: 'text',
        ),
      );

      // Sync with WidgetKit & Keyboard Extension
      await WidgetSyncService.instance.syncLatestTranslation(
        sourceText: query,
        translatedText: result,
        sourceLang: effectiveSource,
        targetLang: _targetLang.code,
      );
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _swapLanguages() {
    setState(() {
      final temp = _sourceLang;
      _sourceLang = _targetLang;
      _targetLang = temp;
      _isAutoDetect = false;

      if (_translatedText.isNotEmpty) {
        _inputController.text = _translatedText;
        _handleTranslate(_translatedText);
      }
    });
  }

  Future<void> _toggleMic() async {
    if (_isRecording) {
      await SpeechService.instance.stopListening();
      setState(() => _isRecording = false);
    } else {
      setState(() => _isRecording = true);
      await SpeechService.instance.startListening(
        langCode: _sourceLang.code,
        onResult: (text, isFinal) {
          _inputController.text = text;
          if (isFinal) {
            setState(() => _isRecording = false);
            _handleTranslate(text);
          }
        },
      );
    }
  }

  Future<void> _toggleFavorite() async {
    if (_translatedText.isEmpty) return;
    setState(() => _isFavorited = !_isFavorited);

    // Save as favorite in DB
    await DatabaseService.instance.insertHistory(
      TranslationHistoryItem(
        sourceText: _inputController.text.trim(),
        translatedText: _translatedText,
        sourceLang: _sourceLang.code,
        targetLang: _targetLang.code,
        timestamp: DateTime.now(),
        category: 'text',
        isFavorite: _isFavorited,
      ),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isFavorited
              ? '⭐ تمت الإضافة إلى المفضلة'
              : 'تمت الإزالة من المفضلة'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.offline_pin_rounded,
                      size: 14, color: AppTheme.accentColor),
                  SizedBox(width: 4),
                  Text(
                    '100% On-Device Engine',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.accentColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              // Language Switcher Bar
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkCard : AppTheme.lightSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                  ),
                ),
                child: Row(
                  children: [
                    // Source Lang
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final selected = await LanguageSelectorSheet.show(
                            context,
                            current: _sourceLang,
                            title: 'اختر لغة الإدخال',
                          );
                          if (selected != null) {
                            setState(() {
                              _sourceLang = selected;
                              _isAutoDetect = false;
                            });
                            if (_inputController.text.isNotEmpty) {
                              _handleTranslate(_inputController.text);
                            }
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 8),
                          child: Row(
                            children: [
                              Text(_sourceLang.flag,
                                  style: const TextStyle(fontSize: 22)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _isAutoDetect
                                          ? 'تلقائي (${_sourceLang.name})'
                                          : _sourceLang.nativeName,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      _sourceLang.code.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark
                                            ? Colors.white54
                                            : Colors.black45,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Swap Button
                    IconButton(
                      onPressed: _swapLanguages,
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.swap_horiz_rounded,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                      ),
                    ),

                    // Target Lang
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final selected = await LanguageSelectorSheet.show(
                            context,
                            current: _targetLang,
                            title: 'اختر لغة الترجمة',
                          );
                          if (selected != null) {
                            setState(() => _targetLang = selected);
                            if (_inputController.text.isNotEmpty) {
                              _handleTranslate(_inputController.text);
                            }
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 8),
                          child: Row(
                            children: [
                              Text(_targetLang.flag,
                                  style: const TextStyle(fontSize: 22)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _targetLang.nativeName,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      _targetLang.code.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark
                                            ? Colors.white54
                                            : Colors.black45,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Source Input Card
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkCard : AppTheme.lightSurface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _inputController,
                      maxLines: 4,
                      minLines: 3,
                      textDirection: _sourceLang.isRTL
                          ? TextDirection.rtl
                          : TextDirection.ltr,
                      decoration: InputDecoration(
                        hintText: 'اكتب أو الصق النص هنا...',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        fillColor: Colors.transparent,
                        contentPadding: EdgeInsets.zero,
                        hintStyle: TextStyle(
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                      onChanged: (text) => _handleTranslate(text),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Left tools: Clear & Paste
                        Row(
                          children: [
                            if (_inputController.text.isNotEmpty)
                              IconButton(
                                onPressed: () {
                                  _inputController.clear();
                                  _handleTranslate('');
                                },
                                icon: const Icon(Icons.clear_rounded, size: 20),
                                tooltip: 'مسح',
                              ),
                            IconButton(
                              onPressed: () async {
                                final data =
                                    await Clipboard.getData('text/plain');
                                if (data?.text != null &&
                                    data!.text!.isNotEmpty) {
                                  _inputController.text = data.text!;
                                  _handleTranslate(data.text!);
                                }
                              },
                              icon: const Icon(Icons.paste_rounded, size: 20),
                              tooltip: 'لصق',
                            ),
                            if (_inputController.text.isNotEmpty)
                              IconButton(
                                onPressed: () {
                                  SpeechService.instance.speak(
                                    text: _inputController.text,
                                    langCode: _sourceLang.code,
                                  );
                                },
                                icon: const Icon(Icons.volume_up_rounded,
                                    size: 20),
                                tooltip: 'استماع',
                              ),
                          ],
                        ),

                        // Voice input button
                        InkWell(
                          onTap: _toggleMic,
                          borderRadius: BorderRadius.circular(20),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: _isRecording
                                  ? AppTheme.dangerColor
                                  : AppTheme.primaryColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _isRecording
                                      ? Icons.stop_rounded
                                      : Icons.mic_rounded,
                                  size: 18,
                                  color: _isRecording
                                      ? Colors.white
                                      : AppTheme.primaryColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _isRecording ? 'جارٍ الاستماع...' : 'تحدث',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: _isRecording
                                        ? Colors.white
                                        : AppTheme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Translated Output Card
              if (_isLoading)
                Container(
                  height: 140,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkCard : AppTheme.lightSurface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color:
                          isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                    ),
                  ),
                  child: const CircularProgressIndicator(),
                )
              else if (_translatedText.isNotEmpty)
                Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.darkCard
                        : AppTheme.primaryColor.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Text(_targetLang.flag,
                              style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 6),
                          Text(
                            _targetLang.nativeName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SelectableText(
                        _translatedText,
                        textDirection: _targetLang.isRTL
                            ? TextDirection.rtl
                            : TextDirection.ltr,
                        style: TextStyle(
                          fontSize: 18,
                          height: 1.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            onPressed: () {
                              SpeechService.instance.speak(
                                text: _translatedText,
                                langCode: _targetLang.code,
                              );
                            },
                            icon: const Icon(Icons.volume_up_rounded, size: 22),
                            tooltip: 'نطق',
                          ),
                          IconButton(
                            onPressed: () {
                              Clipboard.setData(
                                  ClipboardData(text: _translatedText));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('تم نسخ الترجمة'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                            icon: const Icon(Icons.copy_rounded, size: 20),
                            tooltip: 'نسخ',
                          ),
                          IconButton(
                            onPressed: _toggleFavorite,
                            icon: Icon(
                              _isFavorited
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              color: _isFavorited ? Colors.amber : null,
                              size: 22,
                            ),
                            tooltip: 'تفضيل',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
