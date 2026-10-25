import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/languages.dart';
import '../../core/services/database_service.dart';
import '../../core/services/speech_service.dart';
import '../../core/services/translation_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/language_selector_sheet.dart';
import '../../models/translation_history_item.dart';

class LiveTalkMessage {
  final String speaker; // 'speaker1' or 'speaker2'
  final String originalText;
  final String translatedText;
  final String sourceLang;
  final String targetLang;
  final DateTime time;

  const LiveTalkMessage({
    required this.speaker,
    required this.originalText,
    required this.translatedText,
    required this.sourceLang,
    required this.targetLang,
    required this.time,
  });
}

class LiveTalkScreen extends ConsumerStatefulWidget {
  const LiveTalkScreen({super.key});

  @override
  ConsumerState<LiveTalkScreen> createState() => _LiveTalkScreenState();
}

class _LiveTalkScreenState extends ConsumerState<LiveTalkScreen> {
  AppLanguage _speaker1Lang = kSupportedLanguages[1]; // English
  AppLanguage _speaker2Lang = kSupportedLanguages[0]; // Arabic

  bool _isSpeaker1Recording = false;
  bool _isSpeaker2Recording = false;
  bool _isFaceToFaceMode = false;

  final List<LiveTalkMessage> _conversation = [];
  final ScrollController _scrollController = ScrollController();

  Future<void> _startRecording({required bool isSpeaker1}) async {
    final activeLang = isSpeaker1 ? _speaker1Lang : _speaker2Lang;
    final targetLang = isSpeaker1 ? _speaker2Lang : _speaker1Lang;

    setState(() {
      if (isSpeaker1) {
        _isSpeaker1Recording = true;
        _isSpeaker2Recording = false;
      } else {
        _isSpeaker2Recording = true;
        _isSpeaker1Recording = false;
      }
    });

    await SpeechService.instance.startListening(
      langCode: activeLang.code,
      onResult: (text, isFinal) async {
        if (isFinal && text.trim().isNotEmpty) {
          setState(() {
            _isSpeaker1Recording = false;
            _isSpeaker2Recording = false;
          });

          // Translate
          final translated = await TranslationService.instance.translate(
            text: text,
            sourceCode: activeLang.code,
            targetCode: targetLang.code,
          );

          final msg = LiveTalkMessage(
            speaker: isSpeaker1 ? 'speaker1' : 'speaker2',
            originalText: text,
            translatedText: translated,
            sourceLang: activeLang.code,
            targetLang: targetLang.code,
            time: DateTime.now(),
          );

          setState(() {
            _conversation.add(msg);
          });

          // Auto TTS playback
          SpeechService.instance.speak(
            text: translated,
            langCode: targetLang.code,
          );

          // Save to SQLite
          await DatabaseService.instance.insertHistory(
            TranslationHistoryItem(
              sourceText: text,
              translatedText: translated,
              sourceLang: activeLang.code,
              targetLang: targetLang.code,
              timestamp: DateTime.now(),
              category: 'talk',
            ),
          );

          // Scroll to bottom
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent + 120,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        }
      },
    );
  }

  Future<void> _stopRecording() async {
    await SpeechService.instance.stopListening();
    setState(() {
      _isSpeaker1Recording = false;
      _isSpeaker2Recording = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('المحادثة الحية المباشرة'),
        actions: [
          IconButton(
            onPressed: () {
              setState(() => _isFaceToFaceMode = !_isFaceToFaceMode);
            },
            icon: Icon(
              _isFaceToFaceMode
                  ? Icons.screen_rotation_rounded
                  : Icons.stay_current_portrait_rounded,
              color: _isFaceToFaceMode ? AppTheme.accentColor : null,
            ),
            tooltip: 'وضع وجهاً لوجه (Face to Face)',
          ),
          IconButton(
            onPressed: () {
              setState(() => _conversation.clear());
            },
            icon: const Icon(Icons.delete_sweep_rounded),
            tooltip: 'مسح المحادثة',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Speaker 1 Zone (Top)
            Expanded(
              flex: 1,
              child: Transform.rotate(
                angle: _isFaceToFaceMode ? math.pi : 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.darkCard.withValues(alpha: 0.6)
                        : AppTheme.primaryColor.withValues(alpha: 0.05),
                    border: Border(
                      bottom: BorderSide(
                        color:
                            isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Lang Selector
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          InkWell(
                            onTap: () async {
                              final sel = await LanguageSelectorSheet.show(
                                context,
                                current: _speaker1Lang,
                                title: 'لغة المتحدث الأول',
                              );
                              if (sel != null) {
                                setState(() => _speaker1Lang = sel);
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppTheme.darkSurface
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark
                                      ? AppTheme.darkBorder
                                      : AppTheme.lightBorder,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Text(_speaker1Lang.flag,
                                      style: const TextStyle(fontSize: 18)),
                                  const SizedBox(width: 6),
                                  Text(
                                    _speaker1Lang.nativeName,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const Icon(Icons.arrow_drop_down, size: 18),
                                ],
                              ),
                            ),
                          ),
                          Text(
                            'المتحدث 1',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white54 : Colors.black45,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),

                      // Last message preview for speaker 1
                      _buildLastSpeakerPreview(
                        speakerId: 'speaker1',
                        isDark: isDark,
                      ),
                      const Spacer(),

                      // Speaker 1 Mic Button
                      GestureDetector(
                        onTapDown: (_) =>
                            _startRecording(isSpeaker1: true),
                        onTapUp: (_) => _stopRecording(),
                        onTapCancel: () => _stopRecording(),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: _isSpeaker1Recording ? 82 : 70,
                          height: _isSpeaker1Recording ? 82 : 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isSpeaker1Recording
                                ? AppTheme.dangerColor
                                : AppTheme.primaryColor,
                            boxShadow: [
                              BoxShadow(
                                color: (_isSpeaker1Recording
                                        ? AppTheme.dangerColor
                                        : AppTheme.primaryColor)
                                    .withValues(alpha: 0.4),
                                blurRadius: _isSpeaker1Recording ? 20 : 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            _isSpeaker1Recording
                                ? Icons.mic_rounded
                                : Icons.mic_none_rounded,
                            size: 34,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _isSpeaker1Recording
                            ? 'اترك الزر للترجمة والنطق'
                            : 'المس مع الاستمرار للتحدث',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Speaker 2 Zone (Bottom)
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkBg : AppTheme.lightBg,
                ),
                child: Column(
                  children: [
                    // Speaker 2 Mic Button
                    GestureDetector(
                      onTapDown: (_) =>
                          _startRecording(isSpeaker1: false),
                      onTapUp: (_) => _stopRecording(),
                      onTapCancel: () => _stopRecording(),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: _isSpeaker2Recording ? 82 : 70,
                        height: _isSpeaker2Recording ? 82 : 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isSpeaker2Recording
                              ? AppTheme.dangerColor
                              : AppTheme.accentColor,
                          boxShadow: [
                            BoxShadow(
                              color: (_isSpeaker2Recording
                                      ? AppTheme.dangerColor
                                      : AppTheme.accentColor)
                                  .withValues(alpha: 0.4),
                              blurRadius: _isSpeaker2Recording ? 20 : 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          _isSpeaker2Recording
                              ? Icons.mic_rounded
                              : Icons.mic_none_rounded,
                          size: 34,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isSpeaker2Recording
                          ? 'اترك الزر للترجمة والنطق'
                          : 'المس مع الاستمرار للتحدث',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                    const Spacer(),

                    // Last message preview for speaker 2
                    _buildLastSpeakerPreview(
                      speakerId: 'speaker2',
                      isDark: isDark,
                    ),
                    const Spacer(),

                    // Lang Selector
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          onTap: () async {
                            final sel = await LanguageSelectorSheet.show(
                              context,
                              current: _speaker2Lang,
                              title: 'لغة المتحدث الثاني',
                            );
                            if (sel != null) {
                              setState(() => _speaker2Lang = sel);
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppTheme.darkSurface
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark
                                    ? AppTheme.darkBorder
                                    : AppTheme.lightBorder,
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(_speaker2Lang.flag,
                                    style: const TextStyle(fontSize: 18)),
                                const SizedBox(width: 6),
                                Text(
                                  _speaker2Lang.nativeName,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const Icon(Icons.arrow_drop_down, size: 18),
                              ],
                            ),
                          ),
                        ),
                        Text(
                          'المتحدث 2',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLastSpeakerPreview({
    required String speakerId,
    required bool isDark,
  }) {
    final matches = _conversation.where((m) => m.speaker == speakerId).toList();
    if (matches.isEmpty) {
      return Text(
        'جاهز للاستماع...',
        style: TextStyle(
          fontSize: 13,
          fontStyle: FontStyle.italic,
          color: isDark ? Colors.white30 : Colors.black26,
        ),
      );
    }

    final latest = matches.last;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          latest.originalText,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white60 : Colors.black54,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          latest.translatedText,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.primaryColor,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
