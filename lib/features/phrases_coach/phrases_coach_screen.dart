import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/database_service.dart';
import '../../core/services/speech_service.dart';
import '../../core/theme/app_theme.dart';
import '../../models/phrase_item.dart';
import '../../models/lesson_progress.dart';

class PhrasesCoachScreen extends ConsumerStatefulWidget {
  const PhrasesCoachScreen({super.key});

  @override
  ConsumerState<PhrasesCoachScreen> createState() => _PhrasesCoachScreenState();
}

class _PhrasesCoachScreenState extends ConsumerState<PhrasesCoachScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'all';

  List<PhraseItem> _phrases = [];
  List<LessonProgress> _lessons = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final phrases = await DatabaseService.instance.getPhrases(
      category: _selectedCategory == 'all' ? null : _selectedCategory,
    );
    final lessons = await DatabaseService.instance.getAllLessons();
    setState(() {
      _phrases = phrases;
      _lessons = lessons;
      _isLoading = false;
    });
  }

  Future<void> _togglePhraseFav(PhraseItem item) async {
    await DatabaseService.instance
        .togglePhraseFavorite(item.id, item.isFavorite);
    _loadData();
  }

  void _openCoachScenario(LessonProgress lesson) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CoachScenarioSheet(
        lesson: lesson,
        onCompleted: () => _loadData(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('العبارات والمدرب الذكي'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryColor,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          tabs: const [
            Tab(text: 'مكتبة العبارات', icon: Icon(Icons.menu_book_rounded)),
            Tab(text: 'المدرب James', icon: Icon(Icons.school_rounded)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Phrases Library
          _buildPhrasesTab(isDark),

          // Tab 2: Coach James
          _buildCoachTab(isDark),
        ],
      ),
    );
  }

  Widget _buildPhrasesTab(bool isDark) {
    return Column(
      children: [
        // Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              _buildCategoryChip('all', 'الكل (All)', isDark),
              const SizedBox(width: 8),
              _buildCategoryChip('casual', 'يومية (Casual)', isDark),
              const SizedBox(width: 8),
              _buildCategoryChip('travel', 'سفر (Travel)', isDark),
              const SizedBox(width: 8),
              _buildCategoryChip('academic', 'أكاديمية (Academic)', isDark),
            ],
          ),
        ),

        // Phrases List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _phrases.isEmpty
                  ? const Center(child: Text('لا توجد عبارات في هذا القسم'))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      itemCount: _phrases.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = _phrases[index];
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppTheme.darkCard
                                : AppTheme.lightSurface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark
                                  ? AppTheme.darkBorder
                                  : AppTheme.lightBorder,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      item.category.toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        onPressed: () {
                                          SpeechService.instance.speak(
                                            text: item.sourceText,
                                            langCode: item.sourceLang,
                                          );
                                        },
                                        icon: const Icon(
                                            Icons.volume_up_rounded,
                                            size: 20),
                                        tooltip: 'استماع',
                                      ),
                                      IconButton(
                                        onPressed: () => _togglePhraseFav(item),
                                        icon: Icon(
                                          item.isFavorite
                                              ? Icons.star_rounded
                                              : Icons.star_border_rounded,
                                          color: item.isFavorite
                                              ? Colors.amber
                                              : null,
                                          size: 22,
                                        ),
                                        tooltip: 'تفضيل',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item.sourceText,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item.translatedText,
                                textDirection: TextDirection.rtl,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppTheme.primaryLight
                                      : AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String id, String label, bool isDark) {
    final isSelected = _selectedCategory == id;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedCategory = id);
          _loadData();
        }
      },
      selectedColor: AppTheme.primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
      ),
    );
  }

  Widget _buildCoachTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Coach James Welcome Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E1B4B), const Color(0xFF312E81)]
                    : [const Color(0xFF4F46E5), const Color(0xFF6366F1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.face_retouching_natural_rounded,
                    size: 38,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hi, I\'m James!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'مدربك الشخصي للنطق والمحادثة التفاعلية بالذكاء الاصطناعي على جهازك مباشرة.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Scenarios Header
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'سيناريوهات التدريب التفاعلي',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Scenarios List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _lessons.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final lesson = _lessons[index];
              final progress = lesson.totalSteps > 0
                  ? (lesson.completedSteps / lesson.totalSteps)
                  : 0.0;

              return InkWell(
                onTap: () => _openCoachScenario(lesson),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkCard : AppTheme.lightSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? AppTheme.darkBorder
                          : AppTheme.lightBorder,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              lesson.scenarioTitle,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: lesson.isCompleted
                                  ? AppTheme.accentColor.withValues(alpha: 0.15)
                                  : AppTheme.primaryColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              lesson.isCompleted
                                  ? 'مكتمل ✅'
                                  : '${lesson.completedSteps}/${lesson.totalSteps} خطوات',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: lesson.isCompleted
                                    ? AppTheme.accentColor
                                    : AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor:
                              isDark ? Colors.white12 : Colors.black12,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            lesson.isCompleted
                                ? AppTheme.accentColor
                                : AppTheme.primaryColor,
                          ),
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'النقاط المكتسبة: ${lesson.score} XP',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white54 : Colors.black54,
                            ),
                          ),
                          const Row(
                            children: [
                              Text(
                                'ابدأ التدريب',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              Icon(Icons.arrow_forward_ios_rounded,
                                  size: 12, color: AppTheme.primaryColor),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CoachScenarioSheet extends StatefulWidget {
  final LessonProgress lesson;
  final VoidCallback onCompleted;

  const _CoachScenarioSheet({
    required this.lesson,
    required this.onCompleted,
  });

  @override
  State<_CoachScenarioSheet> createState() => _CoachScenarioSheetState();
}

class _CoachScenarioSheetState extends State<_CoachScenarioSheet> {
  int _currentStep = 0;
  bool _isListening = false;
  String _recognizedSpeech = '';
  String? _feedbackText;
  int _currentScore = 0;

  final List<Map<String, String>> _dialogues = const [
    {
      'coach': 'Hello! May I see your passport and boarding pass, please?',
      'coachAr': 'مرحباً! هل يمكنني رؤية جواز سفرك وبطاقة الصعود من فضلك؟',
      'userExpected': 'Here is my passport and boarding pass.',
      'userExpectedAr': 'تفضل، هذا جواز سفري وبطاقة الصعود.',
    },
    {
      'coach': 'Are you traveling for business or pleasure?',
      'coachAr': 'هل تسافر لغرض العمل أم للسياحة؟',
      'userExpected': 'I am traveling for vacation and sightseeing.',
      'userExpectedAr': 'أنا مسافر لقضاء عطلة وسياحة.',
    },
    {
      'coach': 'How long will you be staying in the country?',
      'coachAr': 'كم من الوقت ستبقى في البلاد؟',
      'userExpected': 'I will be staying for two weeks.',
      'userExpectedAr': 'سأبقى لمدة أسبوعين.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _currentScore = widget.lesson.score;
    // Play initial coach speech
    Future.delayed(const Duration(milliseconds: 300), () {
      _playCoachSpeech();
    });
  }

  void _playCoachSpeech() {
    final stepIdx = _currentStep.clamp(0, _dialogues.length - 1);
    SpeechService.instance.speak(
      text: _dialogues[stepIdx]['coach']!,
      langCode: 'en',
    );
  }

  Future<void> _recordUserPractice() async {
    if (_isListening) {
      await SpeechService.instance.stopListening();
      setState(() => _isListening = false);
    } else {
      setState(() {
        _isListening = true;
        _recognizedSpeech = '';
        _feedbackText = null;
      });

      await SpeechService.instance.startListening(
        langCode: 'en',
        onResult: (text, isFinal) {
          setState(() => _recognizedSpeech = text);
          if (isFinal) {
            setState(() => _isListening = false);
            _evaluatePronunciation(text);
          }
        },
      );
    }
  }

  void _evaluatePronunciation(String spoken) {
    final stepIdx = _currentStep.clamp(0, _dialogues.length - 1);
    final expected = _dialogues[stepIdx]['userExpected']!.toLowerCase();
    final actual = spoken.toLowerCase();

    if (actual.contains(expected.split(' ').first) || actual.length > 5) {
      setState(() {
        _feedbackText = '🎉 نطق ممتاز ودقيق جداً! +25 نقطة XP';
        _currentScore += 25;
      });
    } else {
      setState(() {
        _feedbackText = 'حاول مجدداً للوصول لنطق أقرب للمطلوب.';
      });
    }
  }

  Future<void> _nextStep() async {
    if (_currentStep < _dialogues.length - 1) {
      setState(() {
        _currentStep++;
        _recognizedSpeech = '';
        _feedbackText = null;
      });
      _playCoachSpeech();
    } else {
      // Completed lesson
      final updated = widget.lesson.copyWith(
        completedSteps: widget.lesson.totalSteps,
        isCompleted: true,
        score: _currentScore,
      );
      await DatabaseService.instance.updateLessonProgress(updated);
      widget.onCompleted();
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final stepIdx = _currentStep.clamp(0, _dialogues.length - 1);
    final dialogue = _dialogues[stepIdx];

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
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

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.lesson.scenarioTitle,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Step Progress
          Text(
            'المرحلة ${_currentStep + 1} من ${_dialogues.length}',
            style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 16),

          // Coach Message Bubble
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: AppTheme.primaryColor,
                          child: Icon(Icons.school, size: 14, color: Colors.white),
                        ),
                        SizedBox(width: 8),
                        Text('Coach James', style: TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ),
                    IconButton(
                      onPressed: _playCoachSpeech,
                      icon: const Icon(Icons.volume_up_rounded, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  dialogue['coach']!,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  dialogue['coachAr']!,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // User Target Response to Practice
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : AppTheme.lightBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'دورك للتحدث والنطق (Say this):',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.accentColor),
                ),
                const SizedBox(height: 8),
                Text(
                  dialogue['userExpected']!,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  dialogue['userExpectedAr']!,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),

          if (_recognizedSpeech.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'ما سمعته: "$_recognizedSpeech"',
              style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
            ),
          ],

          if (_feedbackText != null) ...[
            const SizedBox(height: 8),
            Text(
              _feedbackText!,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.accentColor,
              ),
            ),
          ],

          const Spacer(),

          // Mic and Next Action
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _recordUserPractice,
                  icon: Icon(_isListening ? Icons.stop : Icons.mic),
                  label: Text(_isListening ? 'جارٍ الاستماع...' : 'تحدث الآن للنطق'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isListening ? AppTheme.dangerColor : AppTheme.primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filled(
                onPressed: _nextStep,
                icon: const Icon(Icons.arrow_forward_rounded),
                tooltip: 'التالي',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
