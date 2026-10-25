class LessonProgress {
  final String id;
  final String scenarioTitle;
  final int completedSteps;
  final int totalSteps;
  final int score;
  final bool isCompleted;

  const LessonProgress({
    required this.id,
    required this.scenarioTitle,
    required this.completedSteps,
    required this.totalSteps,
    required this.score,
    required this.isCompleted,
  });

  LessonProgress copyWith({
    String? id,
    String? scenarioTitle,
    int? completedSteps,
    int? totalSteps,
    int? score,
    bool? isCompleted,
  }) {
    return LessonProgress(
      id: id ?? this.id,
      scenarioTitle: scenarioTitle ?? this.scenarioTitle,
      completedSteps: completedSteps ?? this.completedSteps,
      totalSteps: totalSteps ?? this.totalSteps,
      score: score ?? this.score,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'scenarioTitle': scenarioTitle,
      'completedSteps': completedSteps,
      'totalSteps': totalSteps,
      'score': score,
      'isCompleted': isCompleted ? 1 : 0,
    };
  }

  factory LessonProgress.fromMap(Map<String, dynamic> map) {
    return LessonProgress(
      id: map['id'] as String? ?? '',
      scenarioTitle: map['scenarioTitle'] as String? ?? '',
      completedSteps: map['completedSteps'] as int? ?? 0,
      totalSteps: map['totalSteps'] as int? ?? 0,
      score: map['score'] as int? ?? 0,
      isCompleted: (map['isCompleted'] as int? ?? 0) == 1,
    );
  }
}
