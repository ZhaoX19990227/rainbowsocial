import 'package:flutter/material.dart';

class FlirtyAction {
  const FlirtyAction({
    required this.id,
    required this.label,
    required this.preview,
    required this.icon,
    required this.gradient,
    required this.hint,
  });

  final String id;
  final String label;
  final String preview;
  final IconData icon;
  final List<Color> gradient;
  final String hint;

  static const all = <FlirtyAction>[
    FlirtyAction(
      id: 'poke_butt',
      label: '戳了戳屁股',
      preview: '戳了戳你的屁股',
      icon: Icons.back_hand_rounded,
      gradient: [Color(0xFFE86A74), Color(0xFFA83B59)],
      hint: '带点坏心思的挑逗开场',
    ),
    FlirtyAction(
      id: 'pat_head',
      label: '摸了摸头',
      preview: '轻轻摸了摸你的头',
      icon: Icons.favorite_border_rounded,
      gradient: [Color(0xFF7A7BFF), Color(0xFFB56DFF)],
      hint: '温柔一点，也很会撩',
    ),
    FlirtyAction(
      id: 'tug_sleeve',
      label: '拽了拽衣角',
      preview: '偷偷拽了拽你的衣角',
      icon: Icons.waving_hand_rounded,
      gradient: [Color(0xFFFE9358), Color(0xFFD45A3F)],
      hint: '像在说，别走',
    ),
    FlirtyAction(
      id: 'brush_shoulder',
      label: '蹭了蹭肩',
      preview: '用肩膀轻轻蹭了蹭你',
      icon: Icons.airline_seat_recline_extra_rounded,
      gradient: [Color(0xFF31D3E7), Color(0xFF2278B8)],
      hint: '靠近一点点，再近一点',
    ),
    FlirtyAction(
      id: 'hook_finger',
      label: '勾了勾手指',
      preview: '轻轻勾了勾你的手指',
      icon: Icons.gesture_rounded,
      gradient: [Color(0xFFF3A83B), Color(0xFFDC6B32)],
      hint: '是邀请，也是试探',
    ),
    FlirtyAction(
      id: 'blow_ear',
      label: '吹了口气',
      preview: '在你耳边轻轻吹了口气',
      icon: Icons.air_rounded,
      gradient: [Color(0xFFFC7C93), Color(0xFFC3477C)],
      hint: '危险，但迷人',
    ),
    FlirtyAction(
      id: 'glance',
      label: '偷偷看你',
      preview: '偷偷看了你一眼',
      icon: Icons.visibility_rounded,
      gradient: [Color(0xFF6C8BFF), Color(0xFF3946B2)],
      hint: '不说破，但很明显',
    ),
    FlirtyAction(
      id: 'naughty_smile',
      label: '坏笑一下',
      preview: '对你露出一个坏笑',
      icon: Icons.mood_rounded,
      gradient: [Color(0xFFF2645A), Color(0xFFF0A35A)],
      hint: '很会，且知道自己很会',
    ),
  ];

  static FlirtyAction byId(String id) {
    return all.firstWhere(
      (item) => item.id == id,
      orElse: () => all.first,
    );
  }
}
