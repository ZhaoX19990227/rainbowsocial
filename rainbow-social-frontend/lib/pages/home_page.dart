import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/home_controller.dart';
import '../models/app_user.dart';
import '../routes/app_router.dart';
import '../services/app_feedback.dart';
import '../services/relationship_copy.dart';
import '../theme/app_theme.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_skeleton.dart';
import '../widgets/user_card.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({
    super.key,
    this.onSwitchToNearby,
  });

  final VoidCallback? onSwitchToNearby;

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _deckKey = GlobalKey<_SwipeDeckState>();
  AppUser? _matchUser;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeControllerProvider);
    final controller = ref.read(homeControllerProvider.notifier);

    return Stack(
      children: [
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              children: [
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '推荐',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '往下翻，看看今天会和谁对上眼',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    AnimatedOpacity(
                      opacity: controller.canUndo ? 1 : 0.45,
                      duration: const Duration(milliseconds: 180),
                      child: IconButton(
                        onPressed: controller.canUndo ? _undoLastSwipe : null,
                        icon: const Icon(
                          Icons.undo_rounded,
                          color: AppTheme.secondary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => ref
                          .read(homeControllerProvider.notifier)
                          .loadRecommendations(),
                      icon: const Icon(
                        Icons.refresh_rounded,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => ref
                              .read(homeControllerProvider.notifier)
                              .loadRecommendations(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0x33F2D8FF),
                                  Color(0x33FFD9E6),
                                ],
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '推荐',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(color: AppTheme.textPrimary),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: widget.onSwitchToNearby,
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Center(
                              child: Text(
                                '附近',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(color: AppTheme.textSecondary),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _MbtiEntryCard(
                        onTap: () =>
                            Navigator.of(context).pushNamed(AppRouter.mbtiTest),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _HoroscopeEntryCard(
                        onTap: () => Navigator.of(context)
                            .pushNamed(AppRouter.birthdaySetup),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: state.when(
                    data: (users) {
                      if (users.isEmpty) {
                        return AppEmptyState(
                          title: '暂时没有更多推荐了',
                          subtitle: '可以稍后再来，或者刷新看看有没有新的心动对象。',
                          action: TextButton(
                            onPressed: () => ref
                                .read(homeControllerProvider.notifier)
                                .loadRecommendations(),
                            child: const Text('重新加载'),
                          ),
                        );
                      }
                      return _SwipeDeck(
                        key: _deckKey,
                        users: users,
                        onSwipe: _handleSwipe,
                        onCardTap: (user) => Navigator.of(context)
                            .pushNamed(AppRouter.detail, arguments: user),
                      );
                    },
                    loading: () => const _HomeSkeleton(),
                    error: (error, _) => AppEmptyState(
                      title: '推荐页加载失败',
                      subtitle: '$error',
                      action: TextButton(
                        onPressed: () => ref
                            .read(homeControllerProvider.notifier)
                            .loadRecommendations(),
                        child: const Text('重新加载'),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ActionCircle(
                      icon: Icons.undo_rounded,
                      color: AppTheme.secondary,
                      size: 52,
                      onTap: controller.canUndo ? _undoLastSwipe : null,
                    ),
                    const SizedBox(width: 14),
                    _ActionCircle(
                      icon: Icons.close_rounded,
                      color: AppTheme.error,
                      size: 58,
                      onTap: () => _deckKey.currentState?.triggerSwipe(
                        _SwipeDecision.pass,
                      ),
                    ),
                    const SizedBox(width: 14),
                    _ActionCircle(
                      icon: Icons.star_rounded,
                      color: AppTheme.secondary,
                      size: 54,
                      onTap: () => _deckKey.currentState?.triggerSwipe(
                        _SwipeDecision.superLike,
                      ),
                    ),
                    const SizedBox(width: 14),
                    _ActionCircle(
                      icon: Icons.favorite_rounded,
                      color: const Color(0xFFB874F6),
                      size: 60,
                      filled: true,
                      onTap: () => _deckKey.currentState?.triggerSwipe(
                        _SwipeDecision.like,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
              ],
            ),
          ),
        ),
        IgnorePointer(
          ignoring: _matchUser == null,
          child: AnimatedOpacity(
            opacity: _matchUser == null ? 0 : 1,
            duration: const Duration(milliseconds: 260),
            child: _matchUser == null
                ? const SizedBox.shrink()
                : _MatchOverlay(
                    user: _matchUser!,
                    onClose: () => setState(() => _matchUser = null),
                    onChat: () {
                      final user = _matchUser!;
                      setState(() => _matchUser = null);
                      Navigator.of(context)
                          .pushNamed(AppRouter.chat, arguments: user);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleSwipe(_SwipeDecision decision) async {
    HomeSwipeResult? result;
    if (decision == _SwipeDecision.pass) {
      result = await ref.read(homeControllerProvider.notifier).passTopCard();
    } else {
      result = await ref.read(homeControllerProvider.notifier).likeTopCard(
            isSuperLike: decision == _SwipeDecision.superLike,
          );
      if (decision == _SwipeDecision.superLike) {
        AppFeedback.showToast('已送出超级喜欢');
      }
    }

    if (!mounted || result == null) return;
    setState(() {});
    if (result.matched) {
      final matchedUser = result.user;
      setState(() => _matchUser = matchedUser);
      return;
    }
    if (decision == _SwipeDecision.superLike) {
      AppFeedback.showToast(RelationshipCopy.superLikeSent(result.user.nickname));
    } else if (decision == _SwipeDecision.like) {
      AppFeedback.showToast(RelationshipCopy.likeSent(result.user.nickname));
    }
  }

  Future<void> _undoLastSwipe() async {
    try {
      final restored =
          await ref.read(homeControllerProvider.notifier).undoLastSwipe();
      if (!mounted || restored == null) return;
      AppFeedback.showToast('已撤销上一张');
      setState(() {});
    } catch (error) {
      AppFeedback.showError('撤销失败：$error');
    }
  }
}

class _MbtiEntryCard extends StatelessWidget {
  const _MbtiEntryCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(32),
      child: Ink(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFFFFF),
              Color(0xFFF8F0FF),
            ],
          ),
          border: Border.all(color: AppTheme.ghostBorder),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.08),
              blurRadius: 28,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: -20,
              right: -14,
              child: Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [Color(0x22B47BFF), Color(0x00B47BFF)],
                  ),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [AppTheme.primary, AppTheme.primaryDark],
                    ),
                  ),
                  child: const Icon(
                    Icons.psychology_alt_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '发现你的隐藏人格',
                  maxLines: 2,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        height: 1.2,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '完善人格档案',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
              ],
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HoroscopeEntryCard extends StatelessWidget {
  const _HoroscopeEntryCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(32),
      child: Ink(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFFFFF),
              Color(0xFFF3F7FF),
            ],
          ),
          border: Border.all(color: AppTheme.ghostBorder),
          boxShadow: [
            BoxShadow(
              color: AppTheme.secondary.withValues(alpha: 0.08),
              blurRadius: 28,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: -18,
              left: -12,
              child: Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [Color(0x227DDCFF), Color(0x007DDCFF)],
                  ),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4AA5FD), Color(0xFF6E7CFF)],
                    ),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '查看今日运势',
                  maxLines: 2,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        height: 1.2,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '解锁星座档案',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
              ],
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _SwipeDecision {
  like,
  pass,
  superLike,
}

class _SwipeDeck extends StatefulWidget {
  const _SwipeDeck({
    super.key,
    required this.users,
    required this.onSwipe,
    required this.onCardTap,
  });

  final List<AppUser> users;
  final Future<void> Function(_SwipeDecision decision) onSwipe;
  final ValueChanged<AppUser> onCardTap;

  @override
  State<_SwipeDeck> createState() => _SwipeDeckState();
}

class _SwipeDeckState extends State<_SwipeDeck>
    with SingleTickerProviderStateMixin {
  static const _horizontalThreshold = 118.0;
  static const _verticalThreshold = 138.0;

  late final AnimationController _controller;
  Animation<Offset>? _offsetAnimation;
  Offset _dragOffset = Offset.zero;
  bool _isAnimating = false;

  Offset get _effectiveOffset => _offsetAnimation?.value ?? _dragOffset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    )..addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(covariant _SwipeDeck oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.users.isNotEmpty &&
        widget.users.isNotEmpty &&
        oldWidget.users.first.id != widget.users.first.id) {
      _dragOffset = Offset.zero;
      _offsetAnimation = null;
      _controller.reset();
      _isAnimating = false;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> triggerSwipe(_SwipeDecision decision) async {
    if (_isAnimating || widget.users.isEmpty) return;
    final size = MediaQuery.of(context).size;
    final target = switch (decision) {
      _SwipeDecision.like => Offset(size.width * 1.2, -20),
      _SwipeDecision.pass => Offset(-size.width * 1.2, -20),
      _SwipeDecision.superLike => Offset(0, -size.height * 0.95),
    };
    await _animateTo(target, curve: Curves.easeInCubic);
    await widget.onSwipe(decision);
    if (!mounted) return;
    setState(() {
      _dragOffset = Offset.zero;
      _offsetAnimation = null;
      _controller.reset();
      _isAnimating = false;
    });
  }

  Future<void> _animateTo(
    Offset target, {
    Curve curve = Curves.easeOutCubic,
  }) async {
    _offsetAnimation = Tween<Offset>(
      begin: _effectiveOffset,
      end: target,
    ).animate(CurvedAnimation(parent: _controller, curve: curve));
    _isAnimating = true;
    _controller.reset();
    await _controller.forward().orCancel;
  }

  @override
  Widget build(BuildContext context) {
    final visible = widget.users.take(3).toList();
    final dxProgress = (_effectiveOffset.dx.abs() / _horizontalThreshold)
        .clamp(0.0, 1.0)
        .toDouble();
    final upProgress = ((_effectiveOffset.dy * -1) / _verticalThreshold)
        .clamp(0.0, 1.0)
        .toDouble();

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            for (int index = visible.length - 1; index >= 0; index--)
              _buildCard(
                context,
                constraints,
                visible[index],
                index,
                dxProgress: dxProgress,
                upProgress: upProgress,
              ),
          ],
        );
      },
    );
  }

  Widget _buildCard(
    BuildContext context,
    BoxConstraints constraints,
    AppUser user,
    int index, {
    required double dxProgress,
    required double upProgress,
  }) {
    final isTop = index == 0;
    final depth = index.toDouble();
    final scale = isTop ? 1.0 : 1.0 - (depth * 0.035);
    final topOffset = isTop ? 0.0 : 10 + (depth * 6);

    Widget child = Positioned.fill(
      top: topOffset,
      child: Transform.scale(
        scale: scale,
        alignment: Alignment.topCenter,
        child: Opacity(
          opacity: isTop ? 1 : 0.5 - (depth * 0.08),
          child: UserCard(
            user: user,
            onTap: () => widget.onCardTap(user),
            overlayBuilder: isTop
                ? (_) => _SwipeOverlay(
                      likeOpacity: _effectiveOffset.dx > 0 ? dxProgress : 0,
                      passOpacity: _effectiveOffset.dx < 0 ? dxProgress : 0,
                      superLikeOpacity:
                          _effectiveOffset.dy < 0 ? upProgress : 0,
                    )
                : null,
          ),
        ),
      ),
    );

    if (!isTop) return child;

    final rotation = (_effectiveOffset.dx / constraints.maxWidth) * 0.18;

    child = Positioned.fill(
      child: Transform.translate(
        offset: _effectiveOffset,
        child: Transform.rotate(
          angle: rotation,
          child: child,
        ),
      ),
    );

    return GestureDetector(
      onPanUpdate: (details) {
        if (_isAnimating) return;
        setState(() {
          _dragOffset += details.delta;
        });
      },
      onPanEnd: (_) async {
        if (_isAnimating) return;
        final decision = _decisionForCurrentOffset();
        if (decision != null) {
          await triggerSwipe(decision);
          return;
        }
        await _animateTo(Offset.zero);
        if (!mounted) return;
        setState(() {
          _dragOffset = Offset.zero;
          _offsetAnimation = null;
          _controller.reset();
          _isAnimating = false;
        });
      },
      child: child,
    );
  }

  _SwipeDecision? _decisionForCurrentOffset() {
    if (_effectiveOffset.dy <= -_verticalThreshold &&
        _effectiveOffset.dx.abs() < _horizontalThreshold) {
      return _SwipeDecision.superLike;
    }
    if (_effectiveOffset.dx >= _horizontalThreshold) {
      return _SwipeDecision.like;
    }
    if (_effectiveOffset.dx <= -_horizontalThreshold) {
      return _SwipeDecision.pass;
    }
    return null;
  }
}

class _SwipeOverlay extends StatelessWidget {
  const _SwipeOverlay({
    required this.likeOpacity,
    required this.passOpacity,
    required this.superLikeOpacity,
  });

  final double likeOpacity;
  final double passOpacity;
  final double superLikeOpacity;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: 20,
          top: 28,
          child: Opacity(
            opacity: passOpacity,
            child: _Badge(
              label: '略过',
              color: AppTheme.error,
              angle: -0.22,
            ),
          ),
        ),
        Positioned(
          right: 20,
          top: 28,
          child: Opacity(
            opacity: likeOpacity,
            child: _Badge(
              label: '喜欢',
              color: AppTheme.primary,
              angle: 0.16,
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 52,
          child: Opacity(
            opacity: superLikeOpacity,
            child: const Center(
              child: _Badge(
                label: '超级喜欢',
                color: AppTheme.secondary,
                angle: 0,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.color,
    required this.angle,
  });

  final String label;
  final Color color;
  final double angle;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.85), width: 2),
          color: Colors.black.withValues(alpha: 0.18),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
        ),
      ),
    );
  }
}

class _ActionCircle extends StatelessWidget {
  const _ActionCircle({
    required this.icon,
    required this.color,
    required this.size,
    this.filled = false,
    this.onTap,
  });

  final IconData icon;
  final Color color;
  final double size;
  final bool filled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: onTap == null ? 0.94 : 1,
      duration: const Duration(milliseconds: 180),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: filled
                ? LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.94),
                      const Color(0xFFE7C5FF),
                    ],
                  )
                : null,
            color: filled
                ? null
                : AppTheme.surfaceHighest.withValues(
                    alpha: onTap == null ? 0.34 : 0.96,
                  ),
            border: Border.all(color: color.withValues(alpha: 0.22)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: filled ? 0.32 : 0.12),
                blurRadius: 20,
              ),
            ],
          ),
          child: Icon(
            icon,
            color: filled ? const Color(0xFF7F2ED1) : color,
          ),
        ),
      ),
    );
  }
}

class _MatchOverlay extends StatefulWidget {
  const _MatchOverlay({
    required this.user,
    required this.onClose,
    required this.onChat,
  });

  final AppUser user;
  final VoidCallback onClose;
  final VoidCallback onChat;

  @override
  State<_MatchOverlay> createState() => _MatchOverlayState();
}

class _MatchOverlayState extends State<_MatchOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = widget.user.photos.isNotEmpty
        ? widget.user.photos.first
        : widget.user.avatarOrFallback;

    return Material(
      color: Colors.white.withValues(alpha: 0.92),
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.1, -0.28),
                radius: 1.08,
                colors: [
                  AppTheme.primary.withValues(alpha: 0.12),
                  AppTheme.secondary.withValues(alpha: 0.08),
                  const Color(0xFFF8F9FE),
                ],
              ),
            ),
          ),
          Positioned(
            top: 104,
            left: -32,
            child: _SoftGlow(
              size: 220,
              color: AppTheme.primary.withValues(alpha: 0.12),
            ),
          ),
          Positioned(
            bottom: 120,
            right: -24,
            child: _SoftGlow(
              size: 200,
              color: AppTheme.secondary.withValues(alpha: 0.1),
            ),
          ),
          Center(
            child: ScaleTransition(
              scale: CurvedAnimation(
                parent: _controller,
                curve: Curves.elasticOut,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '互相喜欢',
                      style:
                          Theme.of(context).textTheme.headlineLarge?.copyWith(
                                fontSize: 40,
                                color: AppTheme.textPrimary,
                              ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '现在你们可以开始聊天了',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 34),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _controller,
                          builder: (context, child) {
                            return Container(
                              width: 220 + (_controller.value * 12),
                              height: 220 + (_controller.value * 12),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppTheme.primary.withValues(alpha: 0.1),
                                ),
                              ),
                            );
                          },
                        ),
                        Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                AppTheme.primary.withValues(alpha: 0.16),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        Transform.translate(
                          offset: const Offset(-44, 0),
                          child: Container(
                            width: 112,
                            height: 112,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primary.withValues(alpha: 0.12),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFFFFF2C8),
                                  Color(0xFFFFE0B5),
                                ],
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '你',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(color: AppTheme.textPrimary),
                              ),
                            ),
                          ),
                        ),
                        Transform.translate(
                          offset: const Offset(44, 0),
                          child: Hero(
                            tag: 'match-avatar-${widget.user.id}',
                            child: Container(
                              width: 112,
                              height: 112,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primary.withValues(alpha: 0.12),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                                image: DecorationImage(
                                  image: NetworkImage(avatarUrl),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.88),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withValues(alpha: 0.14),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.favorite_rounded,
                            color: AppTheme.primary,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 34),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '缘分在此刻开启',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: AppTheme.primary,
                            ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    Container(
                      width: double.infinity,
                      height: 58,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        gradient: const LinearGradient(
                          colors: [AppTheme.primary, AppTheme.primaryDark],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.24),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: widget.onChat,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '去聊天',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(color: Colors.white),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.send_rounded, color: Colors.white),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: widget.onClose,
                      child: Text(
                        '稍后再说',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftGlow extends StatelessWidget {
  const _SoftGlow({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                top: 24,
                child: AppSkeleton(height: double.infinity, radius: 30),
              ),
              Positioned.fill(
                top: 12,
                left: 8,
                right: 8,
                child: AppSkeleton(height: double.infinity, radius: 30),
              ),
              Positioned.fill(
                child: AppSkeleton(height: double.infinity, radius: 30),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
