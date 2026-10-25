import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/languages.dart';
import '../../core/services/database_service.dart';
import '../../core/services/speech_service.dart';
import '../../core/theme/app_theme.dart';
import '../../models/translation_history_item.dart';
import '../../models/lesson_progress.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String _selectedCategory = 'text'; // 'text', 'talk', 'lesson'
  bool _favoritesOnly = false;
  List<TranslationHistoryItem> _items = [];
  List<LessonProgress> _lessons = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);

    if (_selectedCategory == 'lesson') {
      final lessons = await DatabaseService.instance.getAllLessons();
      setState(() {
        _lessons = lessons;
        _isLoading = false;
      });
    } else {
      final list = await DatabaseService.instance.getAllHistory(
        category: _selectedCategory,
        favoritesOnly: _favoritesOnly,
      );
      setState(() {
        _items = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteItem(TranslationHistoryItem item) async {
    if (item.id != null) {
      await DatabaseService.instance.deleteHistory(item.id!);
      _loadHistory();
    }
  }

  Future<void> _toggleFavorite(TranslationHistoryItem item) async {
    if (item.id != null) {
      await DatabaseService.instance
          .toggleHistoryFavorite(item.id!, item.isFavorite);
      _loadHistory();
    }
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('مسح السجل'),
        content: Text(_selectedCategory == 'lesson'
            ? 'هل تريد إعادة ضبط تقدم الدروس؟'
            : 'هل أنت متأكد من مسح جميع عناصر هذا القسم؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.dangerColor),
            child: const Text('مسح الآن'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (_selectedCategory != 'lesson') {
        await DatabaseService.instance.clearHistory(category: _selectedCategory);
      }
      _loadHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('السجل والمفضلة'),
        actions: [
          if (_selectedCategory != 'lesson')
            IconButton(
              onPressed: () {
                setState(() => _favoritesOnly = !_favoritesOnly);
                _loadHistory();
              },
              icon: Icon(
                _favoritesOnly ? Icons.star_rounded : Icons.star_border_rounded,
                color: _favoritesOnly ? Colors.amber : null,
              ),
              tooltip: 'المفضلة فقط',
            ),
          IconButton(
            onPressed: _clearAll,
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'مسح الكل',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 3-Way Segmented Selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkCard : AppTheme.lightBorder.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    _buildSegmentButton('text', 'النصوص (Text)', isDark),
                    _buildSegmentButton('talk', 'المحادثة (Talk)', isDark),
                    _buildSegmentButton('lesson', 'الدروس (Lessons)', isDark),
                  ],
                ),
              ),
            ),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _selectedCategory == 'lesson'
                      ? _buildLessonsList(isDark)
                      : _buildHistoryList(isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentButton(String id, String title, bool isDark) {
    final isSelected = _selectedCategory == id;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_selectedCategory != id) {
            setState(() => _selectedCategory = id);
            _loadHistory();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AppTheme.primaryLight : AppTheme.primaryColor)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white60 : Colors.black54),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryList(bool isDark) {
    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _favoritesOnly ? Icons.star_border_rounded : Icons.history_rounded,
              size: 54,
              color: isDark ? Colors.white24 : Colors.black26,
            ),
            const SizedBox(height: 12),
            Text(
              _favoritesOnly
                  ? 'لا توجد عناصر في المفضلة بعد'
                  : 'السجل فارغ حالياً',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = _items[index];
        final srcLang = getAppLanguageByCode(item.sourceLang);
        final tgtLang = getAppLanguageByCode(item.targetLang);

        return Dismissible(
          key: ValueKey(item.id ?? index),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 20),
            decoration: BoxDecoration(
              color: AppTheme.dangerColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
          ),
          onDismissed: (_) => _deleteItem(item),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCard : AppTheme.lightSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text('${srcLang.flag} ${srcLang.code.toUpperCase()}'),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(Icons.arrow_forward_rounded, size: 14),
                        ),
                        Text('${tgtLang.flag} ${tgtLang.code.toUpperCase()}'),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            SpeechService.instance.speak(
                              text: item.translatedText,
                              langCode: item.targetLang,
                            );
                          },
                          icon: const Icon(Icons.volume_up_rounded, size: 20),
                          tooltip: 'استماع',
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: item.translatedText));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('تم النسخ إلى الحافظة'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy_rounded, size: 18),
                          tooltip: 'نسخ',
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => _toggleFavorite(item),
                          icon: Icon(
                            item.isFavorite
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: item.isFavorite ? Colors.amber : null,
                            size: 20,
                          ),
                          tooltip: 'تفضيل',
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  item.sourceText,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 6),
                Text(
                  item.translatedText,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLessonsList(bool isDark) {
    if (_lessons.isEmpty) {
      return const Center(child: Text('لا توجد دروس حالياً'));
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _lessons.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final lesson = _lessons[index];
        final progress = lesson.totalSteps > 0
            ? (lesson.completedSteps / lesson.totalSteps)
            : 0.0;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : AppTheme.lightSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    lesson.scenarioTitle,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '${lesson.score} XP',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.accentColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: isDark ? Colors.white12 : Colors.black12,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    lesson.isCompleted ? AppTheme.accentColor : AppTheme.primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                lesson.isCompleted
                    ? 'اكتملت جميع المراحل بنجاح'
                    : 'التقدم: ${lesson.completedSteps} من ${lesson.totalSteps} مراحل',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
