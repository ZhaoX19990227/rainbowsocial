import 'package:flutter/material.dart';

import '../widgets/app_bottom_nav.dart';
import '../widgets/luminous_background.dart';
import 'chat_list_page.dart';
import 'home_page.dart';
import 'nearby_page.dart';
import 'profile_page.dart';

class MainTabPage extends StatefulWidget {
  const MainTabPage({super.key});

  @override
  State<MainTabPage> createState() => _MainTabPageState();
}

class _MainTabPageState extends State<MainTabPage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(onSwitchToNearby: () => setState(() => _index = 1)),
      NearbyPage(onSwitchToRecommendations: () => setState(() => _index = 0)),
      const ChatListPage(),
      const ProfilePage(),
    ];

    return Scaffold(
      body: LuminousBackground(
        child: IndexedStack(index: _index, children: pages),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _index,
        onTap: (value) => setState(() => _index = value),
      ),
    );
  }
}
