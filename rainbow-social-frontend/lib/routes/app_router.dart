import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../pages/chat_page.dart';
import '../pages/edit_profile_page.dart';
import '../pages/flirty_action_design_page.dart';
import '../pages/birthday_setup_page.dart';
import '../pages/horoscope_detail_page.dart';
import '../pages/likes_overview_page.dart';
import '../pages/login_page.dart';
import '../pages/main_tab_page.dart';
import '../pages/mbti_test_page.dart';
import '../pages/splash_page.dart';
import '../pages/user_detail_page.dart';

class AppRouter {
  static const splash = '/';
  static const login = '/login';
  static const main = '/main';
  static const chat = '/chat';
  static const detail = '/detail';
  static const editProfile = '/edit-profile';
  static const likesOverview = '/likes-overview';
  static const flirtyDesign = '/flirty-design';
  static const mbtiTest = '/mbti-test';
  static const birthdaySetup = '/birthday-setup';
  static const horoscopeDetail = '/horoscope-detail';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashPage());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case main:
        return MaterialPageRoute(builder: (_) => const MainTabPage());
      case chat:
        return MaterialPageRoute(
          builder: (_) => ChatPage(peer: settings.arguments! as AppUser),
        );
      case detail:
        return MaterialPageRoute(
          builder: (_) => UserDetailPage(user: settings.arguments! as AppUser),
        );
      case editProfile:
        return MaterialPageRoute(builder: (_) => const EditProfilePage());
      case likesOverview:
        return MaterialPageRoute(
          builder: (_) =>
              LikesOverviewPage(args: settings.arguments! as LikesOverviewArgs),
        );
      case flirtyDesign:
        return MaterialPageRoute(
          builder: (_) => const FlirtyActionDesignPage(),
        );
      case mbtiTest:
        return MaterialPageRoute(
          builder: (_) => const MbtiTestPage(),
        );
      case birthdaySetup:
        return MaterialPageRoute(
          builder: (_) => const BirthdaySetupPage(),
        );
      case horoscopeDetail:
        return MaterialPageRoute(
          builder: (_) => const HoroscopeDetailPage(),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('页面不存在')),
          ),
        );
    }
  }
}
