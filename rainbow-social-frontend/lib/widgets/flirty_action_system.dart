import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/flirty_action.dart';

class FlirtyReplayData {
  const FlirtyReplayData({
    required this.instanceKey,
    required this.action,
    required this.preview,
    required this.isMine,
  });

  final String instanceKey;
  final FlirtyAction action;
  final String preview;
  final bool isMine;
}

class FlirtyActionOverlay extends StatefulWidget {
  const FlirtyActionOverlay({
    super.key,
    required this.data,
  });

  final FlirtyReplayData data;

  @override
  State<FlirtyActionOverlay> createState() => _FlirtyActionOverlayState();
}

class _FlirtyActionOverlayState extends State<FlirtyActionOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2550),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final action = widget.data.action;
    final size = MediaQuery.of(context).size;
    final stageWidth = math.min(size.width - 28, 392.0).toDouble();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final entry = Curves.easeOutCubic.transform(
          (_controller.value / 0.26).clamp(0.0, 1.0),
        );
        final exit = Curves.easeInCubic.transform(
          ((_controller.value - 0.78) / 0.22).clamp(0.0, 1.0),
        );
        final sceneProgress = Curves.easeInOutCubic.transform(
          ((_controller.value - 0.06) / 0.72).clamp(0.0, 1.0),
        );
        final opacity = (entry * (1 - exit)).clamp(0.0, 1.0);
        final lift = lerpDouble(28, -8, entry)! + exit * 18;
        final scale = lerpDouble(0.95, 1.0, entry)! - exit * 0.03;

        return IgnorePointer(
          child: Opacity(
            opacity: opacity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 18 * entry,
                    sigmaY: 18 * entry,
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3EEFF).withValues(
                        alpha: 0.74 * opacity,
                      ),
                      gradient: RadialGradient(
                        center: const Alignment(0, -0.14),
                        radius: 1.12,
                        colors: [
                          action.gradient.first.withValues(alpha: 0.16 * opacity),
                          const Color(0xFFF7F4FF).withValues(alpha: opacity),
                        ],
                      ),
                    ),
                  ),
                ),
                _AtmosphericParticles(
                  progress: sceneProgress,
                  colors: action.gradient,
                ),
                Center(
                  child: Transform.translate(
                    offset: Offset(0, lift),
                    child: Transform.scale(
                      scale: scale,
                      child: SizedBox(
                        width: stageWidth,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _OverlayTopLine(
                                action: action,
                                isMine: widget.data.isMine,
                              ),
                              const SizedBox(height: 14),
                              _CinematicStage(
                                action: action,
                                progress: sceneProgress,
                                overlayMode: true,
                              ),
                              const SizedBox(height: 18),
                              Text(
                                action.stageTitle,
                                textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                      color: const Color(0xFF2D2350),
                                      fontSize: 30,
                                      letterSpacing: -0.4,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                action.sceneMoment,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: const Color(0xFF665C89),
                                      height: 1.45,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class FlirtyActionMessageCard extends StatefulWidget {
  const FlirtyActionMessageCard({
    super.key,
    required this.messagePreview,
    required this.action,
    required this.isMine,
    this.onTap,
  });

  final String messagePreview;
  final FlirtyAction action;
  final bool isMine;
  final VoidCallback? onTap;

  @override
  State<FlirtyActionMessageCard> createState() => _FlirtyActionMessageCardState();
}

class _FlirtyActionMessageCardState extends State<FlirtyActionMessageCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final action = widget.action;

    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final pulse = 1 + math.sin(_controller.value * math.pi * 2) * 0.01;
          return Transform.scale(
            scale: pulse,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: action.gradient.first.withValues(alpha: 0.18),
                    blurRadius: 26,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: child!,
            ),
          );
        },
        child: Container(
          constraints: const BoxConstraints(maxWidth: 286),
          padding: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                action.gradient.first.withValues(alpha: 0.85),
                action.gradient.last.withValues(alpha: 0.64),
              ],
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(27),
            child: Stack(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xF4FDFBFF),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.82),
                        const Color(0xFFF1EDFF),
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _MoodChip(
                              label: action.moodTag,
                              colors: action.gradient,
                              icon: action.icon,
                            ),
                            const Spacer(),
                            _ReplayBadge(isMine: widget.isMine),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _CompactSceneFrame(
                          action: action,
                          progress: _controller.value,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          action.label,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                color: const Color(0xFF2F2650),
                                fontSize: 19,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.messagePreview,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: const Color(0xFF5B527D),
                              ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                action.hint,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(
                                      color: const Color(0xFF7B7297),
                                      letterSpacing: 0.15,
                                    ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                color: Colors.white.withValues(alpha: 0.64),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                              child: Text(
                                '回放',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(
                                      color: const Color(0xFF5D537F),
                                      letterSpacing: 0.2,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: const Alignment(-0.8, -1),
                          end: const Alignment(0.3, 0.9),
                          colors: [
                            Colors.white.withValues(alpha: 0.22),
                            Colors.transparent,
                          ],
                          stops: const [0, 0.54],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FlirtyActionPickerSheet extends StatefulWidget {
  const FlirtyActionPickerSheet({super.key});

  @override
  State<FlirtyActionPickerSheet> createState() => _FlirtyActionPickerSheetState();
}

class _FlirtyActionPickerSheetState extends State<FlirtyActionPickerSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groups = FlirtyMoodGroup.values;

    return Padding(
      padding: EdgeInsets.only(
        left: 14,
        right: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 14,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(34),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xF7FBF7FF),
              Color(0xF2F0FBFF),
              Color(0xEEF2FFFF),
            ],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
          boxShadow: [
            BoxShadow(
              color: const Color(0x339B63FF),
              blurRadius: 28,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 640),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PickerHeader(controller: _controller),
              const SizedBox(height: 18),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: groups.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final group = groups[index];
                    final actions = FlirtyAction.all
                        .where((item) => item.moodGroup == group)
                        .toList();
                    return AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        final start = 0.08 * index;
                        final progress = Curves.easeOutCubic.transform(
                          ((_controller.value - start) / 0.45).clamp(0.0, 1.0),
                        );
                        return Transform.translate(
                          offset: Offset(0, (1 - progress) * 16),
                          child: Opacity(opacity: progress, child: child),
                        );
                      },
                      child: _MoodSection(
                        group: group,
                        actions: actions,
                        onTap: (action) => Navigator.of(context).pop(action),
                        progress: _controller.value,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickerHeader extends StatelessWidget {
  const _PickerHeader({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                final glow = 0.14 + controller.value * 0.16;
                return Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFB37BFF), Color(0xFF84CFFF)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0x33A56BFF).withValues(alpha: glow),
                        blurRadius: 24,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.favorite_outline_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '熊猴互动',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: const Color(0xFF2E2550),
                        ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '用小熊和小猴承载暧昧动作，气质更轻松，也更有记忆点。',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: const Color(0xFF7D739B),
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final progress = Curves.easeOutCubic.transform(controller.value);
            return Transform.translate(
              offset: Offset(0, (1 - progress) * 12),
              child: Opacity(
                opacity: progress,
                child: const _SignatureDuoPanel(),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _SignatureDuoPanel extends StatelessWidget {
  const _SignatureDuoPanel();

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Colors.white.withValues(alpha: 0.86),
          letterSpacing: 0.18,
        );
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0x33A76BFF),
            Color(0xCCFFFFFF),
            Color(0x3389CDFF),
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.82),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '固定签名角色',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF2E2550),
                      ),
                ),
              ),
              Text('小熊 x 小猴 / 明亮紫调', style: labelStyle),
            ],
          ),
          const SizedBox(height: 12),
          const _SignatureDuoStage(),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _PoseChip(label: '日常', expression: _ChibiExpression.neutral),
              _PoseChip(label: '微笑', expression: _ChibiExpression.softSmile),
              _PoseChip(label: '害羞', expression: _ChibiExpression.shy),
              _PoseChip(
                label: '坏笑',
                expression: _ChibiExpression.naughtySmile,
              ),
              _PoseChip(
                label: '心动',
                expression: _ChibiExpression.surprised,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SignatureDuoStage extends StatelessWidget {
  const _SignatureDuoStage();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 168,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const RadialGradient(
          center: Alignment(0, -0.26),
          radius: 1.08,
          colors: [
            Color(0x66B67BFF),
            Color(0xFFF5F1FF),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 28,
            right: 28,
            top: 18,
            height: 64,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.78),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 28,
            right: 28,
            bottom: 16,
            height: 32,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    const Color(0x40AA74FF),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          const Positioned(
            left: 30,
            top: 12,
            child: _StageNameTag(label: '熊仔'),
          ),
          const Positioned(
            right: 30,
            top: 12,
            child: _StageNameTag(label: '猴仔'),
          ),
          const Positioned(
            left: 28,
            top: 28,
            child: _CharacterStandPreview(
              proactive: true,
              expression: _ChibiExpression.neutral,
            ),
          ),
          const Positioned(
            right: 24,
            top: 34,
            child: _CharacterStandPreview(
              proactive: false,
              expression: _ChibiExpression.softSmile,
            ),
          ),
        ],
      ),
    );
  }
}

class _StageNameTag extends StatelessWidget {
  const _StageNameTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.black.withValues(alpha: 0.28),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.78),
              letterSpacing: 0.18,
            ),
      ),
    );
  }
}

class _CharacterStandPreview extends StatelessWidget {
  const _CharacterStandPreview({
    required this.proactive,
    required this.expression,
  });

  final bool proactive;
  final _ChibiExpression expression;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: proactive ? 0.9 : 0.86,
      child: _ChibiBoy(
        proactive: proactive,
        faceRight: proactive,
        expression: expression,
        headTilt: proactive ? -0.02 : 0.04,
        bodyLean: proactive ? 0.03 : -0.01,
        frontArmReach: 0.1,
        frontArmLift: 0.1,
        backArmLift: 0.1,
        blush: proactive ? 0.18 : 0.24,
      ),
    );
  }
}

class _PoseChip extends StatelessWidget {
  const _PoseChip({
    required this.label,
    required this.expression,
  });

  final String label;
  final _ChibiExpression expression;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 28,
            height: 22,
            child: CustomPaint(
              painter: _FacePainter(
                expression: expression,
                blush: expression == _ChibiExpression.shy ? 0.42 : 0.16,
                proactive: expression == _ChibiExpression.naughtySmile,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.84),
                  letterSpacing: 0.16,
                ),
          ),
        ],
      ),
    );
  }
}

class _MoodSection extends StatelessWidget {
  const _MoodSection({
    required this.group,
    required this.actions,
    required this.onTap,
    required this.progress,
  });

  final FlirtyMoodGroup group;
  final List<FlirtyAction> actions;
  final ValueChanged<FlirtyAction> onTap;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final groupTint = switch (group) {
      FlirtyMoodGroup.tease => const Color(0xFFCF866A),
      FlirtyMoodGroup.closer => const Color(0xFFB8897A),
      FlirtyMoodGroup.cute => const Color(0xFF8EA0E6),
      FlirtyMoodGroup.stir => const Color(0xFF6F8FB7),
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            groupTint.withValues(alpha: 0.11),
            Colors.white.withValues(alpha: 0.56),
          ],
        ),
        border: Border.all(
          color: groupTint.withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF2F2650),
                        letterSpacing: -0.1,
                      ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        group.subtitle,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: const Color(0xFF6F658F),
                              letterSpacing: 0.15,
                            ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: groupTint.withValues(alpha: 0.14),
                      ),
                      child: Text(
                        '${actions.length} 款',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: const Color(0xFF544A78),
                              letterSpacing: 0.12,
                            ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: actions.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.9,
            ),
            itemBuilder: (context, index) {
              final action = actions[index];
              return _RelationshipActionCell(
                action: action,
                progress: (progress + index * 0.14) % 1,
                onTap: () => onTap(action),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RelationshipActionCell extends StatelessWidget {
  const _RelationshipActionCell({
    required this.action,
    required this.progress,
    required this.onTap,
  });

  final FlirtyAction action;
  final double progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              action.gradient.first.withValues(alpha: 0.78),
              action.gradient.last.withValues(alpha: 0.56),
            ],
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(23),
            color: const Color(0xF8FFFDFE),
          ),
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: action.gradient.first.withValues(alpha: 0.14),
                      ),
                      child: Icon(
                        action.icon,
                        size: 16,
                        color: const Color(0xFF3E3364),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: Colors.white.withValues(alpha: 0.76),
                      ),
                      child: Text(
                        action.moodTag,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: const Color(0xFF5C527E),
                              letterSpacing: 0.18,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: _CompactSceneFrame(
                            action: action,
                            progress: progress,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 10,
                        right: 10,
                        bottom: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: const Color(0x80FFFFFF),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                          child: Text(
                            action.sceneMoment,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: const Color(0xFF574D79),
                                  letterSpacing: 0.05,
                                ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 10,
                        top: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: Colors.white.withValues(alpha: 0.72),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.play_circle_fill_rounded,
                                size: 12,
                                color: Color(0xFF726794),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '点开',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(
                                      color: const Color(0xFF726794),
                                      letterSpacing: 0.12,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  action.label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF2F2650),
                        fontSize: 15,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  action.stageTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: const Color(0xFF6A608D),
                        letterSpacing: 0.18,
                      ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        action.hint,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: const Color(0xFF756B96),
                              letterSpacing: 0.15,
                            ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_outward_rounded,
                      size: 14,
                      color: const Color(0xFF8277A4),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompactSceneFrame extends StatelessWidget {
  const _CompactSceneFrame({
    required this.action,
    required this.progress,
  });

  final FlirtyAction action;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 112,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: RadialGradient(
          center: const Alignment(0, -0.3),
          radius: 1.18,
          colors: [
            action.gradient.first.withValues(alpha: 0.18),
            const Color(0xFFF5F1FF),
          ],
        ),
      ),
      child: _FlirtyDuoScene(
        action: action,
        progress: progress,
        compact: true,
      ),
    );
  }
}

class _OverlayTopLine extends StatelessWidget {
  const _OverlayTopLine({
    required this.action,
    required this.isMine,
  });

  final FlirtyAction action;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _MoodChip(
          label: action.moodTag,
          colors: action.gradient,
          icon: action.icon,
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: Colors.white.withValues(alpha: 0.82),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
          child: Text(
            isMine ? '你先伸手' : '他先靠近',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: const Color(0xFF635985),
                  letterSpacing: 0.2,
                ),
          ),
        ),
      ],
    );
  }
}

class _MoodChip extends StatelessWidget {
  const _MoodChip({
    required this.label,
    required this.colors,
    required this.icon,
  });

  final String label;
  final List<Color> colors;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: LinearGradient(
            colors: [
            colors.first.withValues(alpha: 0.18),
            colors.last.withValues(alpha: 0.12),
          ],
        ),
        border: Border.all(
          color: colors.first.withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 7),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: const Color(0xFF413566),
                  letterSpacing: 0.2,
                ),
          ),
        ],
      ),
    );
  }
}

class _ReplayBadge extends StatelessWidget {
  const _ReplayBadge({required this.isMine});

  final bool isMine;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withValues(alpha: 0.76),
      ),
      child: Text(
        isMine ? '你发出的暧昧' : '对方向你靠近',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: const Color(0xFF6B618D),
              letterSpacing: 0.1,
            ),
      ),
    );
  }
}

class _CinematicStage extends StatelessWidget {
  const _CinematicStage({
    required this.action,
    required this.progress,
    required this.overlayMode,
  });

  final FlirtyAction action;
  final double progress;
  final bool overlayMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: overlayMode ? 320 : 248,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: RadialGradient(
          center: const Alignment(0, -0.28),
          radius: 1.08,
          colors: [
            Colors.white.withValues(alpha: 0.92),
            const Color(0xFFF3EEFF),
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.94),
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    action.gradient.first.withValues(alpha: 0.14),
                    Colors.transparent,
                    const Color(0xFFEFEAFF).withValues(alpha: 0.9),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 54,
            right: 54,
            top: 18,
            height: 132,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.92),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 26,
            height: 54,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.03),
                    action.gradient.first.withValues(alpha: 0.16),
                    Colors.white.withValues(alpha: 0.03),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 18,
            top: 18,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: Colors.white.withValues(alpha: 0.7),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              child: const Text(
                'XiongHou Duo',
                style: TextStyle(
                  color: Color(0xFF6D628F),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
          _FlirtyDuoScene(
            action: action,
            progress: progress,
            compact: false,
          ),
        ],
      ),
    );
  }
}

class _AtmosphericParticles extends StatelessWidget {
  const _AtmosphericParticles({
    required this.progress,
    required this.colors,
  });

  final double progress;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return IgnorePointer(
      child: Stack(
        children: List.generate(14, (index) {
          final seed = index / 14;
          final orbit = 96 + index * 18;
          final dx = size.width / 2 +
              math.cos(seed * math.pi * 2 + progress * 1.2) * orbit;
          final dy = size.height * 0.43 +
              math.sin(seed * math.pi * 3 + progress) * 32 +
              index * 10;
          final diameter = 5.0 + (index % 4) * 2.0;
          return Positioned(
            left: dx,
            top: dy,
            child: Opacity(
              opacity: (0.08 +
                      (math.sin(progress * math.pi * 2 + index) + 1) * 0.07)
                  .clamp(0.0, 0.24),
              child: Container(
                width: diameter,
                height: diameter,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (index.isEven ? colors.first : colors.last)
                      .withValues(alpha: 0.74),
                  boxShadow: [
                    BoxShadow(
                      color: (index.isEven ? colors.first : colors.last)
                          .withValues(alpha: 0.22),
                      blurRadius: 18,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _FlirtyDuoScene extends StatelessWidget {
  const _FlirtyDuoScene({
    required this.action,
    required this.progress,
    required this.compact,
  });

  final FlirtyAction action;
  final double progress;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final motion = _buildMotion(action.id, progress);
    final scale = compact ? 0.66 : 1.0;
    final stageHeight = compact ? 112.0 : 320.0;

    return SizedBox(
      height: stageHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final accent in motion.accents)
            Positioned(
              left: accent.offset.dx * scale,
              top: accent.offset.dy * scale,
              child: Opacity(
                opacity: accent.opacity,
                child: Transform.scale(
                  scale: accent.scale * scale,
                  child: accent.child,
                ),
              ),
            ),
          Positioned(
            left: motion.left.dx * scale,
            top: motion.left.dy * scale,
            child: Transform.rotate(
              angle: motion.leftPose.rotation,
              child: Transform.scale(
                scale: motion.leftPose.scale * scale,
                child: _ChibiBoy(
                  proactive: true,
                  faceRight: true,
                  expression: motion.leftPose.expression,
                  headTilt: motion.leftPose.headTilt,
                  bodyLean: motion.leftPose.bodyLean,
                  frontArmReach: motion.leftPose.frontArmReach,
                  frontArmLift: motion.leftPose.frontArmLift,
                  backArmLift: motion.leftPose.backArmLift,
                  blush: motion.leftPose.blush,
                ),
              ),
            ),
          ),
          Positioned(
            left: motion.right.dx * scale,
            top: motion.right.dy * scale,
            child: Transform.rotate(
              angle: motion.rightPose.rotation,
              child: Transform.scale(
                scale: motion.rightPose.scale * scale,
                child: _ChibiBoy(
                  proactive: false,
                  faceRight: false,
                  expression: motion.rightPose.expression,
                  headTilt: motion.rightPose.headTilt,
                  bodyLean: motion.rightPose.bodyLean,
                  frontArmReach: motion.rightPose.frontArmReach,
                  frontArmLift: motion.rightPose.frontArmLift,
                  backArmLift: motion.rightPose.backArmLift,
                  blush: motion.rightPose.blush,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  _SceneMotion _buildMotion(String id, double rawProgress) {
    final t = compact
        ? rawProgress
        : Curves.easeInOutCubic.transform(rawProgress.clamp(0.0, 1.0));
    final drift = math.sin(t * math.pi * 2) * 4;
    final breathe = math.sin(t * math.pi * 2 + 0.7) * 2;

    switch (id) {
      case 'poke_butt':
        final windUp = _segment(t, 0.0, 0.16, Curves.easeOut);
        final jab = _segment(t, 0.16, 0.34, Curves.easeIn);
        final bounce = _dampedWave(t, start: 0.34, speed: 18, decay: 5.2);
        final hairFlick = _segment(t, 0.34, 0.5, Curves.easeOut);
        return _SceneMotion(
          left: Offset(52 + windUp * 12 + jab * 38, 120 + drift),
          right: Offset(212 - jab * 2, 90 - bounce * 24 + breathe),
          leftPose: _ActorPose(
            scale: 1.02,
            rotation: -0.08 + jab * 0.08,
            expression: jab > 0.28
                ? _ChibiExpression.naughtySmile
                : _ChibiExpression.mischief,
            headTilt: -0.18 + windUp * 0.07,
            bodyLean: 0.16 + jab * 0.34,
            frontArmReach: 0.34 + jab * 0.6,
            frontArmLift: 0.18 + jab * 0.12,
            backArmLift: 0.24,
            blush: 0.14,
          ),
          rightPose: _ActorPose(
            scale: 1.0,
            rotation: 0.04 - bounce * 0.05,
            expression: bounce.abs() > 0.14
                ? _ChibiExpression.surprised
                : _ChibiExpression.flustered,
            headTilt: 0.12 + bounce * 0.12,
            bodyLean: -0.12 - bounce * 0.24,
            frontArmReach: 0.12,
            frontArmLift: 0.54 + bounce.abs() * 0.16,
            backArmLift: 0.26,
            blush: 0.38,
          ),
          accents: [
            _SceneAccent(
              child: const _ImpactBurst(),
              offset: Offset(194 + jab * 18, 160 - bounce * 12),
              opacity: 0.16 + jab * 0.68,
              scale: 0.66 + jab * 0.46,
            ),
            _SceneAccent(
              child: const _BounceRing(),
              offset: Offset(214, 208 - bounce * 18),
              opacity: 0.14 + bounce.abs() * 0.32,
              scale: 0.88 + bounce.abs() * 0.32,
            ),
            _SceneAccent(
              child: const _HairFlickAccent(),
              offset: Offset(234, 98 - bounce * 10),
              opacity: 0.08 + hairFlick * 0.3,
              scale: 0.92 + hairFlick * 0.18,
            ),
          ],
        );
      case 'tug_sleeve':
        final reach = _segment(t, 0.0, 0.22, Curves.easeOut);
        final pull = _segment(t, 0.22, 0.52, Curves.easeInOut);
        final settle = _segment(t, 0.52, 0.84, Curves.easeOut);
        final shyDip = _segment(t, 0.12, 0.34, Curves.easeInOut);
        return _SceneMotion(
          left: Offset(74 + pull * 14, 118 + drift * 0.5),
          right: Offset(214 - pull * 12, 114 - settle * 12),
          leftPose: _ActorPose(
            scale: 1.0,
            rotation: -0.03,
            expression: _ChibiExpression.softSmile,
            headTilt: -0.06,
            bodyLean: 0.08 + pull * 0.08,
            frontArmReach: 0.54 + pull * 0.16,
            frontArmLift: 0.22 + reach * 0.12,
            backArmLift: 0.2,
            blush: 0.16,
          ),
          rightPose: _ActorPose(
            scale: 0.98,
            rotation: 0.03,
            expression: pull > 0.18
                ? _ChibiExpression.shy
                : _ChibiExpression.softSmile,
            headTilt: 0.18 + shyDip * 0.08,
            bodyLean: -0.04 - pull * 0.14,
            frontArmReach: 0.24,
            frontArmLift: 0.22 + shyDip * 0.06,
            backArmLift: 0.16 + settle * 0.14,
            blush: 0.42,
          ),
          accents: [
            _SceneAccent(
              child: const _SleeveRibbon(),
              offset: Offset(164 + pull * 8, 156),
              opacity: 0.18 + pull * 0.56,
              scale: 1.0,
            ),
            _SceneAccent(
              child: const _ClothTensionAccent(),
              offset: Offset(178 + pull * 5, 150),
              opacity: 0.1 + pull * 0.34,
              scale: 1.0,
            ),
            _SceneAccent(
              child: const _HeartDustCluster(),
              offset: const Offset(150, 90),
              opacity: 0.1 + settle * 0.28,
              scale: 0.9,
            ),
          ],
        );
      case 'pat_head':
        final drop = _segment(t, 0.08, 0.28, Curves.easeOut);
        final pat = _pulse(t, 0.28, 0.52);
        final rest = _segment(t, 0.52, 0.86, Curves.easeOut);
        return _SceneMotion(
          left: Offset(80, 110 + drift * 0.4),
          right: Offset(214, 122 - pat * 10),
          leftPose: _ActorPose(
            scale: 1.0,
            rotation: -0.03,
            expression: _ChibiExpression.gentle,
            headTilt: -0.04,
            bodyLean: 0.02,
            frontArmReach: 0.56,
            frontArmLift: 0.44 + drop * 0.46,
            backArmLift: 0.14,
            blush: 0.12,
          ),
          rightPose: _ActorPose(
            scale: 0.98,
            rotation: 0.03,
            expression: rest > 0.16
                ? _ChibiExpression.comforted
                : _ChibiExpression.softSmile,
            headTilt: 0.12 + pat * 0.06,
            bodyLean: -0.06,
            frontArmReach: 0.16,
            frontArmLift: 0.16,
            backArmLift: 0.18,
            blush: 0.3,
          ),
          accents: [
            _SceneAccent(
              child: const _StarHalo(),
              offset: Offset(208, 88 - pat * 12),
              opacity: 0.16 + pat * 0.5,
              scale: 0.9 + pat * 0.24,
            ),
          ],
        );
      case 'hook_finger':
        final approach1 = _segment(t, 0.0, 0.22, Curves.easeOut);
        final approach2 = _segment(t, 0.28, 0.44, Curves.easeOut);
        final lock = _segment(t, 0.44, 0.62, Curves.easeInOut);
        final sway = math.sin(math.max(0.0, t - 0.62) * math.pi * 4) * 0.5;
        final pause = _segment(t, 0.22, 0.3, Curves.linear);
        return _SceneMotion(
          left: Offset(88 + approach1 * 12 + approach2 * 8, 118 + drift * 0.6),
          right: Offset(196 - approach1 * 10 - approach2 * 12, 118 - drift * 0.2),
          leftPose: _ActorPose(
            scale: 1.0,
            rotation: -0.02 + sway * 0.02,
            expression: lock > 0.1
                ? _ChibiExpression.naughtySmile
                : _ChibiExpression.mischief,
            headTilt: -0.12 + pause * 0.03,
            bodyLean: 0.08 + lock * 0.08,
            frontArmReach: 0.46 + approach1 * 0.16 + approach2 * 0.18,
            frontArmLift: 0.18,
            backArmLift: 0.14,
            blush: 0.14,
          ),
          rightPose: _ActorPose(
            scale: 1.0,
            rotation: 0.02 - sway * 0.02,
            expression: lock > 0.2
                ? _ChibiExpression.shy
                : _ChibiExpression.flustered,
            headTilt: 0.14 + pause * 0.05,
            bodyLean: -0.02 + lock * 0.02,
            frontArmReach: 0.38 + approach2 * 0.18,
            frontArmLift: 0.16,
            backArmLift: 0.14,
            blush: 0.44,
          ),
          accents: [
            _SceneAccent(
              child: const _FingerBridge(),
              offset: const Offset(156, 168),
              opacity: 0.18 + lock * 0.58,
              scale: 1.0,
            ),
            _SceneAccent(
              child: const _EyeContactAccent(),
              offset: const Offset(142, 104),
              opacity: 0.08 + pause * 0.2 + lock * 0.12,
              scale: 1.0,
            ),
            _SceneAccent(
              child: const _HeartDustCluster(),
              offset: const Offset(164, 116),
              opacity: 0.08 + lock * 0.34,
              scale: 0.86,
            ),
          ],
        );
      case 'lean_closer':
        final push = _segment(t, 0.06, 0.46, Curves.easeOutCubic);
        final hover = _segment(t, 0.46, 0.76, Curves.linear);
        final eyeLock = _segment(t, 0.3, 0.72, Curves.easeInOut);
        return _SceneMotion(
          left: Offset(96 + push * 22, 110 + drift),
          right: Offset(210 - push * 18, 114 - drift * 0.4),
          leftPose: _ActorPose(
            scale: 1.03,
            rotation: -0.01,
            expression: hover > 0.1
                ? _ChibiExpression.naughtySmile
                : _ChibiExpression.mischief,
            headTilt: -0.08 - eyeLock * 0.03,
            bodyLean: 0.12 + push * 0.18,
            frontArmReach: 0.3 + push * 0.12,
            frontArmLift: 0.14,
            backArmLift: 0.12,
            blush: 0.14,
          ),
          rightPose: _ActorPose(
            scale: 1.0,
            rotation: 0.01,
            expression: hover > 0.16
                ? _ChibiExpression.flustered
                : _ChibiExpression.shy,
            headTilt: 0.12 + eyeLock * 0.02,
            bodyLean: -0.08 - push * 0.08,
            frontArmReach: 0.18,
            frontArmLift: 0.22,
            backArmLift: 0.14,
            blush: 0.42,
          ),
          accents: [
            _SceneAccent(
              child: const _BreathHalo(),
              offset: const Offset(142, 84),
              opacity: 0.12 + push * 0.36,
              scale: 0.94 + push * 0.22,
            ),
            _SceneAccent(
              child: const _EyeContactAccent(),
              offset: const Offset(148, 108),
              opacity: 0.06 + eyeLock * 0.18,
              scale: 0.94 + eyeLock * 0.08,
            ),
          ],
        );
      case 'sneak_glance':
        final glance = _pulse(t, 0.18, 0.42);
        final retreat = _segment(t, 0.42, 0.66, Curves.easeIn);
        return _SceneMotion(
          left: Offset(92, 118 + drift),
          right: Offset(214, 118 - drift * 0.3),
          leftPose: _ActorPose(
            scale: 1.0,
            rotation: -0.02,
            expression: glance > 0.2
                ? _ChibiExpression.glance
                : _ChibiExpression.softSmile,
            headTilt: -0.18 + retreat * 0.08,
            bodyLean: 0.0,
            frontArmReach: 0.16,
            frontArmLift: 0.14,
            backArmLift: 0.12,
            blush: 0.12,
          ),
          rightPose: _ActorPose(
            scale: 1.0,
            rotation: 0.02,
            expression: retreat > 0.08
                ? _ChibiExpression.shy
                : _ChibiExpression.surprised,
            headTilt: 0.08 + glance * 0.08,
            bodyLean: -0.02,
            frontArmReach: 0.14,
            frontArmLift: 0.14,
            backArmLift: 0.12,
            blush: 0.34,
          ),
          accents: [
            _SceneAccent(
              child: const _GlanceBeam(),
              offset: Offset(144 + glance * 8, 114),
              opacity: 0.12 + glance * 0.44,
              scale: 1.0,
            ),
          ],
        );
      case 'brush_shoulder':
        final cross = _segment(t, 0.1, 0.46, Curves.easeInOut);
        final checkBack = _segment(t, 0.52, 0.78, Curves.easeOut);
        return _SceneMotion(
          left: Offset(96 + cross * 22, 126 + drift * 0.4),
          right: Offset(186 - cross * 16, 124 - drift * 0.2),
          leftPose: _ActorPose(
            scale: 1.0,
            rotation: -0.01,
            expression: checkBack > 0.1
                ? _ChibiExpression.softSmile
                : _ChibiExpression.gentle,
            headTilt: -0.08,
            bodyLean: 0.14,
            frontArmReach: 0.18,
            frontArmLift: 0.12,
            backArmLift: 0.12,
            blush: 0.16,
          ),
          rightPose: _ActorPose(
            scale: 1.0,
            rotation: 0.01,
            expression: cross > 0.16
                ? _ChibiExpression.flustered
                : _ChibiExpression.shy,
            headTilt: 0.1 + checkBack * 0.08,
            bodyLean: -0.08,
            frontArmReach: 0.14,
            frontArmLift: 0.14,
            backArmLift: 0.12,
            blush: 0.34,
          ),
          accents: [
            _SceneAccent(
              child: const _ShoulderTrail(),
              offset: const Offset(146, 154),
              opacity: 0.14 + cross * 0.46,
              scale: 1.0,
            ),
          ],
        );
      case 'naughty_smile':
      default:
        final lookUp = _segment(t, 0.06, 0.3, Curves.easeOut);
        final smile = _segment(t, 0.3, 0.56, Curves.easeOut);
        return _SceneMotion(
          left: Offset(98, 118 + drift),
          right: Offset(216, 118 - drift * 0.2),
          leftPose: _ActorPose(
            scale: 1.02,
            rotation: -0.02,
            expression: smile > 0.18
                ? _ChibiExpression.naughtySmile
                : _ChibiExpression.mischief,
            headTilt: -0.16 + lookUp * 0.1,
            bodyLean: 0.04,
            frontArmReach: 0.16,
            frontArmLift: 0.12,
            backArmLift: 0.12,
            blush: 0.14,
          ),
          rightPose: _ActorPose(
            scale: 1.0,
            rotation: 0.02,
            expression: smile > 0.18
                ? _ChibiExpression.flustered
                : _ChibiExpression.shy,
            headTilt: 0.1,
            bodyLean: -0.02,
            frontArmReach: 0.12,
            frontArmLift: 0.14,
            backArmLift: 0.12,
            blush: 0.4,
          ),
          accents: [
            _SceneAccent(
              child: const _SmileSlash(),
              offset: const Offset(162, 120),
              opacity: 0.1 + smile * 0.32,
              scale: 1.0,
            ),
          ],
        );
    }
  }

  double _segment(
    double t,
    double start,
    double end,
    Curve curve,
  ) {
    if (t <= start) return 0;
    if (t >= end) return 1;
    return curve.transform((t - start) / (end - start));
  }

  double _pulse(double t, double start, double end) {
    final p = _segment(t, start, end, Curves.easeInOut);
    return math.sin(p * math.pi);
  }

  double _dampedWave(
    double t, {
    required double start,
    required double speed,
    required double decay,
  }) {
    final normalized = math.max(0.0, t - start);
    return math.sin(normalized * speed) * math.exp(-normalized * decay);
  }
}

class _SceneMotion {
  const _SceneMotion({
    required this.left,
    required this.right,
    required this.leftPose,
    required this.rightPose,
    required this.accents,
  });

  final Offset left;
  final Offset right;
  final _ActorPose leftPose;
  final _ActorPose rightPose;
  final List<_SceneAccent> accents;
}

class _SceneAccent {
  const _SceneAccent({
    required this.child,
    required this.offset,
    required this.opacity,
    required this.scale,
  });

  final Widget child;
  final Offset offset;
  final double opacity;
  final double scale;
}

class _ActorPose {
  const _ActorPose({
    required this.scale,
    required this.rotation,
    required this.expression,
    required this.headTilt,
    required this.bodyLean,
    required this.frontArmReach,
    required this.frontArmLift,
    required this.backArmLift,
    required this.blush,
  });

  final double scale;
  final double rotation;
  final _ChibiExpression expression;
  final double headTilt;
  final double bodyLean;
  final double frontArmReach;
  final double frontArmLift;
  final double backArmLift;
  final double blush;
}

enum _ChibiExpression {
  comforted,
  flustered,
  gentle,
  glance,
  mischief,
  naughtySmile,
  neutral,
  shy,
  softSmile,
  surprised,
}

class _ChibiBoy extends StatelessWidget {
  const _ChibiBoy({
    required this.proactive,
    required this.faceRight,
    required this.expression,
    required this.headTilt,
    required this.bodyLean,
    required this.frontArmReach,
    required this.frontArmLift,
    required this.backArmLift,
    required this.blush,
  });

  final bool proactive;
  final bool faceRight;
  final _ChibiExpression expression;
  final double headTilt;
  final double bodyLean;
  final double frontArmReach;
  final double frontArmLift;
  final double backArmLift;
  final double blush;

  @override
  Widget build(BuildContext context) {
    final palette = proactive
        ? const _CharacterPalette(
            skin: Color(0xFFF3D4BF),
            hairTop: Color(0xFF5B4033),
            hairBase: Color(0xFF2E1E19),
            shirtTop: Color(0xFFFFF2D9),
            shirtBase: Color(0xFFE7C78E),
            shortsTop: Color(0xFF9A5B3E),
            shortsBase: Color(0xFF723926),
            sneakerTop: Color(0xFFF8F7F5),
            sneakerBase: Color(0xFFA8A7A5),
            accent: Color(0xFFFFB978),
            shadow: Color(0xFF1C120F),
          )
        : const _CharacterPalette(
            skin: Color(0xFFF6D9C7),
            hairTop: Color(0xFF453A34),
            hairBase: Color(0xFF241B18),
            shirtTop: Color(0xFFF7F8FF),
            shirtBase: Color(0xFFC9D7F2),
            shortsTop: Color(0xFF6885A2),
            shortsBase: Color(0xFF46617A),
            sneakerTop: Color(0xFFF9F8F6),
            sneakerBase: Color(0xFFBAB8B4),
            accent: Color(0xFF90B8D9),
            shadow: Color(0xFF11141B),
          );

    final frontArmAngle =
        lerpDouble(-0.55, 0.1, frontArmLift)! - frontArmReach * 0.42;
    final backArmAngle = lerpDouble(0.42, -0.06, backArmLift)!;
    final bodyRotation = bodyLean * 0.1;

    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..scale(faceRight ? 1.0 : -1.0, 1.0),
      child: SizedBox(
        width: 144,
        height: 184,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 22,
              right: 22,
              bottom: 8,
              height: 18,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: Colors.black.withValues(alpha: 0.24),
                ),
              ),
            ),
            Positioned(
              left: 38,
              bottom: 20,
              child: _Limb(
                angle: -0.08,
                color: palette.skin,
                height: 34,
                width: 18,
              ),
            ),
            Positioned(
              right: 34,
              bottom: 20,
              child: _Limb(
                angle: 0.08,
                color: palette.skin,
                height: 34,
                width: 18,
              ),
            ),
            Positioned(
              left: 28,
              bottom: 10,
              child: _Sneaker(
                colorTop: palette.sneakerTop,
                colorBase: palette.sneakerBase,
              ),
            ),
            Positioned(
              right: 24,
              bottom: 10,
              child: _Sneaker(
                colorTop: palette.sneakerTop,
                colorBase: palette.sneakerBase,
              ),
            ),
            Positioned(
              left: 18,
              top: 88,
              child: _Limb(
                angle: backArmAngle + bodyLean * 0.1,
                color: palette.skin,
                height: 42,
                width: 18,
              ),
            ),
            Positioned(
              right: 24 - frontArmReach * 12,
              top: 88 - frontArmLift * 10,
              child: _Limb(
                angle: frontArmAngle,
                color: palette.skin,
                height: 46,
                width: 18,
              ),
            ),
            Positioned(
              left: 30,
              top: 88,
              child: Transform.rotate(
                angle: bodyRotation,
                child: _ChibiBody(
                  proactive: proactive,
                  palette: palette,
                ),
              ),
            ),
            Positioned(
              left: 16,
              top: 4,
              child: Transform.rotate(
                angle: headTilt,
                child: _ChibiHead(
                  proactive: proactive,
                  palette: palette,
                  expression: expression,
                  blush: blush,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CharacterPalette {
  const _CharacterPalette({
    required this.skin,
    required this.hairTop,
    required this.hairBase,
    required this.shirtTop,
    required this.shirtBase,
    required this.shortsTop,
    required this.shortsBase,
    required this.sneakerTop,
    required this.sneakerBase,
    required this.accent,
    required this.shadow,
  });

  final Color skin;
  final Color hairTop;
  final Color hairBase;
  final Color shirtTop;
  final Color shirtBase;
  final Color shortsTop;
  final Color shortsBase;
  final Color sneakerTop;
  final Color sneakerBase;
  final Color accent;
  final Color shadow;
}

class _ChibiBody extends StatelessWidget {
  const _ChibiBody({
    required this.proactive,
    required this.palette,
  });

  final bool proactive;
  final _CharacterPalette palette;

  @override
  Widget build(BuildContext context) {
    final bodyWidth = proactive ? 78.0 : 72.0;
    final bodyRadius = proactive ? 34.0 : 32.0;
    return SizedBox(
      width: proactive ? 84 : 78,
      height: 82,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: bodyWidth,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(bodyRadius),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [palette.shirtTop, palette.shirtBase],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.12),
                  blurRadius: 18,
                ),
              ],
            ),
          ),
          Positioned(
            left: 14,
            right: proactive ? 14 : 10,
            top: 10,
            height: 10,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: Colors.white.withValues(alpha: 0.18),
              ),
            ),
          ),
          Positioned(
            left: proactive ? 24 : 22,
            right: proactive ? 24 : 22,
            top: -8,
            height: 22,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: palette.skin,
              ),
            ),
          ),
          Positioned(
            left: proactive ? 16 : 14,
            right: proactive ? 16 : 14,
            top: 42,
            height: 28,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [palette.shortsTop, palette.shortsBase],
                ),
              ),
            ),
          ),
          Positioned(
            left: proactive ? 20 : 18,
            top: 48,
            child: Container(
              width: proactive ? 12 : 10,
              height: 20,
              decoration: BoxDecoration(
                color: palette.skin,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Positioned(
            right: proactive ? 20 : 18,
            top: 48,
            child: Container(
              width: proactive ? 12 : 10,
              height: 20,
              decoration: BoxDecoration(
                color: palette.skin,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Positioned(
            left: proactive ? 12 : 14,
            right: proactive ? 12 : 14,
            top: 32,
            height: 14,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: palette.accent.withValues(alpha: proactive ? 0.14 : 0.09),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChibiHead extends StatelessWidget {
  const _ChibiHead({
    required this.proactive,
    required this.palette,
    required this.expression,
    required this.blush,
  });

  final bool proactive;
  final _CharacterPalette palette;
  final _ChibiExpression expression;
  final double blush;

  @override
  Widget build(BuildContext context) {
    final faceWidth = proactive ? 86.0 : 80.0;
    final faceHeight = proactive ? 80.0 : 78.0;
    return SizedBox(
      width: proactive ? 104 : 98,
      height: 98,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: proactive ? 8 : 10,
            top: 14,
            child: Container(
              width: faceWidth,
              height: faceHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                color: palette.skin,
              ),
            ),
          ),
          if (proactive)
            Positioned(
              left: 2,
              top: 0,
              child: CustomPaint(
                size: const Size(84, 48),
                painter: _ProactiveHairPainter(palette),
              ),
            )
          else
            Positioned(
              left: 2,
              top: 0,
              child: CustomPaint(
                size: const Size(84, 50),
                painter: _ShyHairPainter(palette),
              ),
            ),
          Positioned(
            left: proactive ? 14 : 16,
            top: proactive ? 22 : 20,
            child: Container(
              width: proactive ? 54 : 48,
              height: proactive ? 14 : 12,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: palette.hairBase.withValues(alpha: 0.94),
              ),
            ),
          ),
          Positioned(
            left: 24,
            top: 40,
            child: CustomPaint(
              size: const Size(42, 26),
              painter: _FacePainter(
                expression: expression,
                blush: blush,
                proactive: proactive,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Limb extends StatelessWidget {
  const _Limb({
    required this.angle,
    required this.color,
    required this.height,
    this.width = 12,
  });

  final double angle;
  final Color color;
  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      alignment: Alignment.topCenter,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _Sneaker extends StatelessWidget {
  const _Sneaker({
    required this.colorTop,
    required this.colorBase,
  });

  final Color colorTop;
  final Color colorBase;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 14,
      child: Stack(
        children: [
          Positioned(
            left: 1,
            right: 0,
            top: 3,
            bottom: 0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [colorTop, colorBase],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 2,
            bottom: 0,
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: const Color(0xFFE9E6E2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FacePainter extends CustomPainter {
  _FacePainter({
    required this.expression,
    required this.blush,
    required this.proactive,
  });

  final _ChibiExpression expression;
  final double blush;
  final bool proactive;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = const Color(0xFF2A202D)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final fill = Paint()
      ..color = const Color(0xFF2A202D)
      ..style = PaintingStyle.fill;
    final mouth = Paint()
      ..color = proactive ? const Color(0xFF7A3F49) : const Color(0xFF734B5E)
      ..strokeWidth = 1.9
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final blushPaint = Paint()
      ..color = const Color(0xFFF7AAB0).withValues(alpha: 0.28 + blush * 0.3);
    final eyeHighlight = Paint()
      ..color = Colors.white.withValues(alpha: 0.95)
      ..style = PaintingStyle.fill;

    final leftEye = Offset(size.width * 0.3, size.height * 0.4);
    final rightEye = Offset(size.width * 0.7, size.height * 0.4);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.14, size.height * 0.6),
        width: 12,
        height: 8,
      ),
      blushPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.86, size.height * 0.6),
        width: 12,
        height: 8,
      ),
      blushPaint,
    );

    switch (expression) {
      case _ChibiExpression.neutral:
        canvas.drawCircle(leftEye, 2.6, fill);
        canvas.drawCircle(rightEye, 2.6, fill);
        canvas.drawCircle(leftEye + const Offset(-0.6, -0.8), 0.8, eyeHighlight);
        canvas.drawCircle(rightEye + const Offset(-0.6, -0.8), 0.8, eyeHighlight);
        canvas.drawLine(
          Offset(size.width * 0.44, size.height * 0.72),
          Offset(size.width * 0.58, size.height * 0.72),
          mouth,
        );
        break;
      case _ChibiExpression.mischief:
        canvas.drawCircle(leftEye, 2.5, fill);
        canvas.drawCircle(rightEye, 2.5, fill);
        final path = Path()
          ..moveTo(size.width * 0.42, size.height * 0.72)
          ..quadraticBezierTo(
            size.width * 0.52,
            size.height * 0.78,
            size.width * 0.66,
            size.height * 0.67,
          );
        canvas.drawPath(path, mouth);
        break;
      case _ChibiExpression.naughtySmile:
        canvas.drawCircle(leftEye, 2.5, fill);
        canvas.drawCircle(rightEye, 2.5, fill);
        canvas.drawArc(
          Rect.fromCenter(center: leftEye, width: 10, height: 6),
          math.pi,
          math.pi,
          false,
          stroke,
        );
        canvas.drawArc(
          Rect.fromCenter(center: rightEye, width: 10, height: 6),
          math.pi,
          math.pi,
          false,
          stroke,
        );
        final path = Path()
          ..moveTo(size.width * 0.42, size.height * 0.73)
          ..quadraticBezierTo(
            size.width * 0.56,
            size.height * 0.82,
            size.width * 0.7,
            size.height * 0.66,
          );
        canvas.drawPath(path, mouth);
        break;
      case _ChibiExpression.shy:
        canvas.drawArc(
          Rect.fromCenter(center: leftEye, width: 9, height: 5),
          0,
          math.pi,
          false,
          stroke,
        );
        canvas.drawArc(
          Rect.fromCenter(center: rightEye, width: 9, height: 5),
          0,
          math.pi,
          false,
          stroke,
        );
        final shy = Path()
          ..moveTo(size.width * 0.46, size.height * 0.72)
          ..quadraticBezierTo(
            size.width * 0.52,
            size.height * 0.8,
            size.width * 0.59,
            size.height * 0.72,
          );
        canvas.drawPath(shy, mouth);
        break;
      case _ChibiExpression.softSmile:
      case _ChibiExpression.gentle:
      case _ChibiExpression.comforted:
        canvas.drawCircle(leftEye, 2.4, fill);
        canvas.drawCircle(rightEye, 2.4, fill);
        canvas.drawCircle(leftEye + const Offset(-0.6, -0.8), 0.75, eyeHighlight);
        canvas.drawCircle(rightEye + const Offset(-0.6, -0.8), 0.75, eyeHighlight);
        final smile = Path()
          ..moveTo(size.width * 0.42, size.height * 0.72)
          ..quadraticBezierTo(
            size.width * 0.52,
            size.height * 0.82,
            size.width * 0.62,
            size.height * 0.72,
          );
        canvas.drawPath(smile, mouth);
        break;
      case _ChibiExpression.surprised:
        canvas.drawCircle(leftEye, 2.8, fill);
        canvas.drawCircle(rightEye, 2.8, fill);
        canvas.drawCircle(leftEye + const Offset(-0.5, -0.8), 0.8, eyeHighlight);
        canvas.drawCircle(rightEye + const Offset(-0.5, -0.8), 0.8, eyeHighlight);
        canvas.drawCircle(
          Offset(size.width * 0.52, size.height * 0.73),
          3.4,
          Paint()..color = mouth.color,
        );
        break;
      case _ChibiExpression.glance:
        canvas.drawCircle(leftEye, 2.4, fill);
        canvas.drawCircle(rightEye + const Offset(0.8, 0), 2.4, fill);
        canvas.drawLine(
          Offset(size.width * 0.44, size.height * 0.72),
          Offset(size.width * 0.6, size.height * 0.7),
          mouth,
        );
        break;
      case _ChibiExpression.flustered:
        canvas.drawArc(
          Rect.fromCenter(center: leftEye, width: 10, height: 6),
          math.pi,
          math.pi,
          false,
          stroke,
        );
        canvas.drawArc(
          Rect.fromCenter(center: rightEye, width: 10, height: 6),
          math.pi,
          math.pi,
          false,
          stroke,
        );
        final path = Path()
          ..moveTo(size.width * 0.44, size.height * 0.72)
          ..quadraticBezierTo(
            size.width * 0.5,
            size.height * 0.84,
            size.width * 0.6,
            size.height * 0.72,
        );
        canvas.drawPath(path, mouth);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _FacePainter oldDelegate) {
    return oldDelegate.expression != expression ||
        oldDelegate.blush != blush ||
        oldDelegate.proactive != proactive;
  }
}

class _ProactiveHairPainter extends CustomPainter {
  const _ProactiveHairPainter(this.palette);

  final _CharacterPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [palette.hairTop, palette.hairBase],
      ).createShader(Offset.zero & size);
    final path = Path()
      ..moveTo(8, 30)
      ..quadraticBezierTo(10, 10, 30, 6)
      ..quadraticBezierTo(54, 0, 74, 10)
      ..quadraticBezierTo(84, 18, 80, 34)
      ..quadraticBezierTo(72, 28, 64, 36)
      ..quadraticBezierTo(58, 44, 50, 38)
      ..quadraticBezierTo(40, 46, 30, 38)
      ..quadraticBezierTo(22, 44, 14, 38)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ProactiveHairPainter oldDelegate) => false;
}

class _ShyHairPainter extends CustomPainter {
  const _ShyHairPainter(this.palette);

  final _CharacterPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [palette.hairTop, palette.hairBase],
      ).createShader(Offset.zero & size);
    final path = Path()
      ..moveTo(10, 18)
      ..quadraticBezierTo(20, 2, 42, 2)
      ..quadraticBezierTo(66, 1, 78, 16)
      ..quadraticBezierTo(82, 28, 76, 40)
      ..quadraticBezierTo(70, 34, 62, 42)
      ..quadraticBezierTo(54, 48, 44, 46)
      ..quadraticBezierTo(34, 50, 24, 46)
      ..quadraticBezierTo(12, 40, 10, 18)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ShyHairPainter oldDelegate) => false;
}

class _ImpactBurst extends StatelessWidget {
  const _ImpactBurst();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(42, 42),
      painter: _BurstPainter(
        color: const Color(0xFFFFD5A6),
        points: 6,
      ),
    );
  }
}

class _BounceRing extends StatelessWidget {
  const _BounceRing();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 18,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.32),
          width: 1.3,
        ),
      ),
    );
  }
}

class _SleeveRibbon extends StatelessWidget {
  const _SleeveRibbon();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(58, 18),
      painter: _RibbonPainter(color: const Color(0xFFE7C89D)),
    );
  }
}

class _StarHalo extends StatelessWidget {
  const _StarHalo();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: const [
        Icon(Icons.auto_awesome_rounded, size: 18, color: Color(0xFFF4D6A2)),
        SizedBox(width: 4),
        Icon(Icons.auto_awesome_rounded, size: 12, color: Color(0xFFF4D6A2)),
      ],
    );
  }
}

class _FingerBridge extends StatelessWidget {
  const _FingerBridge();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(68, 22),
      painter: _BridgePainter(color: const Color(0xFFF0C38A)),
    );
  }
}

class _BreathHalo extends StatelessWidget {
  const _BreathHalo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 82,
      height: 82,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.24),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

class _GlanceBeam extends StatelessWidget {
  const _GlanceBeam();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(54, 16),
      painter: _BeamPainter(color: const Color(0xFFC6D7FF)),
    );
  }
}

class _ShoulderTrail extends StatelessWidget {
  const _ShoulderTrail();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(70, 24),
      painter: _TrailPainter(color: const Color(0xFFC4E2FF)),
    );
  }
}

class _SmileSlash extends StatelessWidget {
  const _SmileSlash();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 2,
          color: Colors.white.withValues(alpha: 0.2),
        ),
        const SizedBox(width: 6),
        const Icon(Icons.auto_awesome_rounded,
            size: 12, color: Color(0xFFF4D29B)),
      ],
    );
  }
}

class _HeartDustCluster extends StatelessWidget {
  const _HeartDustCluster();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 26,
      child: Stack(
        children: const [
          Positioned(
            left: 0,
            top: 8,
            child: Icon(Icons.favorite, size: 10, color: Color(0x66FFD4C0)),
          ),
          Positioned(
            left: 16,
            top: 0,
            child: Icon(Icons.favorite, size: 12, color: Color(0x88FFD4C0)),
          ),
          Positioned(
            right: 0,
            top: 10,
            child: Icon(Icons.favorite, size: 8, color: Color(0x55FFD4C0)),
          ),
        ],
      ),
    );
  }
}

class _ClothTensionAccent extends StatelessWidget {
  const _ClothTensionAccent();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(34, 14),
      painter: _TensionPainter(color: const Color(0xFFF0D3AD)),
    );
  }
}

class _EyeContactAccent extends StatelessWidget {
  const _EyeContactAccent();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 12,
      child: CustomPaint(
        painter: _EyeLinePainter(color: const Color(0x88FFFFFF)),
      ),
    );
  }
}

class _HairFlickAccent extends StatelessWidget {
  const _HairFlickAccent();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(22, 18),
      painter: _HairFlickPainter(color: const Color(0x99FFD5B2)),
    );
  }
}

class _BurstPainter extends CustomPainter {
  const _BurstPainter({
    required this.color,
    required this.points,
  });

  final Color color;
  final int points;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final center = Offset(size.width / 2, size.height / 2);
    for (var i = 0; i < points; i++) {
      final angle = (math.pi * 2 / points) * i;
      final inner = Offset(
        center.dx + math.cos(angle) * 6,
        center.dy + math.sin(angle) * 6,
      );
      final outer = Offset(
        center.dx + math.cos(angle) * 18,
        center.dy + math.sin(angle) * 18,
      );
      canvas.drawLine(inner, outer, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter oldDelegate) => false;
}

class _RibbonPainter extends CustomPainter {
  const _RibbonPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [color.withValues(alpha: 0), color.withValues(alpha: 0.92)],
      ).createShader(Offset.zero & size)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(0, size.height * 0.6)
      ..quadraticBezierTo(
        size.width * 0.38,
        0,
        size.width,
        size.height * 0.54,
      );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _RibbonPainter oldDelegate) => false;
}

class _BridgePainter extends CustomPainter {
  const _BridgePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [color.withValues(alpha: 0), color.withValues(alpha: 0.9)],
      ).createShader(Offset.zero & size)
      ..strokeWidth = 2.3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(0, size.height * 0.72)
      ..quadraticBezierTo(
        size.width * 0.5,
        0,
        size.width,
        size.height * 0.45,
      );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BridgePainter oldDelegate) => false;
}

class _TensionPainter extends CustomPainter {
  const _TensionPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.7
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 3; i++) {
      final y = 2.0 + i * 4.0;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width - i * 4.0, y + 1.5),
        paint..color = color.withValues(alpha: 0.56 - i * 0.12),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TensionPainter oldDelegate) => false;
}

class _EyeLinePainter extends CustomPainter {
  const _EyeLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          color.withValues(alpha: 0),
          color,
          color.withValues(alpha: 0),
        ],
      ).createShader(Offset.zero & size)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _EyeLinePainter oldDelegate) => false;
}

class _HairFlickPainter extends CustomPainter {
  const _HairFlickPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [color.withValues(alpha: 0), color],
      ).createShader(Offset.zero & size)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(0, size.height)
      ..quadraticBezierTo(
        size.width * 0.42,
        size.height * 0.1,
        size.width,
        0,
      );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _HairFlickPainter oldDelegate) => false;
}

class _BeamPainter extends CustomPainter {
  const _BeamPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [color.withValues(alpha: 0), color.withValues(alpha: 0.76)],
      ).createShader(Offset.zero & size)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(0, size.height * 0.7),
      Offset(size.width, size.height * 0.35),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _BeamPainter oldDelegate) => false;
}

class _TrailPainter extends CustomPainter {
  const _TrailPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [color.withValues(alpha: 0), color.withValues(alpha: 0.76)],
      ).createShader(Offset.zero & size)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(0, size.height * 0.76)
      ..quadraticBezierTo(
        size.width * 0.42,
        size.height * 0.18,
        size.width,
        size.height * 0.48,
      );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrailPainter oldDelegate) => false;
}
