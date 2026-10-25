class TranslationHistoryItem {
  final int? id;
  final String sourceText;
  final String translatedText;
  final String sourceLang;
  final String targetLang;
  final DateTime timestamp;
  final String category; // 'text', 'talk', 'lesson'
  final bool isFavorite;

  const TranslationHistoryItem({
    this.id,
    required this.sourceText,
    required this.translatedText,
    required this.sourceLang,
    required this.targetLang,
    required this.timestamp,
    required this.category,
    this.isFavorite = false,
  });

  TranslationHistoryItem copyWith({
    int? id,
    String? sourceText,
    String? translatedText,
    String? sourceLang,
    String? targetLang,
    DateTime? timestamp,
    String? category,
    bool? isFavorite,
  }) {
    return TranslationHistoryItem(
      id: id ?? this.id,
      sourceText: sourceText ?? this.sourceText,
      translatedText: translatedText ?? this.translatedText,
      sourceLang: sourceLang ?? this.sourceLang,
      targetLang: targetLang ?? this.targetLang,
      timestamp: timestamp ?? this.timestamp,
      category: category ?? this.category,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sourceText': sourceText,
      'translatedText': translatedText,
      'sourceLang': sourceLang,
      'targetLang': targetLang,
      'timestamp': timestamp.toIso8601String(),
      'category': category,
      'isFavorite': isFavorite ? 1 : 0,
    };
  }

  factory TranslationHistoryItem.fromMap(Map<String, dynamic> map) {
    return TranslationHistoryItem(
      id: map['id'] as int?,
      sourceText: map['sourceText'] as String? ?? '',
      translatedText: map['translatedText'] as String? ?? '',
      sourceLang: map['sourceLang'] as String? ?? 'en',
      targetLang: map['targetLang'] as String? ?? 'ar',
      timestamp: DateTime.tryParse(map['timestamp'] as String? ?? '') ??
          DateTime.now(),
      category: map['category'] as String? ?? 'text',
      isFavorite: (map['isFavorite'] as int? ?? 0) == 1,
    );
  }
}
