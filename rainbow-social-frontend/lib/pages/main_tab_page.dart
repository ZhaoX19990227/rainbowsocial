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
  final Set<int> _visitedTabs = {0};

  void _switchTab(int value) {
    if (_index == value) return;
    setState(() {
      _index = value;
      _visitedTabs.add(value);
    });
  }

  Widget _buildPage(int index) {
    if (!_visitedTabs.contains(index)) {
      return const SizedBox.shrink();
    }
    switch (index) {
      case 0:
        return const HomePage();
      case 1:
        return NearbyPage(onSwitchToRecommendations: () => _switchTab(0));
      case 2:
        return const ChatListPage();
      case 3:
        return const ProfilePage();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LuminousBackground(
        child: IndexedStack(
          index: _index,
          children: List.generate(4, _buildPage),
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _index,
        onTap: _switchTab,
      ),
    );
  }
}
