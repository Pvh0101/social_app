import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../notification/presentation/screens/notification_screen.dart';

import '../../core/core.dart';
import '../posts/screens/feed_screen.dart';
import '../posts/screens/video_reels_screen.dart';
import '../friends/presentation/screens/friends_screen.dart';
import '../menu/presentation/screens/menu_screen.dart';
import '../notification/providers/notification_provider.dart';
import '../chat/providers/chat_providers.dart';

final currentScreenIndexProvider = StateProvider<int>((ref) => 0);

class HomeScreen extends ConsumerStatefulWidget {
  static const String routeName = RouteConstants.home;

  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final List<Widget> _screens = [
    const FeedScreen(),
    const VideoReelsScreen(),
    const FriendsScreen(),
    const NotificationScreen(),
    const MenuScreen(),
  ];

  void _onItemTapped(int index) {
    final currentIndex = ref.read(currentScreenIndexProvider);
    if (currentIndex == index) return;
    ref.read(currentScreenIndexProvider.notifier).state = index;
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(currentScreenIndexProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        enableFeedback: true,
        elevation: 8,
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurface,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        items: _buildNavigationItems(),
      ),
    );
  }

  List<BottomNavigationBarItem> _buildNavigationItems() {
    // Lấy số lượng thông báo chưa đọc
    final unreadNotificationsAsync =
        ref.watch(unreadNotificationsCountProvider);

    return [
      _buildItem(Icons.home_outlined, Icons.home, 'home'),
      _buildItem(CupertinoIcons.play_circle, CupertinoIcons.play_circle_fill,
          'Videos'),
      _buildItem(Icons.people_outline, Icons.people, 'People'),
      _buildItemWithBadge(
        Icons.notifications_outlined,
        Icons.notifications,
        'notifications',
        unreadNotificationsAsync.maybeWhen(
          data: (count) => count,
          orElse: () => 0,
        ),
      ),
      _buildItem(Icons.menu_outlined, Icons.menu, 'menu'),
    ];
  }

  BottomNavigationBarItem _buildItem(
      IconData icon, IconData activeIcon, String label) {
    return BottomNavigationBarItem(
      icon: Icon(icon),
      activeIcon: Icon(activeIcon),
      label: label.tr(),
    );
  }

  // Xây dựng item với badge
  BottomNavigationBarItem _buildItemWithBadge(
      IconData icon, IconData activeIcon, String label, int badgeCount) {
    return BottomNavigationBarItem(
      icon: _buildBadge(icon, badgeCount, false),
      activeIcon: _buildBadge(activeIcon, badgeCount, true),
      label: label.tr(),
    );
  }

  // Tạo badge với số lượng
  Widget _buildBadge(IconData icon, int count, bool isActive) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        if (count > 0)
          Positioned(
            right: -8,
            top: -3,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isActive
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.error,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Center(
                child: Text(
                  count > 99 ? '99+' : count.toString(),
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
