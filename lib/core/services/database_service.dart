import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../../models/translation_history_item.dart';
import '../../models/phrase_item.dart';
import '../../models/lesson_progress.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();
  DatabaseService._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'vava_translator.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            sourceText TEXT NOT NULL,
            translatedText TEXT NOT NULL,
            sourceLang TEXT NOT NULL,
            targetLang TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            category TEXT NOT NULL,
            isFavorite INTEGER NOT NULL DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE phrases (
            id TEXT PRIMARY KEY,
            category TEXT NOT NULL,
            sourceText TEXT NOT NULL,
            translatedText TEXT NOT NULL,
            sourceLang TEXT NOT NULL,
            targetLang TEXT NOT NULL,
            isFavorite INTEGER NOT NULL DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE lessons (
            id TEXT PRIMARY KEY,
            scenarioTitle TEXT NOT NULL,
            completedSteps INTEGER NOT NULL DEFAULT 0,
            totalSteps INTEGER NOT NULL,
            score INTEGER NOT NULL DEFAULT 0,
            isCompleted INTEGER NOT NULL DEFAULT 0
          )
        ''');

        await _seedInitialData(db);
      },
    );
  }

  Future<void> _seedInitialData(Database db) async {
    final List<PhraseItem> defaultPhrases = [
      // Casual
      const PhraseItem(
        id: 'c1',
        category: 'casual',
        sourceText: 'How are you doing today?',
        translatedText: 'كيف حالك اليوم؟',
        sourceLang: 'en',
        targetLang: 'ar',
      ),
      const PhraseItem(
        id: 'c2',
        category: 'casual',
        sourceText: 'Nice to meet you!',
        translatedText: 'سعيد بلقائك!',
        sourceLang: 'en',
        targetLang: 'ar',
      ),
      const PhraseItem(
        id: 'c3',
        category: 'casual',
        sourceText: 'Have a great weekend!',
        translatedText: 'عطلة نهاية أسبوع رائعة!',
        sourceLang: 'en',
        targetLang: 'ar',
      ),
      // Travel
      const PhraseItem(
        id: 't1',
        category: 'travel',
        sourceText: 'Where is the nearest train station?',
        translatedText: 'أين أقرب محطة قطار؟',
        sourceLang: 'en',
        targetLang: 'ar',
      ),
      const PhraseItem(
        id: 't2',
        category: 'travel',
        sourceText: 'Could I have the check, please?',
        translatedText: 'هل يمكنني الحصول على الفاتورة من فضلك؟',
        sourceLang: 'en',
        targetLang: 'ar',
      ),
      const PhraseItem(
        id: 't3',
        category: 'travel',
        sourceText: 'How much does this ticket cost?',
        translatedText: 'كم ثمن هذه التذكرة؟',
        sourceLang: 'en',
        targetLang: 'ar',
      ),
      // Academic
      const PhraseItem(
        id: 'a1',
        category: 'academic',
        sourceText: 'The empirical evidence supports the hypothesis.',
        translatedText: 'الأدلة التجريبية تدعم الفرضية.',
        sourceLang: 'en',
        targetLang: 'ar',
      ),
      const PhraseItem(
        id: 'a2',
        category: 'academic',
        sourceText: 'Please refer to the bibliography on page twelve.',
        translatedText: 'يرجى مراجعة قائمة المراجع في الصفحة الثانية عشرة.',
        sourceLang: 'en',
        targetLang: 'ar',
      ),
      const PhraseItem(
        id: 'a3',
        category: 'academic',
        sourceText: 'In conclusion, further research is required.',
        translatedText: 'ختاماً، هناك حاجة إلى مزيد من البحث.',
        sourceLang: 'en',
        targetLang: 'ar',
      ),
    ];

    for (final phrase in defaultPhrases) {
      await db.insert('phrases', phrase.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }

    final List<LessonProgress> defaultLessons = [
      const LessonProgress(
        id: 'lesson_airport',
        scenarioTitle: 'Airport & Customs Check',
        completedSteps: 1,
        totalSteps: 4,
        score: 25,
        isCompleted: false,
      ),
      const LessonProgress(
        id: 'lesson_cafe',
        scenarioTitle: 'Ordering at a Paris Café',
        completedSteps: 0,
        totalSteps: 3,
        score: 0,
        isCompleted: false,
      ),
      const LessonProgress(
        id: 'lesson_hotel',
        scenarioTitle: 'Hotel Check-in & Inquiries',
        completedSteps: 0,
        totalSteps: 4,
        score: 0,
        isCompleted: false,
      ),
      const LessonProgress(
        id: 'lesson_business',
        scenarioTitle: 'Business Meeting Greetings',
        completedSteps: 0,
        totalSteps: 5,
        score: 0,
        isCompleted: false,
      ),
    ];

    for (final lesson in defaultLessons) {
      await db.insert('lessons', lesson.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  // --- HISTORY CRUD ---

  Future<int> insertHistory(TranslationHistoryItem item) async {
    final db = await database;
    return await db.insert('history', item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<TranslationHistoryItem>> getAllHistory({
    String? category,
    bool? favoritesOnly,
  }) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (category != null && category.isNotEmpty) {
      whereClause += 'category = ?';
      whereArgs.add(category);
    }

    if (favoritesOnly == true) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'isFavorite = 1';
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'history',
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'timestamp DESC',
    );

    return maps.map((m) => TranslationHistoryItem.fromMap(m)).toList();
  }

  Future<int> toggleHistoryFavorite(int id, bool currentStatus) async {
    final db = await database;
    return await db.update(
      'history',
      {'isFavorite': currentStatus ? 0 : 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteHistory(int id) async {
    final db = await database;
    return await db.delete('history', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> clearHistory({String? category}) async {
    final db = await database;
    if (category != null && category.isNotEmpty) {
      return await db.delete('history',
          where: 'category = ?', whereArgs: [category]);
    }
    return await db.delete('history');
  }

  // --- PHRASES CRUD ---

  Future<List<PhraseItem>> getPhrases({String? category, bool? favoritesOnly}) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (category != null && category.isNotEmpty && category != 'all') {
      whereClause += 'category = ?';
      whereArgs.add(category);
    }

    if (favoritesOnly == true) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'isFavorite = 1';
    }

    final maps = await db.query(
      'phrases',
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
    );

    return maps.map((m) => PhraseItem.fromMap(m)).toList();
  }

  Future<int> togglePhraseFavorite(String id, bool currentStatus) async {
    final db = await database;
    return await db.update(
      'phrases',
      {'isFavorite': currentStatus ? 0 : 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- LESSONS CRUD ---

  Future<List<LessonProgress>> getAllLessons() async {
    final db = await database;
    final maps = await db.query('lessons', orderBy: 'id ASC');
    return maps.map((m) => LessonProgress.fromMap(m)).toList();
  }

  Future<int> updateLessonProgress(LessonProgress lesson) async {
    final db = await database;
    return await db.update(
      'lessons',
      lesson.toMap(),
      where: 'id = ?',
      whereArgs: [lesson.id],
    );
  }
}

