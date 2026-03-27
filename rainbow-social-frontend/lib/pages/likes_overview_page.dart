import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/auth_controller.dart';
import '../models/app_user.dart';
import '../models/match_summary.dart';
import '../routes/app_router.dart';
import '../services/app_feedback.dart';
import '../theme/app_theme.dart';
import '../usecases/swipe_usecases.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';

enum LikeOverviewType {
  received,
  sent,
  mutual,
}

class LikesOverviewArgs {
  const LikesOverviewArgs({
    required this.type,
    required this.summary,
  });

  final LikeOverviewType type;
  final MatchSummary summary;
}

class LikesOverviewPage extends ConsumerStatefulWidget {
  const LikesOverviewPage({super.key, required this.args});

  final LikesOverviewArgs args;

  @override
  ConsumerState<LikesOverviewPage> createState() => _LikesOverviewPageState();
}

class _LikesOverviewPageState extends ConsumerState<LikesOverviewPage> {
  late final PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionUser = ref.watch(authControllerProvider).valueOrNull?.user;
    final config = _pageConfig(widget.args);

    if (widget.args.type == LikeOverviewType.sent) {
      return _SentLikesScaffold(config: config);
    }

    if (config.items.isEmpty) {
      return Scaffold(
        body: SafeArea(
          child: AppEmptyState(
            title: config.emptyTitle,
            subtitle: config.emptySubtitle,
          ),
        ),
      );
    }

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFCFCFF),
              Color(0xFFF6F1FF),
              Color(0xFFF7FAFF),
            ],
          ),
        ),
        child: Stack(
          children: [
            const _EtherealBackdrop(),
            SafeArea(
              child: PageView.builder(
                controller: _pageController,
                itemCount: config.items.length,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                },
                itemBuilder: (context, index) {
                  final item = config.items[index];
                  if (widget.args.type == LikeOverviewType.received) {
                    return _ReceivedLikeExperience(
                      user: item.user,
                      currentIndex: index,
                      total: config.items.length,
                      onClose: () => Navigator.of(context).pop(),
                      onReply: () => _handleReceivedLikeReply(item.user),
                      onPreview: () => Navigator.of(context)
                          .pushNamed(AppRouter.detail, arguments: item.user),
                    );
                  }

                  return _MutualLikeExperience(
                    currentUser: sessionUser,
                    user: item.user,
                    currentIndex: index,
                    total: config.items.length,
                    onChat: () => Navigator.of(context)
                        .pushNamed(AppRouter.chat, arguments: item.user),
                    onLater: () => Navigator.of(context).pop(),
                  );
                },
              ),
            ),
            if (config.items.length > 1)
              Positioned(
                bottom: 22,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(config.items.length, (index) {
                    final active = index == _currentIndex;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: active ? 18 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: active
                            ? AppTheme.primary
                            : AppTheme.primary.withValues(alpha: 0.18),
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }

  _LikePageConfig _pageConfig(LikesOverviewArgs args) {
    switch (args.type) {
      case LikeOverviewType.received:
        return _LikePageConfig(
          title: '喜欢我的',
          emptyTitle: '还没有人喜欢你',
          emptySubtitle: '有人向你表达好感后，这里会第一时间出现。',
          items: args.summary.received
              .map((item) => _LikeListItem(user: item.user))
              .toList(),
        );
      case LikeOverviewType.sent:
        return _LikePageConfig(
          title: '我喜欢的',
          emptyTitle: '你还没有点过喜欢',
          emptySubtitle: '你发出的喜欢会显示在这里。',
          items: args.summary.sent
              .map((item) => _LikeListItem(user: item.user))
              .toList(),
        );
      case LikeOverviewType.mutual:
        return _LikePageConfig(
          title: '互相喜欢',
          emptyTitle: '还没有互相喜欢',
          emptySubtitle: '互相喜欢后，这里会显示匹配记录。',
          items: args.summary.mutual
              .map((item) => _LikeListItem(user: item.user))
              .toList(),
        );
    }
  }

  Future<void> _handleReceivedLikeReply(AppUser user) async {
    final session = ref.read(authControllerProvider).valueOrNull;
    if (session == null) {
      AppFeedback.showToast('请先登录');
      return;
    }
    try {
      final result = await ref.read(likeUserUseCaseProvider)(
        session.token,
        user.id,
      );
      if (!mounted) return;
      if (result.matched) {
        Navigator.of(context).pushNamed(AppRouter.chat, arguments: user);
      } else {
        Navigator.of(context).pushNamed(AppRouter.detail, arguments: user);
      }
    } catch (error) {
      AppFeedback.showError('回应失败：$error');
    }
  }
}

class _LikePageConfig {
  const _LikePageConfig({
    required this.title,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.items,
  });

  final String title;
  final String emptyTitle;
  final String emptySubtitle;
  final List<_LikeListItem> items;
}

class _LikeListItem {
  const _LikeListItem({
    required this.user,
  });

  final AppUser user;
}

class _SentLikesScaffold extends StatelessWidget {
  const _SentLikesScaffold({required this.config});

  final _LikePageConfig config;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(config.title),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GlassCard(
                borderRadius: BorderRadius.circular(28),
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                child: Text(
                  config.title,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: config.items.isEmpty
                    ? AppEmptyState(
                        title: config.emptyTitle,
                        subtitle: config.emptySubtitle,
                      )
                    : ListView.separated(
                        itemCount: config.items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final user = config.items[index].user;
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(24),
                              onTap: () => Navigator.of(context)
                                  .pushNamed(AppRouter.detail, arguments: user),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  color: Colors.white.withValues(alpha: 0.88),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primary
                                          .withValues(alpha: 0.06),
                                      blurRadius: 16,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    AvatarWidget(
                                      imageUrl: user.avatar,
                                      isOnline: user.onlineStatus,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            user.nickname,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            user.basicsLine,
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelLarge
                                                ?.copyWith(
                                                  color: AppTheme.textSecondary,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right_rounded,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ],
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
      ),
    );
  }
}

class _ReceivedLikeExperience extends StatelessWidget {
  const _ReceivedLikeExperience({
    required this.user,
    required this.currentIndex,
    required this.total,
    required this.onClose,
    required this.onReply,
    required this.onPreview,
  });

  final AppUser user;
  final int currentIndex;
  final int total;
  final VoidCallback onClose;
  final VoidCallback onReply;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 42),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              onPressed: onClose,
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.55),
                shadowColor: AppTheme.primary.withValues(alpha: 0.08),
              ),
              icon: const Icon(Icons.close_rounded),
            ),
          ),
          const Spacer(),
          Text(
            '有人喜欢了你',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontSize: 34,
                  foreground: Paint()
                    ..shader = const LinearGradient(
                      colors: [
                        AppTheme.primary,
                        AppTheme.primaryDark,
                        AppTheme.tertiary,
                      ],
                    ).createShader(const Rect.fromLTWH(0, 0, 260, 60)),
                ),
          ),
          const SizedBox(height: 12),
          Text(
            '查看谁喜欢了你',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary.withValues(alpha: 0.82),
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 32),
          _ReceivedIdentityGlow(user: user),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: GradientButton(
              label: '回个喜欢',
              icon: Icons.favorite_rounded,
              onPressed: onReply,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onPreview,
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.64),
                foregroundColor: AppTheme.primary,
                side: BorderSide.none,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: const Text('先看看'),
            ),
          ),
          if (total > 1) ...[
            const SizedBox(height: 10),
            Text(
              '${currentIndex + 1} / $total',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppTheme.textSecondary.withValues(alpha: 0.74),
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReceivedIdentityGlow extends StatelessWidget {
  const _ReceivedIdentityGlow({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final image =
        user.photos.isNotEmpty ? user.photos.first : user.avatarOrFallback;

    return SizedBox(
      width: 320,
      height: 320,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppTheme.primary.withValues(alpha: 0.1),
                  AppTheme.secondary.withValues(alpha: 0.06),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.28),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.18),
                  blurRadius: 40,
                  spreadRadius: 6,
                ),
              ],
            ),
          ),
          Positioned(
            top: 34,
            right: 18,
            child: _FloatingBadge(
              size: 48,
              child: const Icon(
                Icons.favorite_rounded,
                color: AppTheme.tertiary,
              ),
            ),
          ),
          Positioned(
            left: 14,
            bottom: 72,
            child: _FloatingBadge(
              size: 36,
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 18,
                color: AppTheme.primary,
              ),
            ),
          ),
          GestureDetector(
            onTap: onTapHint,
            child: Container(
              width: 214,
              height: 214,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.92),
                  width: 8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.2),
                    blurRadius: 34,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: ClipOval(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(image, fit: BoxFit.cover),
                    ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                      child: Image.network(
                        image,
                        fit: BoxFit.cover,
                        color: Colors.white.withValues(alpha: 0.18),
                        colorBlendMode: BlendMode.lighten,
                      ),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            AppTheme.primary.withValues(alpha: 0.18),
                          ],
                        ),
                      ),
                    ),
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 26,
                              vertical: 13,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.52),
                              ),
                            ),
                            child: Text(
                              '点击解锁',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
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
        ],
      ),
    );
  }

  void onTapHint() {}
}

class _MutualLikeExperience extends StatelessWidget {
  const _MutualLikeExperience({
    required this.currentUser,
    required this.user,
    required this.currentIndex,
    required this.total,
    required this.onChat,
    required this.onLater,
  });

  final AppUser? currentUser;
  final AppUser user;
  final int currentIndex;
  final int total;
  final VoidCallback onChat;
  final VoidCallback onLater;

  @override
  Widget build(BuildContext context) {
    final leftAvatar = currentUser?.avatarOrFallback ?? user.avatarOrFallback;

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 46, 28, 42),
      child: Column(
        children: [
          Text(
            '互相喜欢',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            '现在你们可以开始聊天了',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary.withValues(alpha: 0.76),
                  fontWeight: FontWeight.w700,
                ),
          ),
          const Spacer(),
          _MutualConnectionVisual(
            leftAvatar: leftAvatar,
            rightAvatar: user.avatarOrFallback,
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '缘分在此刻开启',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: GradientButton(
              label: '去聊天',
              icon: Icons.send_rounded,
              onPressed: onChat,
            ),
          ),
          const SizedBox(height: 14),
          TextButton(
            onPressed: onLater,
            child: Text(
              '稍后再说',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textSecondary.withValues(alpha: 0.78),
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          if (total > 1) ...[
            const SizedBox(height: 6),
            Text(
              '${currentIndex + 1} / $total',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppTheme.textSecondary.withValues(alpha: 0.74),
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MutualConnectionVisual extends StatelessWidget {
  const _MutualConnectionVisual({
    required this.leftAvatar,
    required this.rightAvatar,
  });

  final String leftAvatar;
  final String rightAvatar;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      height: 210,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 260,
            height: 1.2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppTheme.primary.withValues(alpha: 0.36),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppTheme.primary.withValues(alpha: 0.12),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Positioned(
            left: 28,
            child: _ConnectedAvatar(
              imageUrl: leftAvatar,
              angle: -0.06,
            ),
          ),
          Positioned(
            right: 28,
            child: _ConnectedAvatar(
              imageUrl: rightAvatar,
              angle: 0.06,
            ),
          ),
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.38),
              border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.16),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: const Center(
                  child: Icon(
                    Icons.favorite_rounded,
                    size: 34,
                    color: AppTheme.primary,
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

class _ConnectedAvatar extends StatelessWidget {
  const _ConnectedAvatar({
    required this.imageUrl,
    required this.angle,
  });

  final String imageUrl;
  final double angle;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        width: 120,
        height: 120,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.16),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipOval(
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

class _FloatingBadge extends StatelessWidget {
  const _FloatingBadge({
    required this.size,
    required this.child,
  });

  final double size;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.46),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _EtherealBackdrop extends StatelessWidget {
  const _EtherealBackdrop();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -80,
            left: -80,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            right: -100,
            bottom: -90,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.secondary.withValues(alpha: 0.07),
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
            child: const SizedBox.expand(),
          ),
        ],
      ),
    );
  }
}
