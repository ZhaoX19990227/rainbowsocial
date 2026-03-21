import '../models/horoscope_data.dart';
import 'zodiac_utils.dart';

class HoroscopeService {
  HoroscopeData buildDaily({
    required String zodiacSign,
    DateTime? date,
  }) {
    final today = DateTime(
      (date ?? DateTime.now()).year,
      (date ?? DateTime.now()).month,
      (date ?? DateTime.now()).day,
    );
    final seed = _seed(zodiacSign, today);

    final romance = 55 + seed % 40;
    final initiative = 48 + (seed ~/ 3) % 45;
    final luck = 50 + (seed ~/ 7) % 42;

    final title = switch (zodiacSign) {
      'Pisces' => '今天更适合温柔靠近，不适合太用力推进',
      'Scorpio' => '你的吸引力在线，但节奏比强度更重要',
      'Libra' => '今天的你在聊天里格外有磁场',
      'Leo' => '自信会加分，但温度比表现更动人',
      _ => '今天的你更容易被看见，也更容易被接住',
    };

    final summary =
        '${ZodiacUtils.displayName(zodiacSign)}今天的关系感知更敏锐一些。只要保持自然、清晰和松弛，你的靠近就更容易得到舒服的回应。';
    final love =
        '今天的桃花能量在上升，轻一点的试探、柔和一点的关注，比过猛的表达更容易让人心动。';
    final social =
        '你今天会更容易进入聊天状态，氛围一旦对了，关系推进会比平时自然得多。';
    final mood =
        '情绪节奏可能比平时起伏得更快一点，稳住自己的重心，反而会更有吸引力。';
    final suggestion =
        initiative >= 70 ? '如果你正在犹豫要不要主动开口，今天很适合先迈出第一步。' : '先从轻松一点的话题切入，让氛围慢慢升温会更顺。';
    final avoid =
        romance >= 80 ? '别把一时上头误判成已经确定，给关系一点呼吸空间。' : '别在情绪刚起来的时候急着要答案，节奏到了自然会明朗。';

    final tags = _tagsFor(zodiacSign, romance, initiative, luck);

    return HoroscopeData(
      date: today,
      zodiacSign: zodiacSign,
      title: title,
      summary: summary,
      love: love,
      social: social,
      mood: mood,
      suggestion: suggestion,
      avoid: avoid,
      scores: HoroscopeScores(
        romance: romance.clamp(0, 100),
        initiative: initiative.clamp(0, 100),
        luck: luck.clamp(0, 100),
      ),
      tags: tags,
    );
  }

  int _seed(String sign, DateTime date) {
    final chars = sign.codeUnits.fold<int>(0, (sum, code) => sum + code);
    return chars + date.year * 3 + date.month * 17 + date.day * 31;
  }

  List<String> _tagsFor(String sign, int romance, int initiative, int luck) {
    final result = <String>[];
    if (romance >= 75) result.add('桃花升温');
    if (initiative >= 72) result.add('适合主动');
    if (luck >= 74) result.add('时机不错');
    switch (sign) {
      case 'Pisces':
        result.add('氛围柔软');
      case 'Scorpio':
        result.add('化学反应');
      case 'Libra':
        result.add('社交发光');
      default:
        result.add('状态稳定');
    }
    while (result.length < 3) {
      result.add('情绪清晰');
    }
    return result.take(3).toList();
  }
}
