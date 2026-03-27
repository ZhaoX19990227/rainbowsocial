import 'package:flutter/material.dart';

import '../models/flirty_action.dart';
import '../widgets/flirty_action_system.dart';
import '../widgets/luminous_background.dart';

class FlirtyActionDesignPage extends StatelessWidget {
  const FlirtyActionDesignPage({super.key});

  @override
  Widget build(BuildContext context) {
    final teaseAction = FlirtyAction.byId('poke_butt');
    final cardAction = FlirtyAction.byId('hook_finger');
    final replayAction = FlirtyAction.byId('lean_closer');

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Lune 互动设计稿'),
      ),
      body: LuminousBackground(
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _ShowcaseHero(),
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 980;
                    final cards = [
                      _PhoneMockup(
                        title: '动作选择面板',
                        subtitle: '聊天输入框上方半屏弹出，四类动作卡片按紫色主调和蓝光高亮分组。',
                        child: Stack(
                          children: const [
                            _MockChatChrome(showInput: true),
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: Padding(
                                padding: EdgeInsets.all(14),
                                child: FlirtyActionPickerSheet(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _PhoneMockup(
                        title: '聊天动作卡片',
                        subtitle: '卡片尺寸适配聊天气泡，保留封面插画、动作名和一句预览文案。',
                        child: _MockChatCardScene(action: cardAction),
                      ),
                      _PhoneMockup(
                        title: '全屏回放',
                        subtitle: '舞台感来自柔和发光、玻璃层次和轻颗粒，不走厚重黑幕路线。',
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            const _MockReplayBackdrop(),
                            FlirtyActionOverlay(
                              data: FlirtyReplayData(
                                instanceKey: 'design-preview',
                                action: replayAction,
                                preview: replayAction.preview,
                                isMine: false,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ];

                    if (!wide) {
                      return Column(
                        children: [
                          for (final card in cards) ...[
                            card,
                            const SizedBox(height: 18),
                          ],
                        ],
                      );
                    }

                    return Wrap(
                      spacing: 18,
                      runSpacing: 18,
                      children: cards
                          .map(
                            (card) => SizedBox(
                              width: (constraints.maxWidth - 36) / 3,
                              child: card,
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
                const SizedBox(height: 28),
                _ActionSystemSummary(action: teaseAction),
                const SizedBox(height: 22),
                Text(
                  '6 个核心动作分镜',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: const Color(0xFF2B214D),
                        fontSize: 28,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  '每张卡都把封面帧、预览关键帧、完整版关键帧、姿态重心、视线方向、回弹方式、Rive 骨骼建议和可拆分特效层一起整理好了。',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF665C89),
                        height: 1.5,
                      ),
                ),
                const SizedBox(height: 16),
                for (final action in FlirtyAction.all) ...[
                  _StoryboardCard(action: action),
                  const SizedBox(height: 14),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShowcaseHero extends StatelessWidget {
  const _ShowcaseHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xF7FBF7FF),
            Color(0xFFF2F8FF),
            Color(0xFFF8F2FF),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.78)),
        boxShadow: [
          BoxShadow(
            color: const Color(0x339B63FF),
            blurRadius: 28,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: const LinearGradient(
                colors: [Color(0xFFAF73FF), Color(0xFF8FD4FF)],
              ),
            ),
            child: Text(
              'Bear x Monkey Flirt Motion',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Colors.white,
                    letterSpacing: 0.24,
                  ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '月光氛围里的 Lune 互动',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: const Color(0xFF2B214D),
                  fontSize: 34,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            '基于现有聊天功能落地了动作面板、消息卡片和全屏回放，同时把 6 个核心动作的镜头节奏、表情系统、Rive 骨骼和特效拆层整理成一套可直接交付给动画同学的规范。',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF5F5585),
                  height: 1.55,
                ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const [
              _HeroChip(label: '明亮清爽'),
              _HeroChip(label: '紫色主调 + 蓝色高光'),
              _HeroChip(label: 'Q 版圆润'),
              _HeroChip(label: 'flirt / playful / intimate / warm'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withValues(alpha: 0.72),
        border: Border.all(color: const Color(0x26A27CFF)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: const Color(0xFF544A78),
              letterSpacing: 0.16,
            ),
      ),
    );
  }
}

class _PhoneMockup extends StatelessWidget {
  const _PhoneMockup({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: const Color(0xFF2B214D),
              ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF6B618D),
                height: 1.45,
              ),
        ),
        const SizedBox(height: 12),
        AspectRatio(
          aspectRatio: 390 / 844,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(38),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2F2A47), Color(0xFF161327)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 30,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Container(
                color: const Color(0xFFF6F3FF),
                child: child,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MockChatChrome extends StatelessWidget {
  const _MockChatChrome({required this.showInput});

  final bool showInput;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF8F6FF), Color(0xFFEFF5FF)],
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.72),
              border: Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.8)),
              ),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: Color(0xFFB689FF),
                  child: Icon(Icons.pets_rounded, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '猴仔',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: const Color(0xFF352A57),
                          ),
                    ),
                    Text(
                      '在线',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: const Color(0xFF7E739D),
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _MiniBubble(
                      text: '刚刚在想你会不会先靠近。',
                      mine: false,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: _MiniBubble(
                      text: '那你先偷看，我再抓包。',
                      mine: true,
                    ),
                  ),
                  const Spacer(),
                  if (showInput)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [Color(0xFFA66CFF), Color(0xFF8DD5FF)],
                              ),
                            ),
                            child: const Icon(
                              Icons.auto_awesome_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '输入消息...',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: const Color(0xFF8C82A8),
                                ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniBubble extends StatelessWidget {
  const _MiniBubble({
    required this.text,
    required this.mine,
  });

  final String text;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: mine
            ? const LinearGradient(
                colors: [Color(0xFFB17AFF), Color(0xFFA7B9FF)],
              )
            : null,
        color: mine ? null : Colors.white.withValues(alpha: 0.82),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: mine ? Colors.white : const Color(0xFF4E446E),
              height: 1.45,
            ),
      ),
    );
  }
}

class _MockChatCardScene extends StatelessWidget {
  const _MockChatCardScene({required this.action});

  final FlirtyAction action;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const _MockChatChrome(showInput: true),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 120, 16, 120),
          child: Align(
            alignment: Alignment.centerRight,
            child: FlirtyActionMessageCard(
              messagePreview: action.preview,
              action: action,
              isMine: true,
            ),
          ),
        ),
      ],
    );
  }
}

class _MockReplayBackdrop extends StatelessWidget {
  const _MockReplayBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF8F5FF), Color(0xFFE8F4FF)],
        ),
      ),
      child: Stack(
        children: const [
          Positioned(
            top: -30,
            left: -10,
            child: _BackdropGlow(color: Color(0x669B63FF), size: 200),
          ),
          Positioned(
            top: 180,
            right: -20,
            child: _BackdropGlow(color: Color(0x557CCBFF), size: 220),
          ),
          Positioned(
            bottom: -60,
            left: 60,
            child: _BackdropGlow(color: Color(0x40FFA8D4), size: 220),
          ),
        ],
      ),
    );
  }
}

class _BackdropGlow extends StatelessWidget {
  const _BackdropGlow({
    required this.color,
    required this.size,
  });

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 90,
            spreadRadius: 20,
          ),
        ],
      ),
    );
  }
}

class _ActionSystemSummary extends StatelessWidget {
  const _ActionSystemSummary({required this.action});

  final FlirtyAction action;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: Colors.white.withValues(alpha: 0.64),
        border: Border.all(color: Colors.white.withValues(alpha: 0.82)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '角色基调',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: const Color(0xFF2B214D),
                ),
          ),
          const SizedBox(height: 10),
          Text(
            '小熊更厚实、更稳、更温柔，主色偏暖紫棕；小猴更灵动、更俏皮、更敏捷，主色偏浅棕紫灰。两者统一为头大身小、四肢短圆的 Q 版比例，表情系统保留日常、微笑、害羞、坏笑、心动五种状态。',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF665C89),
                  height: 1.55,
                ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _SpecChip(label: '小熊: 厚实 / 温柔 / 暖紫棕'),
              _SpecChip(label: '小猴: 灵动 / 害羞 / 浅棕紫灰'),
              _SpecChip(label: '主视觉: 紫色主调 + 蓝色高光 + 少量粉点缀'),
              _SpecChip(label: '参考动作: ${action.label}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StoryboardCard extends StatelessWidget {
  const _StoryboardCard({required this.action});

  final FlirtyAction action;

  @override
  Widget build(BuildContext context) {
    final storyboard = action.storyboard;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.9),
            action.gradient.first.withValues(alpha: 0.08),
            action.gradient.last.withValues(alpha: 0.08),
          ],
        ),
        border: Border.all(
          color: action.gradient.first.withValues(alpha: 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: action.gradient.first.withValues(alpha: 0.08),
            blurRadius: 18,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: LinearGradient(colors: action.gradient),
                ),
                child: Text(
                  action.label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  action.stageTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: const Color(0xFF2B214D),
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            storyboard.coverFrame,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF675D88),
                  height: 1.5,
                ),
          ),
          const SizedBox(height: 14),
          _TimelineSection(
            title: '封面帧',
            duration: storyboard.previewDuration,
            lines: [storyboard.coverFrame],
          ),
          const SizedBox(height: 12),
          _TimelineSection(
            title: '预览动画关键帧',
            duration: storyboard.previewDuration,
            beats: storyboard.previewBeats,
          ),
          const SizedBox(height: 12),
          _TimelineSection(
            title: '完整版关键帧',
            duration: storyboard.fullDuration,
            beats: storyboard.fullBeats,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _SpecTile(title: '姿势与重心', body: storyboard.poseNotes),
              _SpecTile(title: '表情变化', body: storyboard.expressionNotes),
              _SpecTile(title: '视线方向', body: storyboard.gazeNotes),
              _SpecTile(title: '受力点', body: storyboard.forceNotes),
              _SpecTile(title: '回弹方式', body: storyboard.reboundNotes),
              _SpecTile(
                title: 'Rive 骨骼建议',
                body:
                    '${storyboard.rigSuggestion.bones.join('；')}。\n控制器: ${storyboard.rigSuggestion.controllers.join('、')}。\n${storyboard.rigSuggestion.notes}',
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '可拆分特效层',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF302652),
                ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: storyboard.effectLayers
                .map((layer) => _SpecChip(label: layer))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _TimelineSection extends StatelessWidget {
  const _TimelineSection({
    required this.title,
    required this.duration,
    this.lines = const [],
    this.beats = const [],
  });

  final String title;
  final String duration;
  final List<String> lines;
  final List<FlirtyBeat> beats;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0x66FFFFFF),
        border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF302652),
                      ),
                ),
              ),
              Text(
                duration,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: const Color(0xFF7E739E),
                    ),
              ),
            ],
          ),
          if (lines.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final line in lines)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  line,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF665C89),
                        height: 1.5,
                      ),
                ),
              ),
          ],
          if (beats.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final beat in beats)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 88,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: const Color(0xFFEDE8FF),
                      ),
                      child: Text(
                        beat.timing,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: const Color(0xFF5D4E86),
                              letterSpacing: 0.1,
                            ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            beat.title,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: const Color(0xFF2F2650),
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            beat.description,
                            style:
                                Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: const Color(0xFF665C89),
                                      height: 1.45,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _SpecTile extends StatelessWidget {
  const _SpecTile({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.white.withValues(alpha: 0.74),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF2F2650),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF665C89),
                    height: 1.5,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpecChip extends StatelessWidget {
  const _SpecChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withValues(alpha: 0.8),
        border: Border.all(color: const Color(0x1A9B63FF)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: const Color(0xFF5D4E86),
              letterSpacing: 0.1,
            ),
      ),
    );
  }
}
