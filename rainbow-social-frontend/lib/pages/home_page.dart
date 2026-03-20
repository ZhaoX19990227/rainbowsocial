import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/home_controller.dart';
import '../models/app_user.dart';
import '../routes/app_router.dart';
import '../theme/app_theme.dart';
import '../widgets/user_card.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _deckKey = GlobalKey<_SwipeDeckState>();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeControllerProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Column(
          children: [
            Row(
              children: [
                Text('推荐', style: Theme.of(context).textTheme.headlineMedium),
                const Spacer(),
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
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.surfaceHighest.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        gradient: const LinearGradient(
                          colors: [Color(0x22EA87FF), Color(0x22FF6E85)],
                        ),
                      ),
                      child: const Center(child: Text('推荐')),
                    ),
                  ),
                  const Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Text(
                          '附近',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: state.when(
                data: (users) {
                  if (users.isEmpty) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('暂时没有更多推荐了'),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => ref
                              .read(homeControllerProvider.notifier)
                              .loadRecommendations(),
                          child: const Text('重新加载'),
                        ),
                      ],
                    );
                  }
                  return _SwipeDeck(
                    key: _deckKey,
                    users: users,
                    onSwipe: _handleSwipe,
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text(error.toString())),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ActionCircle(
                  icon: Icons.close_rounded,
                  color: AppTheme.error,
                  size: 58,
                  onTap: () => _deckKey.currentState?.triggerSwipe(
                    _SwipeDecision.pass,
                  ),
                ),
                const SizedBox(width: 18),
                _ActionCircle(
                  icon: Icons.star_rounded,
                  color: AppTheme.secondary,
                  size: 52,
                  onTap: () {},
                ),
                const SizedBox(width: 18),
                _ActionCircle(
                  icon: Icons.favorite_rounded,
                  color: AppTheme.primary,
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
    );
  }

  Future<void> _handleSwipe(_SwipeDecision decision) async {
    if (decision == _SwipeDecision.like) {
      final matched =
          await ref.read(homeControllerProvider.notifier).likeTopCard();
      if (mounted && matched) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('匹配成功，快去打个招呼吧')),
        );
      }
      return;
    }
    await ref.read(homeControllerProvider.notifier).passTopCard();
  }
}

enum _SwipeDecision {
  like,
  pass,
}

class _SwipeDeck extends StatefulWidget {
  const _SwipeDeck({
    super.key,
    required this.users,
    required this.onSwipe,
  });

  final List<AppUser> users;
  final Future<void> Function(_SwipeDecision decision) onSwipe;

  @override
  State<_SwipeDeck> createState() => _SwipeDeckState();
}

class _SwipeDeckState extends State<_SwipeDeck>
    with SingleTickerProviderStateMixin {
  static const _swipeThreshold = 118.0;

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
    final width = MediaQuery.of(context).size.width;
    final target = Offset(
      decision == _SwipeDecision.like ? width * 1.2 : -width * 1.2,
      -20,
    );
    await _animateTo(target, curve: Curves.easeInCubic);
    await widget.onSwipe(decision);
    if (mounted) {
      setState(() {
        _dragOffset = Offset.zero;
        _offsetAnimation = null;
        _controller.reset();
        _isAnimating = false;
      });
    }
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
    final swipeProgress = (_effectiveOffset.dx.abs() / _swipeThreshold)
        .clamp(0.0, 1.0)
        .toDouble();

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          clipBehavior: Clip.none,
          children: List.generate(visible.length, (index) {
            final depth = visible.length - 1 - index;
            final user = visible[depth];
            final isTop = depth == 0;

            final scale = switch (depth) {
              0 => 1.0,
              1 => 0.95 + (swipeProgress * 0.03),
              _ => 0.9 + (swipeProgress * 0.02),
            };
            final topInset = switch (depth) {
              0 => 0.0,
              1 => 18.0 - (swipeProgress * 12),
              _ => 32.0 - (swipeProgress * 14),
            };
            final sideInset = switch (depth) {
              0 => 0.0,
              1 => 8.0 - (swipeProgress * 5),
              _ => 16.0 - (swipeProgress * 8),
            };

            Widget card = UserCard(
              user: user,
              overlayBuilder: isTop
                  ? (context) => _SwipeOverlay(
                        dx: _effectiveOffset.dx,
                        progress: swipeProgress,
                      )
                  : null,
              onTap: isTop && !_isAnimating && _effectiveOffset.distance < 10
                  ? () => Navigator.of(context)
                      .pushNamed(AppRouter.detail, arguments: user)
                  : null,
            );

            if (isTop) {
              card = GestureDetector(
                onPanStart: (_) {
                  if (_isAnimating) return;
                  _offsetAnimation = null;
                  _controller.stop();
                },
                onPanUpdate: (details) {
                  if (_isAnimating) return;
                  setState(() {
                    _dragOffset += details.delta;
                  });
                },
                onPanEnd: (details) async {
                  if (_isAnimating) return;
                  final velocity = details.velocity.pixelsPerSecond.dx;
                  final shouldLike =
                      _effectiveOffset.dx > _swipeThreshold || velocity > 900;
                  final shouldPass =
                      _effectiveOffset.dx < -_swipeThreshold || velocity < -900;

                  if (shouldLike) {
                    await triggerSwipe(_SwipeDecision.like);
                    return;
                  }
                  if (shouldPass) {
                    await triggerSwipe(_SwipeDecision.pass);
                    return;
                  }

                  await _animateTo(Offset.zero);
                  if (mounted) {
                    setState(() {
                      _dragOffset = Offset.zero;
                      _offsetAnimation = null;
                      _controller.reset();
                      _isAnimating = false;
                    });
                  }
                },
                child: Transform.translate(
                  offset: _effectiveOffset,
                  child: Transform.rotate(
                    angle: (_effectiveOffset.dx / constraints.maxWidth) * 0.18,
                    child: card,
                  ),
                ),
              );
            }

            return Positioned.fill(
              top: topInset,
              left: sideInset,
              right: sideInset,
              child: Transform.scale(
                scale: scale,
                alignment: Alignment.topCenter,
                child: IgnorePointer(
                  ignoring: !isTop,
                  child: card,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _SwipeOverlay extends StatelessWidget {
  const _SwipeOverlay({
    required this.dx,
    required this.progress,
  });

  final double dx;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final showLike = dx > 0;
    final opacity = (progress * 1.1).clamp(0.0, 1.0);

    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: 30,
            left: showLike ? null : 24,
            right: showLike ? 24 : null,
            child: Transform.rotate(
              angle: showLike ? 0.18 : -0.18,
              child: Opacity(
                opacity: opacity,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: (showLike ? AppTheme.primary : AppTheme.error)
                        .withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: showLike ? AppTheme.primary : AppTheme.error,
                      width: 1.6,
                    ),
                  ),
                  child: Text(
                    showLike ? '喜欢' : '略过',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: showLike ? AppTheme.primary : AppTheme.error,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCircle extends StatefulWidget {
  const _ActionCircle({
    required this.icon,
    required this.color,
    required this.size,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback onTap;
  final bool filled;

  @override
  State<_ActionCircle> createState() => _ActionCircleState();
}

class _ActionCircleState extends State<_ActionCircle> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.filled ? null : AppTheme.surfaceHighest,
            gradient: widget.filled
                ? const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.primaryDark],
                  )
                : null,
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.25),
                blurRadius: _pressed ? 10 : 18,
              ),
            ],
          ),
          child: Icon(
            widget.icon,
            color: widget.filled ? const Color(0xFF400050) : widget.color,
          ),
        ),
      ),
    );
  }
}
