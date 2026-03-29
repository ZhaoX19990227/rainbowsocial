import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/auth_controller.dart';
import '../models/auth_session.dart';
import '../models/match_summary.dart';
import '../providers/app_providers.dart';
import '../services/app_feedback.dart';
import '../usecases/match_usecases.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/luminous_background.dart';
import 'chat_list_page.dart';
import 'home_page.dart';
import 'nearby_page.dart';
import 'profile_page.dart';

class MainTabPage extends ConsumerStatefulWidget {
  const MainTabPage({super.key});

  @override
  ConsumerState<MainTabPage> createState() => _MainTabPageState();
}

class _MainTabPageState extends ConsumerState<MainTabPage> {
  int _index = 0;
  final Set<int> _visitedTabs = {0};
  Timer? _matchAlertTimer;
  bool _checkingMatchAlerts = false;
  bool _showingMatchDialog = false;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_syncMatchAlerts);
    _matchAlertTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => _syncMatchAlerts(silentWhenBusy: true),
    );
  }

  @override
  void dispose() {
    _matchAlertTimer?.cancel();
    super.dispose();
  }

  void _switchTab(int value) {
    if (_index == value) return;
    setState(() {
      _index = value;
      _visitedTabs.add(value);
    });
  }

  Future<void> _syncMatchAlerts({bool silentWhenBusy = false}) async {
    if (_checkingMatchAlerts || (!mounted && silentWhenBusy)) return;
    final session = ref.read(authControllerProvider).valueOrNull;
    if (session == null) return;

    _checkingMatchAlerts = true;
    try {
      final summary =
          await ref.read(getMatchSummaryUseCaseProvider)(session.token);
      await _showNewRelationshipAlerts(session, summary,
          silentWhenBusy: silentWhenBusy);
    } catch (_) {
      // Keep the app usable if alerts fail to refresh.
    } finally {
      _checkingMatchAlerts = false;
    }
  }

  Future<void> _showNewRelationshipAlerts(
    AuthSession session,
    MatchSummary summary, {
    required bool silentWhenBusy,
  }) async {
    final store = ref.read(matchAlertStateServiceProvider);
    final seenReceivedAt = await store.loadLastReceivedAt(session.user.id);
    final seenMutualAt = await store.loadLastMutualAt(session.user.id);
    final latestReceived = _latestReceivedAt(summary);
    final latestMutual = _latestMutualAt(summary);

    final newReceivedCount = summary.received.where((item) {
      if (seenReceivedAt == null) return true;
      return item.likedAt.isAfter(seenReceivedAt);
    }).length;
    final newMutualCount = summary.mutual.where((item) {
      if (seenMutualAt == null) return true;
      return item.matchedAt.isAfter(seenMutualAt);
    }).length;

    if (_showingMatchDialog && silentWhenBusy) {
      return;
    }

    if (latestReceived != null) {
      await store.saveLastReceivedAt(session.user.id, latestReceived);
    }
    if (latestMutual != null) {
      await store.saveLastMutualAt(session.user.id, latestMutual);
    }

    if (newMutualCount > 0 && mounted) {
      _showingMatchDialog = true;
      AppFeedback.showRelationshipToast(
        title: newMutualCount > 1 ? '有 $newMutualCount 个新的互相喜欢' : '你们互相喜欢了',
        subtitle: newMutualCount > 1
            ? '刚刚有几段双向心动成立了，去看看是谁回应了你。'
            : '${summary.mutual.first.user.nickname} 和你已经可以开始聊天了。',
      );
      _showingMatchDialog = false;
    }

    if (newReceivedCount > 0 && mounted) {
      _showingMatchDialog = true;
      AppFeedback.showRelationshipToast(
        title: newReceivedCount > 1 ? '有 $newReceivedCount 个新喜欢' : '有人喜欢了你',
        subtitle: newReceivedCount > 1
            ? '这段时间有几个人向你表达了好感，去看看是谁在靠近。'
            : '${summary.received.first.user.nickname} 喜欢了你，回个喜欢就能聊天。',
      );
      _showingMatchDialog = false;
    }
  }

  DateTime? _latestReceivedAt(MatchSummary summary) {
    if (summary.received.isEmpty) return null;
    return summary.received
        .map((item) => item.likedAt)
        .reduce((left, right) => left.isAfter(right) ? left : right);
  }

  DateTime? _latestMutualAt(MatchSummary summary) {
    if (summary.mutual.isEmpty) return null;
    return summary.mutual
        .map((item) => item.matchedAt)
        .reduce((left, right) => left.isAfter(right) ? left : right);
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
        return ChatListPage(onDiscoverFriends: () => _switchTab(0));
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
