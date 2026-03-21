import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/flirty_action.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

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
      duration: const Duration(milliseconds: 2200),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final stageWidth = math.min(screenWidth - 28, 380.0).toDouble();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final entry = Curves.easeOutCubic.transform(
          (_controller.value / 0.28).clamp(0.0, 1.0),
        );
        final exit = Curves.easeInCubic.transform(
          ((_controller.value - 0.72) / 0.28).clamp(0.0, 1.0),
        );
        final sceneProgress = Curves.easeInOutSine.transform(
          ((_controller.value - 0.08) / 0.72).clamp(0.0, 1.0),
        );
        final opacity = (entry * (1 - exit)).clamp(0.0, 1.0);
        final stageLift = (1 - entry) * 34 - (exit * 10);
        final stageScale = lerpDouble(0.94, 1.0, entry)! * (1 - exit * 0.04);

        return IgnorePointer(
          child: Opacity(
            opacity: opacity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 22 * entry,
                    sigmaY: 22 * entry,
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.46 * opacity),
                      gradient: RadialGradient(
                        center: const Alignment(0, -0.1),
                        radius: 1.05,
                        colors: [
                          action.gradient.first.withValues(alpha: 0.20 * opacity),
                          const Color(0xE7090B12).withValues(alpha: opacity),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: _SceneParticles(
                      progress: sceneProgress,
                      colors: action.gradient,
                    ),
                  ),
                ),
                Center(
                  child: Transform.translate(
                    offset: Offset(0, stageLift),
                    child: Transform.scale(
                      scale: stageScale,
                      child: SizedBox(
                        width: stageWidth,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: GlassCard(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                            borderRadius: BorderRadius.circular(34),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 7,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(999),
                                        color: Colors.white.withValues(alpha: 0.06),
                                        border: Border.all(
                                          color: action.gradient.first
                                              .withValues(alpha: 0.24),
                                        ),
                                      ),
                                      child: Text(
                                        widget.data.isMine ? '你主动出招' : '对方先撩一步',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelMedium
                                            ?.copyWith(
                                              color: Colors.white
                                                  .withValues(alpha: 0.80),
                                              letterSpacing: 0.3,
                                            ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: [
                                            action.gradient.first
                                                .withValues(alpha: 0.85),
                                            action.gradient.last
                                                .withValues(alpha: 0.70),
                                          ],
                                        ),
                                      ),
                                      child: Icon(
                                        action.icon,
                                        size: 18,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                _StageSpotlight(
                                  colors: action.gradient,
                                  child: _FlirtyDuoScene(
                                    action: action,
                                    progress: sceneProgress,
                                    compact: false,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  action.stageTitle,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        fontSize: 28,
                                        color: Colors.white,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  widget.data.preview,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        color: Colors.white
                                            .withValues(alpha: 0.94),
                                        height: 1.4,
                                      ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  action.stageSubtitle,
                                  textAlign: TextAlign.center,
                                  style:
                                      Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: AppTheme.textSecondary
                                                .withValues(alpha: 0.92),
                                            height: 1.45,
                                          ),
                                ),
                                const SizedBox(height: 14),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(18),
                                    color: Colors.white.withValues(alpha: 0.04),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.06),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          action.motionNotes,
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelMedium
                                              ?.copyWith(
                                                color: Colors.white
                                                    .withValues(alpha: 0.82),
                                                letterSpacing: 0.15,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Icon(
                                        Icons.vibration_rounded,
                                        size: 16,
                                        color:
                                            action.gradient.first.withValues(alpha: 0.9),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
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
      duration: const Duration(milliseconds: 1600),
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
      borderRadius: BorderRadius.circular(22),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final pulse = 1 + math.sin(_controller.value * math.pi * 2) * 0.015;
          return Transform.scale(scale: pulse, child: child);
        },
        child: Container(
          constraints: const BoxConstraints(maxWidth: 274),
          padding: const EdgeInsets.all(1.2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                action.gradient.first.withValues(alpha: 0.88),
                action.gradient.last.withValues(alpha: 0.66),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: action.gradient.first.withValues(alpha: 0.18),
                blurRadius: 22,
                spreadRadius: 1,
              ),
            ],
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(21),
              color: const Color(0xCC10131B),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 13),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              action.icon,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              action.label,
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.90),
                                    letterSpacing: 0.2,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          size: 18,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      height: 104,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            action.gradient.first.withValues(alpha: 0.18),
                            const Color(0x22141A26),
                          ],
                        ),
                      ),
                      child: _FlirtyDuoScene(
                        action: action,
                        progress: _controller.value,
                        compact: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.messagePreview,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.94),
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    action.hint,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppTheme.textSecondary.withValues(alpha: 0.9),
                          letterSpacing: 0.15,
                        ),
                  ),
                ],
              ),
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
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 14,
        right: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 14,
      ),
      child: GlassCard(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        borderRadius: BorderRadius.circular(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0x44D56A55), Color(0x446278D8)],
                    ),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'XiongHou 暧昧动作',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '像一次关系升级，不像发了个表情。',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 428,
              child: GridView.builder(
                itemCount: FlirtyAction.all.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.78,
                ),
                itemBuilder: (context, index) {
                  final action = FlirtyAction.all[index];
                  return AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      final start = 0.08 * index;
                      final progress = Curves.easeOutCubic.transform(
                        ((_controller.value - start) / 0.42).clamp(0.0, 1.0),
                      );
                      return Transform.translate(
                        offset: Offset(0, (1 - progress) * 18),
                        child: Opacity(opacity: progress, child: child),
                      );
                    },
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () => Navigator.of(context).pop(action),
                      child: Container(
                        padding: const EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              action.gradient.first.withValues(alpha: 0.78),
                              action.gradient.last.withValues(alpha: 0.54),
                            ],
                          ),
                        ),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(23),
                            color: const Color(0xDA11141C),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
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
                                        color: Colors.white.withValues(alpha: 0.06),
                                      ),
                                      child: Icon(
                                        action.icon,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const Spacer(),
                                    Icon(
                                      Icons.north_east_rounded,
                                      size: 15,
                                      color:
                                          Colors.white.withValues(alpha: 0.42),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    height: 82,
                                    width: double.infinity,
                                    color: Colors.white.withValues(alpha: 0.02),
                                    child: _FlirtyDuoScene(
                                      action: action,
                                      progress: (_controller.value + index * 0.12) % 1,
                                      compact: true,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  action.label,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontSize: 15,
                                      ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  action.hint,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                        color: AppTheme.textSecondary
                                            .withValues(alpha: 0.88),
                                        letterSpacing: 0.15,
                                      ),
                                ),
                                const Spacer(),
                                Text(
                                  action.motionNotes,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                        color: Colors.white.withValues(alpha: 0.72),
                                        letterSpacing: 0.1,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StageSpotlight extends StatelessWidget {
  const _StageSpotlight({
    required this.colors,
    required this.child,
  });

  final List<Color> colors;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 248,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: RadialGradient(
          center: const Alignment(0, -0.2),
          radius: 1.1,
          colors: [
            colors.first.withValues(alpha: 0.18),
            const Color(0xFF10131C),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            left: 46,
            right: 46,
            top: 18,
            height: 88,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 18,
            right: 18,
            bottom: 18,
            height: 42,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.05),
                    colors.first.withValues(alpha: 0.18),
                    Colors.white.withValues(alpha: 0.04),
                  ],
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _SceneParticles extends StatelessWidget {
  const _SceneParticles({
    required this.progress,
    required this.colors,
  });

  final double progress;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Stack(
      children: List.generate(12, (index) {
        final seed = index / 12;
        final radius = 110 + index * 18.0 + progress * 32;
        final angle = seed * math.pi * 2 + progress * 0.8;
        final dx = size.width / 2 + math.cos(angle) * radius;
        final dy = size.height * 0.43 + math.sin(angle * 1.3) * radius * 0.28;
        return Positioned(
          left: dx,
          top: dy,
          child: Opacity(
            opacity: (0.18 + math.sin(progress * math.pi * 2 + index) * 0.08)
                .clamp(0.0, 0.28),
            child: Container(
              width: 6 + (index % 3) * 3,
              height: 6 + (index % 3) * 3,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (index.isEven ? colors.first : colors.last)
                    .withValues(alpha: 0.65),
                boxShadow: [
                  BoxShadow(
                    color: (index.isEven ? colors.first : colors.last)
                        .withValues(alpha: 0.32),
                    blurRadius: 14,
                  ),
                ],
              ),
            ),
          ),
        );
      }),
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
    final loop = compact
        ? Curves.easeInOutSine.transform(progress)
        : Curves.easeInOutCubic.transform(progress);
    final motion = _buildMotion(action.id, loop);
    final stageHeight = compact ? 104.0 : 248.0;
    final chibiScale = compact ? 0.62 : 1.0;

    return SizedBox(
      height: stageHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: motion.accentOffset.dx,
            top: motion.accentOffset.dy,
            child: Opacity(
              opacity: motion.accentOpacity,
              child: Transform.scale(
                scale: compact ? 0.74 : 1,
                child: motion.accent,
              ),
            ),
          ),
          Positioned(
            left: motion.left.dx,
            top: motion.left.dy,
            child: Transform.rotate(
              angle: motion.leftPose.rotation,
              child: Transform.scale(
                scale: motion.leftPose.scale * chibiScale,
                child: _ChibiBoy(
                  proactive: true,
                  faceRight: true,
                  expression: motion.leftPose.expression,
                  handReach: motion.leftPose.handReach,
                  handLift: motion.leftPose.handLift,
                  headTilt: motion.leftPose.headTilt,
                  bodyLean: motion.leftPose.bodyLean,
                  blush: motion.leftPose.blush,
                ),
              ),
            ),
          ),
          Positioned(
            left: motion.right.dx,
            top: motion.right.dy,
            child: Transform.rotate(
              angle: motion.rightPose.rotation,
              child: Transform.scale(
                scale: motion.rightPose.scale * chibiScale,
                child: _ChibiBoy(
                  proactive: false,
                  faceRight: false,
                  expression: motion.rightPose.expression,
                  handReach: motion.rightPose.handReach,
                  handLift: motion.rightPose.handLift,
                  headTilt: motion.rightPose.headTilt,
                  bodyLean: motion.rightPose.bodyLean,
                  blush: motion.rightPose.blush,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  _SceneMotion _buildMotion(String id, double t) {
    final float = math.sin(t * math.pi * 2) * 4;
    switch (id) {
      case 'poke_butt':
        final poke = Curves.easeOutBack.transform((t * 1.15).clamp(0.0, 1.0));
        final bounce = math.sin(t * math.pi * 3).abs() * 12;
        return _SceneMotion(
          left: Offset(44 + poke * 24, 88 + float),
          right: Offset(168, 70 - bounce),
          leftPose: _ActorPose(
            scale: 1.0,
            rotation: -0.08,
            expression: _ChibiExpression.smirk,
            handReach: 0.78,
            handLift: 0.24,
            headTilt: -0.12,
            bodyLean: 0.20,
            blush: 0.16,
          ),
          rightPose: _ActorPose(
            scale: 1.0,
            rotation: 0.06,
            expression: _ChibiExpression.surprised,
            handReach: 0.12,
            handLift: 0.64,
            headTilt: 0.18,
            bodyLean: -0.18,
            blush: 0.34,
          ),
          accent: const Icon(Icons.touch_app_rounded, color: Colors.white, size: 30),
          accentOffset: Offset(158 + poke * 14, 122 - bounce * 0.35),
          accentOpacity: 0.34 + poke * 0.38,
        );
      case 'tug_sleeve':
        final tug = math.sin(t * math.pi).abs();
        return _SceneMotion(
          left: Offset(54 + tug * 18, 86 + float),
          right: Offset(170 - tug * 8, 84 - tug * 10),
          leftPose: _ActorPose(
            scale: 0.98,
            rotation: -0.04,
            expression: _ChibiExpression.gentle,
            handReach: 0.66,
            handLift: 0.36,
            headTilt: -0.08,
            bodyLean: 0.10,
            blush: 0.18,
          ),
          rightPose: _ActorPose(
            scale: 1.0,
            rotation: 0.03,
            expression: _ChibiExpression.shy,
            handReach: 0.18,
            handLift: 0.22,
            headTilt: 0.16,
            bodyLean: -0.10,
            blush: 0.42,
          ),
          accent: Container(
            width: 54,
            height: 12,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.06),
                  Colors.white.withValues(alpha: 0.42),
                ],
              ),
            ),
          ),
          accentOffset: Offset(132 + tug * 12, 142),
          accentOpacity: 0.24 + tug * 0.45,
        );
      case 'pat_head':
        final pat = math.sin(t * math.pi * 1.5).abs();
        return _SceneMotion(
          left: Offset(62, 80 + float),
          right: Offset(172, 86 - pat * 8),
          leftPose: _ActorPose(
            scale: 1.02,
            rotation: -0.03,
            expression: _ChibiExpression.gentle,
            handReach: 0.60,
            handLift: 0.88,
            headTilt: -0.04,
            bodyLean: 0.04,
            blush: 0.12,
          ),
          rightPose: _ActorPose(
            scale: 0.98,
            rotation: 0.04,
            expression: _ChibiExpression.softSmile,
            handReach: 0.08,
            handLift: 0.28,
            headTilt: 0.14,
            bodyLean: -0.08,
            blush: 0.34,
          ),
          accent: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.auto_awesome_rounded, color: Color(0xFFF4D29B), size: 18),
              SizedBox(width: 6),
              Icon(Icons.auto_awesome_rounded, color: Color(0xFFF4D29B), size: 14),
            ],
          ),
          accentOffset: Offset(174, 72 - pat * 10),
          accentOpacity: 0.22 + pat * 0.58,
        );
      case 'hook_finger':
        final hold = math.sin(t * math.pi).abs();
        return _SceneMotion(
          left: Offset(62 + hold * 6, 84 + float),
          right: Offset(166 - hold * 6, 84 + float * 0.5),
          leftPose: _ActorPose(
            scale: 1.0,
            rotation: -0.02,
            expression: _ChibiExpression.smirk,
            handReach: 0.72,
            handLift: 0.34,
            headTilt: -0.10,
            bodyLean: 0.10,
            blush: 0.18,
          ),
          rightPose: _ActorPose(
            scale: 1.0,
            rotation: 0.02,
            expression: _ChibiExpression.shy,
            handReach: 0.56,
            handLift: 0.28,
            headTilt: 0.10,
            bodyLean: -0.02,
            blush: 0.44,
          ),
          accent: CustomPaint(
            size: const Size(58, 18),
            painter: _LinkPainter(color: const Color(0xFFE5BD82)),
          ),
          accentOffset: const Offset(136, 144),
          accentOpacity: 0.34 + hold * 0.4,
        );
      case 'lean_closer':
        final lean = Curves.easeOutSine.transform(t);
        return _SceneMotion(
          left: Offset(74 + lean * 20, 80 + float),
          right: Offset(170 - lean * 18, 84 - float * 0.3),
          leftPose: _ActorPose(
            scale: 1.04,
            rotation: -0.01,
            expression: _ChibiExpression.smirk,
            handReach: 0.42,
            handLift: 0.20,
            headTilt: -0.08,
            bodyLean: 0.22,
            blush: 0.18,
          ),
          rightPose: _ActorPose(
            scale: 1.0,
            rotation: 0.01,
            expression: _ChibiExpression.flustered,
            handReach: 0.16,
            handLift: 0.36,
            headTilt: 0.12,
            bodyLean: -0.12,
            blush: 0.42,
          ),
          accent: Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.26),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          accentOffset: const Offset(132, 76),
          accentOpacity: 0.20 + lean * 0.42,
        );
      case 'sneak_glance':
        final glance = math.sin(t * math.pi * 2);
        return _SceneMotion(
          left: Offset(66, 88 + float),
          right: Offset(172, 86),
          leftPose: _ActorPose(
            scale: 1.0,
            rotation: -0.02,
            expression: glance > 0 ? _ChibiExpression.glance : _ChibiExpression.softSmile,
            handReach: 0.18,
            handLift: 0.20,
            headTilt: -0.12,
            bodyLean: 0.02,
            blush: 0.14,
          ),
          rightPose: _ActorPose(
            scale: 1.0,
            rotation: 0.02,
            expression: glance > 0.25
                ? _ChibiExpression.surprised
                : _ChibiExpression.shy,
            handReach: 0.16,
            handLift: 0.28,
            headTilt: 0.14,
            bodyLean: -0.02,
            blush: 0.36,
          ),
          accent: Icon(
            Icons.remove_red_eye_rounded,
            color: const Color(0xFFB9C8FF).withValues(alpha: 0.88),
            size: 28,
          ),
          accentOffset: Offset(132 + glance * 12, 94),
          accentOpacity: 0.22 + glance.abs() * 0.46,
        );
      case 'brush_shoulder':
        final brush = math.sin(t * math.pi).abs();
        return _SceneMotion(
          left: Offset(78 + brush * 18, 90 + float * 0.2),
          right: Offset(150 - brush * 12, 92 - brush * 4),
          leftPose: _ActorPose(
            scale: 1.0,
            rotation: -0.01,
            expression: _ChibiExpression.softSmile,
            handReach: 0.20,
            handLift: 0.18,
            headTilt: -0.06,
            bodyLean: 0.18,
            blush: 0.18,
          ),
          rightPose: _ActorPose(
            scale: 1.0,
            rotation: 0.01,
            expression: _ChibiExpression.flustered,
            handReach: 0.18,
            handLift: 0.24,
            headTilt: 0.08,
            bodyLean: -0.04,
            blush: 0.34,
          ),
          accent: CustomPaint(
            size: const Size(64, 24),
            painter: _TrailPainter(color: const Color(0xFFC9E0FF)),
          ),
          accentOffset: const Offset(136, 128),
          accentOpacity: 0.24 + brush * 0.44,
        );
      case 'naughty_smile':
      default:
        final smug = math.sin(t * math.pi).abs();
        return _SceneMotion(
          left: Offset(72, 86 + float),
          right: Offset(176, 88),
          leftPose: _ActorPose(
            scale: 1.02,
            rotation: -0.02,
            expression: _ChibiExpression.smirk,
            handReach: 0.16,
            handLift: 0.16,
            headTilt: -0.14,
            bodyLean: 0.05,
            blush: 0.18,
          ),
          rightPose: _ActorPose(
            scale: 1.0,
            rotation: 0.02,
            expression: smug > 0.45
                ? _ChibiExpression.flustered
                : _ChibiExpression.shy,
            handReach: 0.10,
            handLift: 0.30,
            headTilt: 0.12,
            bodyLean: -0.04,
            blush: 0.40,
          ),
          accent: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                color: const Color(0xFFF4D29B).withValues(alpha: 0.9),
                size: 14,
              ),
              const SizedBox(width: 6),
              Container(
                width: 36,
                height: 2,
                color: Colors.white.withValues(alpha: 0.22),
              ),
            ],
          ),
          accentOffset: const Offset(148, 98),
          accentOpacity: 0.18 + smug * 0.38,
        );
    }
  }
}

class _SceneMotion {
  const _SceneMotion({
    required this.left,
    required this.right,
    required this.leftPose,
    required this.rightPose,
    required this.accent,
    required this.accentOffset,
    required this.accentOpacity,
  });

  final Offset left;
  final Offset right;
  final _ActorPose leftPose;
  final _ActorPose rightPose;
  final Widget accent;
  final Offset accentOffset;
  final double accentOpacity;
}

class _ActorPose {
  const _ActorPose({
    required this.scale,
    required this.rotation,
    required this.expression,
    required this.handReach,
    required this.handLift,
    required this.headTilt,
    required this.bodyLean,
    required this.blush,
  });

  final double scale;
  final double rotation;
  final _ChibiExpression expression;
  final double handReach;
  final double handLift;
  final double headTilt;
  final double bodyLean;
  final double blush;
}

enum _ChibiExpression {
  gentle,
  glance,
  flustered,
  shy,
  smirk,
  softSmile,
  surprised,
}

class _ChibiBoy extends StatelessWidget {
  const _ChibiBoy({
    required this.proactive,
    required this.faceRight,
    required this.expression,
    required this.handReach,
    required this.handLift,
    required this.headTilt,
    required this.bodyLean,
    required this.blush,
  });

  final bool proactive;
  final bool faceRight;
  final _ChibiExpression expression;
  final double handReach;
  final double handLift;
  final double headTilt;
  final double bodyLean;
  final double blush;

  @override
  Widget build(BuildContext context) {
    final hair = proactive
        ? const [Color(0xFF6A4338), Color(0xFF27131D)]
        : const [Color(0xFF405A87), Color(0xFF18213B)];
    final outfit = proactive
        ? const [Color(0xFF8A394C), Color(0xFF441B2A)]
        : const [Color(0xFF315D8E), Color(0xFF1A2946)];

    final leftArmAngle = lerpDouble(-0.6, 0.35, handLift)! + bodyLean * 0.35;
    final rightArmAngle = lerpDouble(0.6, -0.55, handReach)! - bodyLean * 0.25;
    final bodyRotation = bodyLean * 0.12;

    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..scale(faceRight ? 1.0 : -1.0, 1.0),
      child: SizedBox(
        width: 116,
        height: 154,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 24,
              right: 24,
              bottom: 4,
              height: 14,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: Colors.black.withValues(alpha: 0.24),
                ),
              ),
            ),
            Positioned(
              left: 28,
              bottom: 8,
              child: _Limb(angle: -0.10, color: outfit.last, height: 36),
            ),
            Positioned(
              right: 28,
              bottom: 8,
              child: _Limb(angle: 0.10, color: outfit.last, height: 36),
            ),
            Positioned(
              left: 8,
              top: 74,
              child: _Limb(
                angle: leftArmAngle,
                color: outfit.first,
                height: 42,
                width: 14,
              ),
            ),
            Positioned(
              right: 10 - handReach * 10,
              top: 72 - handLift * 8,
              child: _Limb(
                angle: rightArmAngle,
                color: outfit.first,
                height: 48,
                width: 14,
              ),
            ),
            Positioned(
              left: 24,
              top: 64,
              child: Transform.rotate(
                angle: bodyRotation,
                child: Container(
                  width: 68,
                  height: 70,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: outfit,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: outfit.first.withValues(alpha: 0.18),
                        blurRadius: 18,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        left: 12,
                        right: 12,
                        top: 10,
                        height: 20,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 24,
                        right: 24,
                        top: 0,
                        height: 18,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: const Color(0xFFF5D7C8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 20,
              top: 14,
              child: Transform.rotate(
                angle: headTilt,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: 6,
                      top: 10,
                      child: Container(
                        width: 72,
                        height: 68,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF6D8C9),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 1,
                      top: 0,
                      child: Container(
                        width: 82,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(34),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: hair,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: proactive ? 8 : 16,
                      top: 30,
                      child: Container(
                        width: proactive ? 54 : 50,
                        height: 22,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: hair.last.withValues(alpha: 0.92),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 18,
                      top: 22,
                      child: Container(
                        width: 16,
                        height: 18,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: hair.first,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 18,
                      top: proactive ? 24 : 20,
                      child: Container(
                        width: 18,
                        height: 20,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: hair.first,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 17,
                      top: 32,
                      child: CustomPaint(
                        size: const Size(52, 28),
                        painter: _FacePainter(
                          expression: expression,
                          blush: blush,
                          proactive: proactive,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
    final eye = Paint()
      ..color = const Color(0xFF2F2330)
      ..strokeWidth = 3.1
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final blushPaint = Paint()
      ..color = const Color(0xFFEFA6A6).withValues(alpha: 0.28 + blush * 0.36)
      ..style = PaintingStyle.fill;
    final mouthPaint = Paint()
      ..color = proactive ? const Color(0xFF7A3C49) : const Color(0xFF74435A)
      ..strokeWidth = 2.3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final leftEye = Offset(size.width * 0.30, size.height * 0.40);
    final rightEye = Offset(size.width * 0.70, size.height * 0.40);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(size.width * 0.18, size.height * 0.58), width: 10, height: 7),
      blushPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(size.width * 0.82, size.height * 0.58), width: 10, height: 7),
      blushPaint,
    );

    switch (expression) {
      case _ChibiExpression.smirk:
        canvas.drawLine(leftEye + const Offset(-3, 0), leftEye + const Offset(3, -1.4), eye);
        canvas.drawLine(rightEye + const Offset(-3, -1.4), rightEye + const Offset(3, 0.8), eye);
        final path = Path()
          ..moveTo(size.width * 0.42, size.height * 0.73)
          ..quadraticBezierTo(
            size.width * 0.55,
            size.height * 0.80,
            size.width * 0.68,
            size.height * 0.68,
          );
        canvas.drawPath(path, mouthPaint);
        break;
      case _ChibiExpression.shy:
        canvas.drawLine(leftEye + const Offset(-3, 0), leftEye + const Offset(3, 0), eye);
        canvas.drawLine(rightEye + const Offset(-3, 0), rightEye + const Offset(3, 0), eye);
        final path = Path()
          ..moveTo(size.width * 0.45, size.height * 0.72)
          ..quadraticBezierTo(
            size.width * 0.52,
            size.height * 0.80,
            size.width * 0.60,
            size.height * 0.72,
          );
        canvas.drawPath(path, mouthPaint);
        break;
      case _ChibiExpression.gentle:
      case _ChibiExpression.softSmile:
        canvas.drawLine(leftEye + const Offset(-3, 0), leftEye + const Offset(3, -0.8), eye);
        canvas.drawLine(rightEye + const Offset(-3, -0.8), rightEye + const Offset(3, 0), eye);
        final path = Path()
          ..moveTo(size.width * 0.42, size.height * 0.71)
          ..quadraticBezierTo(
            size.width * 0.52,
            size.height * 0.80,
            size.width * 0.62,
            size.height * 0.71,
          );
        canvas.drawPath(path, mouthPaint);
        break;
      case _ChibiExpression.surprised:
        canvas.drawCircle(leftEye, 2.6, eye..style = PaintingStyle.fill);
        canvas.drawCircle(rightEye, 2.6, eye);
        canvas.drawCircle(
          Offset(size.width * 0.52, size.height * 0.73),
          3.6,
          mouthPaint..style = PaintingStyle.fill,
        );
        break;
      case _ChibiExpression.glance:
        canvas.drawLine(leftEye + const Offset(-4, 0), leftEye + const Offset(2, -0.8), eye);
        canvas.drawLine(rightEye + const Offset(-2, 0.6), rightEye + const Offset(4, -0.8), eye);
        canvas.drawLine(
          Offset(size.width * 0.45, size.height * 0.73),
          Offset(size.width * 0.58, size.height * 0.71),
          mouthPaint,
        );
        break;
      case _ChibiExpression.flustered:
        canvas.drawLine(leftEye + const Offset(-3, -0.6), leftEye + const Offset(3, 0.4), eye);
        canvas.drawLine(rightEye + const Offset(-3, 0.4), rightEye + const Offset(3, -0.6), eye);
        final path = Path()
          ..moveTo(size.width * 0.44, size.height * 0.71)
          ..quadraticBezierTo(
            size.width * 0.50,
            size.height * 0.83,
            size.width * 0.60,
            size.height * 0.72,
          );
        canvas.drawPath(path, mouthPaint);
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

class _LinkPainter extends CustomPainter {
  const _LinkPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [color.withValues(alpha: 0), color.withValues(alpha: 0.92)],
      ).createShader(Offset.zero & size)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(0, size.height * 0.65)
      ..quadraticBezierTo(
        size.width * 0.48,
        size.height * 0.0,
        size.width,
        size.height * 0.45,
      );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LinkPainter oldDelegate) => false;
}

class _TrailPainter extends CustomPainter {
  const _TrailPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [color.withValues(alpha: 0), color.withValues(alpha: 0.75)],
      ).createShader(Offset.zero & size)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(0, size.height * 0.70)
      ..quadraticBezierTo(
        size.width * 0.44,
        size.height * 0.18,
        size.width,
        size.height * 0.48,
      );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrailPainter oldDelegate) => false;
}
