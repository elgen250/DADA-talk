import 'dart:ui';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'translation_service.dart';

class OcrTranslatedBlock {
  final String sourceText;
  final String translatedText;
  final Rect boundingBox;

  const OcrTranslatedBlock({
    required this.sourceText,
    required this.translatedText,
    required this.boundingBox,
  });
}

class OcrService {
  static final OcrService instance = OcrService._internal();
  OcrService._internal();

  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<List<OcrTranslatedBlock>> processAndTranslateImage({
    required String imagePath,
    required String sourceCode,
    required String targetCode,
  }) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);

    final List<OcrTranslatedBlock> results = [];

    for (final block in recognizedText.blocks) {
      final rawText = block.text.trim();
      if (rawText.isEmpty) continue;

      final translated = await TranslationService.instance.translate(
        text: rawText,
        sourceCode: sourceCode,
        targetCode: targetCode,
      );

      results.add(
        OcrTranslatedBlock(
          sourceText: rawText,
          translatedText: translated,
          boundingBox: block.boundingBox,
        ),
      );
    }

    return results;
  }

  void dispose() {
    _textRecognizer.close();
  }
}

