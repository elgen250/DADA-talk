class PhraseItem {
  final String id;
  final String category; // 'casual', 'travel', 'academic'
  final String sourceText;
  final String translatedText;
  final String sourceLang;
  final String targetLang;
  final bool isFavorite;

  const PhraseItem({
    required this.id,
    required this.category,
    required this.sourceText,
    required this.translatedText,
    required this.sourceLang,
    required this.targetLang,
    this.isFavorite = false,
  });

  PhraseItem copyWith({
    String? id,
    String? category,
    String? sourceText,
    String? translatedText,
    String? sourceLang,
    String? targetLang,
    bool? isFavorite,
  }) {
    return PhraseItem(
      id: id ?? this.id,
      category: category ?? this.category,
      sourceText: sourceText ?? this.sourceText,
      translatedText: translatedText ?? this.translatedText,
      sourceLang: sourceLang ?? this.sourceLang,
      targetLang: targetLang ?? this.targetLang,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'sourceText': sourceText,
      'translatedText': translatedText,
      'sourceLang': sourceLang,
      'targetLang': targetLang,
      'isFavorite': isFavorite ? 1 : 0,
    };
  }

  factory PhraseItem.fromMap(Map<String, dynamic> map) {
    return PhraseItem(
      id: map['id'] as String? ?? '',
      category: map['category'] as String? ?? 'casual',
      sourceText: map['sourceText'] as String? ?? '',
      translatedText: map['translatedText'] as String? ?? '',
      sourceLang: map['sourceLang'] as String? ?? 'en',
      targetLang: map['targetLang'] as String? ?? 'ar',
      isFavorite: (map['isFavorite'] as int? ?? 0) == 1,
    );
  }
}
