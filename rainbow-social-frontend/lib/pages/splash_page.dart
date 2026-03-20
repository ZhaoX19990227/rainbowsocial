import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/auth_controller.dart';
import '../routes/app_router.dart';
import '../theme/app_theme.dart';
import '../widgets/luminous_background.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  bool _navigated = false;
  ProviderSubscription<AsyncValue>? _subscription;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() {
      _subscription = ref.listenManual<AsyncValue>(
        authControllerProvider,
        (previous, next) {
          _routeIfReady(next);
        },
      );
      _routeIfReady(ref.read(authControllerProvider));
    });
  }

  void _routeIfReady(AsyncValue state) {
    if (!mounted || _navigated || state.isLoading) {
      return;
    }
    _navigated = true;
    Navigator.of(context).pushReplacementNamed(
      state.valueOrNull == null ? AppRouter.login : AppRouter.main,
    );
  }

  @override
  void dispose() {
    _subscription?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LuminousBackground(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.tertiary],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.4),
                      blurRadius: 35,
                    ),
                  ],
                ),
                child: const Icon(Icons.favorite_rounded,
                    size: 42, color: Color(0xFF400050)),
              ),
              const SizedBox(height: 28),
              Text('彩虹社交', style: Theme.of(context).textTheme.displayLarge),
              const SizedBox(height: 10),
              Text(
                '为现代 LGBTQ+ 社交打造的沉浸式连接体验。',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
