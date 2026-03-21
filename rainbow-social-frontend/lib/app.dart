import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'routes/app_router.dart';
import 'services/app_feedback.dart';
import 'theme/app_theme.dart';

class RainbowSocialApp extends StatelessWidget {
  const RainbowSocialApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '彩虹社交',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: AppFeedback.messengerKey,
      locale: const Locale('zh', 'CN'),
      supportedLocales: const [
        Locale('zh', 'CN'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.darkTheme,
      onGenerateRoute: AppRouter.onGenerateRoute,
      initialRoute: AppRouter.splash,
    );
  }
}
