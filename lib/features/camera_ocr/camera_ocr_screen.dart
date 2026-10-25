import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/languages.dart';
import '../../core/services/database_service.dart';
import '../../core/services/ocr_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/language_selector_sheet.dart';
import '../../models/translation_history_item.dart';

class CameraOcrScreen extends ConsumerStatefulWidget {
  const CameraOcrScreen({super.key});

  @override
  ConsumerState<CameraOcrScreen> createState() => _CameraOcrScreenState();
}

class _CameraOcrScreenState extends ConsumerState<CameraOcrScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _availableCameras;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;

  AppLanguage _sourceLang = kSupportedLanguages[1]; // English
  AppLanguage _targetLang = kSupportedLanguages[0]; // Arabic

  String? _capturedImagePath;
  List<OcrTranslatedBlock> _translatedBlocks = [];

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _availableCameras = await availableCameras();
      if (_availableCameras != null && _availableCameras!.isNotEmpty) {
        _cameraController = CameraController(
          _availableCameras!.first,
          ResolutionPreset.medium,
          enableAudio: false,
        );
        await _cameraController!.initialize();
        if (mounted) {
          setState(() => _isCameraInitialized = true);
        }
      }
    } catch (_) {
      // Camera might not be available in simulator/desktop
      if (mounted) {
        setState(() => _isCameraInitialized = false);
      }
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _processImageFile(String path) async {
    setState(() {
      _capturedImagePath = path;
      _isProcessing = true;
      _translatedBlocks = [];
    });

    try {
      final blocks = await OcrService.instance.processAndTranslateImage(
        imagePath: path,
        sourceCode: _sourceLang.code,
        targetCode: _targetLang.code,
      );

      setState(() {
        _translatedBlocks = blocks;
        _isProcessing = false;
      });

      // Save complete text to history if any blocks detected
      if (blocks.isNotEmpty) {
        final fullSource = blocks.map((b) => b.sourceText).join('\n');
        final fullTarget = blocks.map((b) => b.translatedText).join('\n');

        await DatabaseService.instance.insertHistory(
          TranslationHistoryItem(
            sourceText: fullSource,
            translatedText: fullTarget,
            sourceLang: _sourceLang.code,
            targetLang: _targetLang.code,
            timestamp: DateTime.now(),
            category: 'text',
          ),
        );
      }
    } catch (_) {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _takePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      final file = await _cameraController!.takePicture();
      await _processImageFile(file.path);
    } catch (_) {}
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? file =
          await _imagePicker.pickImage(source: ImageSource.gallery);
      if (file != null) {
        await _processImageFile(file.path);
      }
    } catch (_) {}
  }

  void _resetCamera() {
    setState(() {
      _capturedImagePath = null;
      _translatedBlocks = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview or Captured Image
          if (_capturedImagePath != null)
            Positioned.fill(
              child: Image.file(
                File(_capturedImagePath!),
                fit: BoxFit.contain,
              ),
            )
          else if (_isCameraInitialized && _cameraController != null)
            Positioned.fill(
              child: CameraPreview(_cameraController!),
            )
          else
            Positioned.fill(
              child: Container(
                color: isDark ? AppTheme.darkBg : Colors.grey.shade900,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.camera_alt_outlined,
                          size: 64, color: Colors.white38),
                      const SizedBox(height: 16),
                      const Text(
                        'الكاميرا غير متوفرة في بيئة المحاكاة',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _pickFromGallery,
                        icon: const Icon(Icons.photo_library_rounded),
                        label: const Text('اختيار صورة من المعرض'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Reticle Overlay & "Hold steady" Banner (When live camera is active)
          if (_capturedImagePath == null && _isCameraInitialized)
            Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.82,
                    height: 240,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.6),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 12),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'ثبّت الكاميرا نحو النص (Hold steady)',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Processing Indicator
          if (_isProcessing)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 16),
                      Text(
                        'جارٍ قراءة وترجمة النصوص بالذكاء الاصطناعي...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Translated Output Bottom Drawer (When results exist)
          if (_capturedImagePath != null && !_isProcessing)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.45,
                ),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkCard : AppTheme.lightSurface,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black38,
                      blurRadius: 20,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'النصوص المترجمة (${_translatedBlocks.length})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        IconButton(
                          onPressed: _resetCamera,
                          icon: const Icon(Icons.refresh_rounded),
                          tooltip: 'التقاط صورة أخرى',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_translatedBlocks.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'لم يتم العثور على نصوص واضحة في الصورة.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: _translatedBlocks.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 16),
                          itemBuilder: (context, idx) {
                            final block = _translatedBlocks[idx];
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  block.sourceText,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark
                                        ? Colors.white60
                                        : Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  block.translatedText,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),

          // Top Header (Lang Selector & Controls)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Source
                  InkWell(
                    onTap: () async {
                      final sel = await LanguageSelectorSheet.show(
                        context,
                        current: _sourceLang,
                        title: 'لغة المصدر (OCR)',
                      );
                      if (sel != null) setState(() => _sourceLang = sel);
                    },
                    child: Row(
                      children: [
                        Text(_sourceLang.flag,
                            style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 6),
                        Text(
                          _sourceLang.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Icon(Icons.arrow_forward_rounded,
                      color: Colors.white70, size: 18),

                  // Target
                  InkWell(
                    onTap: () async {
                      final sel = await LanguageSelectorSheet.show(
                        context,
                        current: _targetLang,
                        title: 'لغة الترجمة (OCR)',
                      );
                      if (sel != null) setState(() => _targetLang = sel);
                    },
                    child: Row(
                      children: [
                        Text(_targetLang.flag,
                            style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 6),
                        Text(
                          _targetLang.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Shutter Controls (When camera active)
          if (_capturedImagePath == null)
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Gallery Button
                  IconButton(
                    onPressed: _pickFromGallery,
                    icon: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.photo_library_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    tooltip: 'من المعرض',
                  ),

                  // Shutter Button
                  GestureDetector(
                    onTap: _takePhoto,
                    child: Container(
                      width: 78,
                      height: 78,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        color: AppTheme.primaryColor,
                      ),
                      child: const Icon(
                        Icons.camera_rounded,
                        color: Colors.white,
                        size: 38,
                      ),
                    ),
                  ),

                  // Placeholder to balance layout
                  const SizedBox(width: 50),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
