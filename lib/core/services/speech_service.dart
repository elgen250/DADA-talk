import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../constants/languages.dart';

class SpeechService {
  static final SpeechService instance = SpeechService._internal();
  SpeechService._internal();

  final stt.SpeechToText _speechToText = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();

  bool _isSttInitialized = false;
  bool _isTtsInitialized = false;

  Future<bool> initSTT() async {
    if (_isSttInitialized) return true;
    try {
      _isSttInitialized = await _speechToText.initialize(
        onError: (err) => {},
        onStatus: (status) => {},
      );
      return _isSttInitialized;
    } catch (_) {
      return false;
    }
  }

  Future<void> initTTS() async {
    if (_isTtsInitialized) return;
    try {
      await _flutterTts.awaitSynthCompletion(true);
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setPitch(1.0);
      _isTtsInitialized = true;
    } catch (_) {}
  }

  bool get isListening => _speechToText.isListening;

  Future<void> startListening({
    required String langCode,
    required Function(String recognizedWords, bool isFinal) onResult,
  }) async {
    final hasInit = await initSTT();
    if (!hasInit) return;

    final appLang = getAppLanguageByCode(langCode);

    try {
      await _speechToText.listen(
        onResult: (result) {
          onResult(result.recognizedWords, result.finalResult);
        },
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          cancelOnError: true,
          listenMode: stt.ListenMode.dictation,
          pauseFor: const Duration(seconds: 3),
          listenFor: const Duration(seconds: 30),
          localeId: appLang.bcp47,
        ),
      );
    } catch (_) {}
  }

  Future<void> stopListening() async {
    try {
      await _speechToText.stop();
    } catch (_) {}
  }

  Future<void> speak({
    required String text,
    required String langCode,
  }) async {
    if (text.trim().isEmpty) return;
    await initTTS();
    final appLang = getAppLanguageByCode(langCode);

    try {
      await _flutterTts.setLanguage(appLang.bcp47);
      await _flutterTts.speak(text);
    } catch (_) {}
  }

  Future<void> stopSpeaking() async {
    try {
      await _flutterTts.stop();
    } catch (_) {}
  }
}
