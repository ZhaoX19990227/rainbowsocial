import 'package:flutter/material.dart';

class FlirtyAction {
  const FlirtyAction({
    required this.id,
    required this.label,
    required this.preview,
    required this.icon,
    required this.gradient,
    required this.hint,
    required this.stageTitle,
    required this.stageSubtitle,
    required this.motionNotes,
    required this.hapticNotes,
  });

  final String id;
  final String label;
  final String preview;
  final IconData icon;
  final List<Color> gradient;
  final String hint;
  final String stageTitle;
  final String stageSubtitle;
  final String motionNotes;
  final String hapticNotes;

  static const all = <FlirtyAction>[
    FlirtyAction(
      id: 'poke_butt',
      label: '坏坏戳一下',
      preview: '指尖坏坏点了点你一下',
      icon: Icons.back_hand_rounded,
      gradient: [Color(0xFFD56A55), Color(0xFF6F2131)],
      hint: '带点坏心思的试探，后劲却很可爱',
      stageTitle: '指尖偷袭',
      stageSubtitle: '一下点中，立刻弹开，留下一个明显的坏笑。',
      motionNotes: '120ms 蓄力，180ms 轻戳，320ms 夸张弹跳回弹。',
      hapticNotes: '触发瞬间一次 medium impact，回弹时一次轻量 tick。',
    ),
    FlirtyAction(
      id: 'tug_sleeve',
      label: '拽住衣角',
      preview: '悄悄勾住了你的袖口',
      icon: Icons.waving_hand_rounded,
      gradient: [Color(0xFFBC7A49), Color(0xFF5C2E2E)],
      hint: '像在说别走，又像故意撒了个娇',
      stageTitle: '袖口试探',
      stageSubtitle: '轻轻一拽，把距离感也一起拽短一点。',
      motionNotes: '160ms 探手，140ms 小幅回拉，360ms 羞怯后仰。',
      hapticNotes: '拉动时一次 selection click。',
    ),
    FlirtyAction(
      id: 'pat_head',
      label: '摸摸你的头',
      preview: '掌心轻轻落在你的发顶',
      icon: Icons.pan_tool_alt_rounded,
      gradient: [Color(0xFF5B78D8), Color(0xFF78519B)],
      hint: '温柔到像安抚，又故意多停了一秒',
      stageTitle: '掌心安抚',
      stageSubtitle: '动作不急，像是故意让气氛慢慢变热。',
      motionNotes: '200ms 落手，240ms 轻拍，450ms 柔软停留与眯眼回应。',
      hapticNotes: '落手时一次 soft impact。',
    ),
    FlirtyAction(
      id: 'hook_finger',
      label: '勾住手指',
      preview: '小指轻轻勾住了你',
      icon: Icons.gesture_rounded,
      gradient: [Color(0xFFB68A49), Color(0xFF6C3A33)],
      hint: '先勾住手指，再勾走注意力',
      stageTitle: '小指邀请',
      stageSubtitle: '不是握手，是更私密一点点的确认。',
      motionNotes: '220ms 靠近，180ms 勾住，520ms 保持轻晃和眼神停留。',
      hapticNotes: '勾住时一次 selection click，停留末尾一次 soft impact。',
    ),
    FlirtyAction(
      id: 'lean_closer',
      label: '忽然靠近',
      preview: '突然朝你靠近了一点',
      icon: Icons.zoom_in_map_rounded,
      gradient: [Color(0xFF7F4E68), Color(0xFF35213A)],
      hint: '没有碰到，却已经让心跳提前一步',
      stageTitle: '距离失守',
      stageSubtitle: '往前半步，眼神却比身体更先抵达。',
      motionNotes: '180ms 前倾，260ms 近距离停顿，280ms 呼吸感悬停。',
      hapticNotes: '靠近峰值时一次 medium impact。',
    ),
    FlirtyAction(
      id: 'sneak_glance',
      label: '偏头偷看',
      preview: '侧过脸偷偷看了你一眼',
      icon: Icons.visibility_rounded,
      gradient: [Color(0xFF5E71B2), Color(0xFF26335E)],
      hint: '装作不在意，但眼神已经先泄密了',
      stageTitle: '偷看暴露',
      stageSubtitle: '余光先过去，表情后补救，可爱得很明显。',
      motionNotes: '140ms 偏头，220ms 余光停留，260ms 慌张收回。',
      hapticNotes: '眼神对上时一次 light tick。',
    ),
    FlirtyAction(
      id: 'brush_shoulder',
      label: '轻蹭肩膀',
      preview: '肩侧若有若无地擦过你',
      icon: Icons.airline_seat_recline_extra_rounded,
      gradient: [Color(0xFF457A9A), Color(0xFF243D61)],
      hint: '像路过时不小心，却又明显不是不小心',
      stageTitle: '肩线擦过',
      stageSubtitle: '暧昧不是撞上去，是故意慢半拍地擦过去。',
      motionNotes: '180ms 贴近，220ms 擦肩，320ms 回头确认反应。',
      hapticNotes: '接触时一次 very light impact。',
    ),
    FlirtyAction(
      id: 'naughty_smile',
      label: '给你坏笑',
      preview: '嘴角一挑，冲你坏笑了一下',
      icon: Icons.mood_rounded,
      gradient: [Color(0xFFCA6A4F), Color(0xFF7D2742)],
      hint: '明明只是笑一下，却像把节奏全拿走了',
      stageTitle: '笑意挑衅',
      stageSubtitle: '表情收得很克制，杀伤力反而更足。',
      motionNotes: '160ms 抬眼，280ms 单侧嘴角上扬，360ms 慢速眨眼收尾。',
      hapticNotes: '表情定格时一次 selection click。',
    ),
  ];

  static FlirtyAction byId(String id) {
    return all.firstWhere(
      (item) => item.id == id,
      orElse: () => all.first,
    );
  }
}
