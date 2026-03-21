class HoroscopeScores {
  const HoroscopeScores({
    required this.romance,
    required this.initiative,
    required this.luck,
  });

  final int romance;
  final int initiative;
  final int luck;
}

class HoroscopeData {
  const HoroscopeData({
    required this.date,
    required this.zodiacSign,
    required this.title,
    required this.summary,
    required this.love,
    required this.social,
    required this.mood,
    required this.suggestion,
    required this.avoid,
    required this.scores,
    required this.tags,
  });

  final DateTime date;
  final String zodiacSign;
  final String title;
  final String summary;
  final String love;
  final String social;
  final String mood;
  final String suggestion;
  final String avoid;
  final HoroscopeScores scores;
  final List<String> tags;
}
