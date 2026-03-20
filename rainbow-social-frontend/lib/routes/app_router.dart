import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../pages/chat_page.dart';
import '../pages/edit_profile_page.dart';
import '../pages/login_page.dart';
import '../pages/main_tab_page.dart';
import '../pages/splash_page.dart';
import '../pages/user_detail_page.dart';

class AppRouter {
  static const splash = '/';
  static const login = '/login';
  static const main = '/main';
  static const chat = '/chat';
  static const detail = '/detail';
  static const editProfile = '/edit-profile';

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
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('页面不存在')),
          ),
        );
    }
  }
}
