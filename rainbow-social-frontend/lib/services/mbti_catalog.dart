import 'package:flutter/material.dart';

enum MbtiDimension { ei, sn, tf, jp }

class MbtiQuestionOption {
  const MbtiQuestionOption({
    required this.label,
    required this.letter,
  });

  final String label;
  final String letter;
}

class MbtiQuestion {
  const MbtiQuestion({
    required this.id,
    required this.prompt,
    required this.dimension,
    required this.left,
    required this.right,
  });

  final String id;
  final String prompt;
  final MbtiDimension dimension;
  final MbtiQuestionOption left;
  final MbtiQuestionOption right;
}

class MbtiProfile {
  const MbtiProfile({
    required this.type,
    required this.name,
    required this.oneLiner,
    required this.summary,
    required this.keywords,
    required this.palette,
    required this.avatarAccent,
  });

  final String type;
  final String name;
  final String oneLiner;
  final String summary;
  final List<String> keywords;
  final List<Color> palette;
  final IconData avatarAccent;
}

class MbtiCatalog {
  static const validTypes = {
    'INTJ',
    'INTP',
    'ENTJ',
    'ENTP',
    'INFJ',
    'INFP',
    'ENFJ',
    'ENFP',
    'ISTJ',
    'ISFJ',
    'ESTJ',
    'ESFJ',
    'ISTP',
    'ISFP',
    'ESTP',
    'ESFP',
  };

  static const questions = <MbtiQuestion>[
    MbtiQuestion(
      id: 'q1',
      prompt: '你更倾向怎样恢复能量？',
      dimension: MbtiDimension.ei,
      left: MbtiQuestionOption(label: '独处充电，慢慢回血', letter: 'I'),
      right: MbtiQuestionOption(label: '和人互动，越聊越有劲', letter: 'E'),
    ),
    MbtiQuestion(
      id: 'q2',
      prompt: '初次见面时你通常会？',
      dimension: MbtiDimension.ei,
      left: MbtiQuestionOption(label: '先观察气氛，再慢慢打开', letter: 'I'),
      right: MbtiQuestionOption(label: '主动开启话题，不怕冷场', letter: 'E'),
    ),
    MbtiQuestion(
      id: 'q3',
      prompt: '周末临时被叫出去，你会？',
      dimension: MbtiDimension.ei,
      left: MbtiQuestionOption(label: '更想保留自己的节奏', letter: 'I'),
      right: MbtiQuestionOption(label: '说走就走，先玩再说', letter: 'E'),
    ),
    MbtiQuestion(
      id: 'q4',
      prompt: '你更容易被哪种人吸引？',
      dimension: MbtiDimension.sn,
      left: MbtiQuestionOption(label: '脚踏实地，让人安心', letter: 'S'),
      right: MbtiQuestionOption(label: '有想法有脑洞，很有故事感', letter: 'N'),
    ),
    MbtiQuestion(
      id: 'q5',
      prompt: '聊天时你更常聊什么？',
      dimension: MbtiDimension.sn,
      left: MbtiQuestionOption(label: '正在发生的事和真实细节', letter: 'S'),
      right: MbtiQuestionOption(label: '未来可能、灵感和联想', letter: 'N'),
    ),
    MbtiQuestion(
      id: 'q6',
      prompt: '做选择时你更依赖？',
      dimension: MbtiDimension.sn,
      left: MbtiQuestionOption(label: '已验证过的经验', letter: 'S'),
      right: MbtiQuestionOption(label: '直觉和整体感觉', letter: 'N'),
    ),
    MbtiQuestion(
      id: 'q7',
      prompt: '朋友来找你倾诉时，你更像？',
      dimension: MbtiDimension.tf,
      left: MbtiQuestionOption(label: '先共情，陪他消化情绪', letter: 'F'),
      right: MbtiQuestionOption(label: '先分析，帮他理清问题', letter: 'T'),
    ),
    MbtiQuestion(
      id: 'q8',
      prompt: '发生分歧时你更在意？',
      dimension: MbtiDimension.tf,
      left: MbtiQuestionOption(label: '关系别受伤，感受最重要', letter: 'F'),
      right: MbtiQuestionOption(label: '事情讲清楚，逻辑要站得住', letter: 'T'),
    ),
    MbtiQuestion(
      id: 'q9',
      prompt: '夸一个人时你更常说？',
      dimension: MbtiDimension.tf,
      left: MbtiQuestionOption(label: '你很温柔，很会照顾人', letter: 'F'),
      right: MbtiQuestionOption(label: '你很聪明，处理事情很稳', letter: 'T'),
    ),
    MbtiQuestion(
      id: 'q10',
      prompt: '旅行前你的状态更像？',
      dimension: MbtiDimension.jp,
      left: MbtiQuestionOption(label: '先把行程安排清楚才安心', letter: 'J'),
      right: MbtiQuestionOption(label: '大概有个方向，现场再看', letter: 'P'),
    ),
    MbtiQuestion(
      id: 'q11',
      prompt: '面对突发变化时你更常？',
      dimension: MbtiDimension.jp,
      left: MbtiQuestionOption(label: '马上调整计划，重新掌控', letter: 'J'),
      right: MbtiQuestionOption(label: '随机应变，说不定更有趣', letter: 'P'),
    ),
    MbtiQuestion(
      id: 'q12',
      prompt: '你喜欢的感情节奏是？',
      dimension: MbtiDimension.jp,
      left: MbtiQuestionOption(label: '稳定推进，关系有清晰方向', letter: 'J'),
      right: MbtiQuestionOption(label: '自然发展，留点惊喜和空间', letter: 'P'),
    ),
  ];

  static final Map<String, MbtiProfile> profiles = {
    'INFP': const MbtiProfile(
      type: 'INFP',
      name: '调停者',
      oneLiner: '理想与温柔并存，越了解越让人上头。',
      summary: '你通常敏感、真诚、有共情力，喜欢有灵魂感和想象力的连接。',
      keywords: ['理想主义', '情绪细腻', '富有想象力'],
      palette: [Color(0xFFB47BFF), Color(0xFFFFA7C4)],
      avatarAccent: Icons.auto_awesome_rounded,
    ),
    'INFJ': const MbtiProfile(
      type: 'INFJ',
      name: '提倡者',
      oneLiner: '温柔克制，但洞察力很强。',
      summary: '你重视深层关系，能快速读懂气氛与情绪，也希望连接足够真诚。',
      keywords: ['深度连接', '高敏感', '洞察人心'],
      palette: [Color(0xFF8E5BFF), Color(0xFF7DDCFF)],
      avatarAccent: Icons.visibility_rounded,
    ),
    'INTJ': const MbtiProfile(
      type: 'INTJ',
      name: '建筑师',
      oneLiner: '冷静有主见，喜欢高质量匹配。',
      summary: '你偏理性和独立，对关系有自己的标准，更容易被聪明稳定的人吸引。',
      keywords: ['战略型', '标准高', '思维清晰'],
      palette: [Color(0xFF6F7BF7), Color(0xFFB47BFF)],
      avatarAccent: Icons.psychology_alt_rounded,
    ),
    'INTP': const MbtiProfile(
      type: 'INTP',
      name: '逻辑学家',
      oneLiner: '脑内宇宙很大，喜欢有趣的灵魂。',
      summary: '你好奇、独立、反应快，关系里比起套路，更在意智性交流和新鲜感。',
      keywords: ['脑洞大', '理性自由', '有趣第一'],
      palette: [Color(0xFF7DDCFF), Color(0xFF91A7FF)],
      avatarAccent: Icons.lightbulb_rounded,
    ),
    'ENFP': const MbtiProfile(
      type: 'ENFP',
      name: '竞选者',
      oneLiner: '热情会传染，靠近你很难无聊。',
      summary: '你自带感染力，喜欢探索人与关系的可能性，也很会给气氛加温。',
      keywords: ['感染力强', '浪漫脑洞', '社交发电机'],
      palette: [Color(0xFFFFA7C4), Color(0xFFFFC27A)],
      avatarAccent: Icons.celebration_rounded,
    ),
    'ENFJ': const MbtiProfile(
      type: 'ENFJ',
      name: '主人公',
      oneLiner: '很会爱人，也希望被认真回应。',
      summary: '你擅长建立关系和照顾情绪，往往在互动里自带温度和推动力。',
      keywords: ['热情主动', '关系推动者', '照顾型'],
      palette: [Color(0xFFFFA7C4), Color(0xFFB47BFF)],
      avatarAccent: Icons.favorite_rounded,
    ),
    'ENTP': const MbtiProfile(
      type: 'ENTP',
      name: '辩论家',
      oneLiner: '会撩会聊，脑子和嘴都很快。',
      summary: '你享受刺激和交锋，喜欢聪明好玩的人，关系里最怕无聊。',
      keywords: ['会聊会撩', '反应快', '新鲜感驱动'],
      palette: [Color(0xFFFFC27A), Color(0xFF7DDCFF)],
      avatarAccent: Icons.flash_on_rounded,
    ),
    'ENTJ': const MbtiProfile(
      type: 'ENTJ',
      name: '指挥官',
      oneLiner: '强势又有魅力，喜欢高效双向奔赴。',
      summary: '你目标感强，欣赏同样有想法、有行动力的人，不喜欢模糊关系。',
      keywords: ['掌控感', '执行力强', '偏爱明确'],
      palette: [Color(0xFF8E5BFF), Color(0xFFFFC27A)],
      avatarAccent: Icons.workspace_premium_rounded,
    ),
    'ISFP': const MbtiProfile(
      type: 'ISFP',
      name: '探险家',
      oneLiner: '松弛感和细腻感同时在线。',
      summary: '你温和有美感，表达不一定很多，但会通过细节和行动释放好感。',
      keywords: ['审美在线', '慢热温柔', '细节表达'],
      palette: [Color(0xFFFFA7C4), Color(0xFF7DDCFF)],
      avatarAccent: Icons.palette_rounded,
    ),
    'ISTP': const MbtiProfile(
      type: 'ISTP',
      name: '鉴赏家',
      oneLiner: '不爱废话，但行动很有吸引力。',
      summary: '你独立、冷静、很看重真实体验，关系里会用行动而不是大段表达来靠近。',
      keywords: ['行动派', '松弛冷感', '真实直接'],
      palette: [Color(0xFF91A7FF), Color(0xFF7DDCFF)],
      avatarAccent: Icons.build_circle_rounded,
    ),
    'ESFP': const MbtiProfile(
      type: 'ESFP',
      name: '表演者',
      oneLiner: '有你在，现场感一下就起来了。',
      summary: '你享受互动和当下体验，擅长制造快乐，也很容易让人快速放松。',
      keywords: ['现场感', '会来电', '情绪感染力'],
      palette: [Color(0xFFFFC27A), Color(0xFFFFA7C4)],
      avatarAccent: Icons.music_note_rounded,
    ),
    'ESTP': const MbtiProfile(
      type: 'ESTP',
      name: '企业家',
      oneLiner: '直接、会玩、很有荷尔蒙感。',
      summary: '你喜欢强互动和即刻反馈，能快速点燃气氛，也偏爱爽快真实的人。',
      keywords: ['高能量', '敢推进', '擅长破冰'],
      palette: [Color(0xFFFFC27A), Color(0xFF91A7FF)],
      avatarAccent: Icons.sports_martial_arts_rounded,
    ),
    'ISFJ': const MbtiProfile(
      type: 'ISFJ',
      name: '守卫者',
      oneLiner: '温柔可靠，是相处后会越来越上头的类型。',
      summary: '你细腻、稳定、顾及他人感受，关系里擅长给人安全感和持久的温度。',
      keywords: ['稳定感', '照顾型', '慢热耐看'],
      palette: [Color(0xFF7DDCFF), Color(0xFFFFD7B8)],
      avatarAccent: Icons.shield_moon_rounded,
    ),
    'ISTJ': const MbtiProfile(
      type: 'ISTJ',
      name: '物流师',
      oneLiner: '靠谱感很强，越认真越有魅力。',
      summary: '你重视原则、稳定和长期可靠，适合认真经营关系，不爱玩虚的。',
      keywords: ['靠谱', '原则感', '稳定输出'],
      palette: [Color(0xFF91A7FF), Color(0xFFE6D8FF)],
      avatarAccent: Icons.inventory_2_rounded,
    ),
    'ESFJ': const MbtiProfile(
      type: 'ESFJ',
      name: '执政官',
      oneLiner: '很会照顾氛围，也很会让人觉得被在意。',
      summary: '你在人际关系里非常有温度，乐于主动表达和经营双向互动。',
      keywords: ['很会照顾人', '关系感强', '氛围高手'],
      palette: [Color(0xFFFFD7B8), Color(0xFFFFA7C4)],
      avatarAccent: Icons.groups_rounded,
    ),
    'ESTJ': const MbtiProfile(
      type: 'ESTJ',
      name: '总经理',
      oneLiner: '清晰、可靠、有主心骨。',
      summary: '你喜欢高效明确的互动，不太爱猜来猜去，也更偏爱成熟稳定的关系节奏。',
      keywords: ['明确直接', '行动稳定', '执行力'],
      palette: [Color(0xFF8E5BFF), Color(0xFFFFD7B8)],
      avatarAccent: Icons.badge_rounded,
    ),
  };

  static MbtiProfile resolve(String type) {
    return profiles[type] ?? profiles['INFP']!;
  }

  static String calculateType(Map<String, String> answers) {
    final counts = <MbtiDimension, Map<String, int>>{
      MbtiDimension.ei: {'E': 0, 'I': 0},
      MbtiDimension.sn: {'S': 0, 'N': 0},
      MbtiDimension.tf: {'T': 0, 'F': 0},
      MbtiDimension.jp: {'J': 0, 'P': 0},
    };

    for (final question in questions) {
      final answer = answers[question.id];
      if (answer == null) continue;
      counts[question.dimension]![answer] =
          (counts[question.dimension]![answer] ?? 0) + 1;
    }

    final first = _pick(counts[MbtiDimension.ei]!, primary: 'E', fallback: 'I');
    final second = _pick(counts[MbtiDimension.sn]!, primary: 'N', fallback: 'S');
    final third = _pick(counts[MbtiDimension.tf]!, primary: 'F', fallback: 'T');
    final fourth = _pick(counts[MbtiDimension.jp]!, primary: 'P', fallback: 'J');
    return '$first$second$third$fourth';
  }

  static String _pick(
    Map<String, int> score, {
    required String primary,
    required String fallback,
  }) {
    final primaryScore = score[primary] ?? 0;
    final fallbackScore = score[fallback] ?? 0;
    return primaryScore >= fallbackScore ? primary : fallback;
  }
}
