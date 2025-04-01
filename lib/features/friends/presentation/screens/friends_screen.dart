import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';

import '../widgets/friend_tab.dart';
import '../widgets/friends_search_bar.dart';
import '../widgets/index.dart';
import '../../../../core/utils/log_utils.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  final int? initialTabIndex;

  const FriendsScreen({
    super.key,
    this.initialTabIndex,
  });

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    ref.logDebug(
        LogService.FRIEND, '[FRIENDS_SCREEN] Khởi tạo màn hình bạn bè');

    _tabController = TabController(length: 3, vsync: this);

    // Chuyển đến tab được chỉ định nếu có
    if (widget.initialTabIndex != null) {
      ref.logDebug(LogService.FRIEND,
          '[FRIENDS_SCREEN] Chuyển đến tab ${widget.initialTabIndex}');
      _tabController.animateTo(widget.initialTabIndex!);
    }

    // Lắng nghe sự kiện thay đổi tab
    _tabController.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      ref.logDebug(LogService.FRIEND,
          '[FRIENDS_SCREEN] Chuyển đến tab ${_tabController.index}');
    }
  }

  void _toggleSearch(bool value) {
    ref.logDebug(LogService.FRIEND,
        '[FRIENDS_SCREEN] ${value ? "Bật" : "Tắt"} tìm kiếm');
    setState(() {
      _isSearching = value;
      if (!value) {
        _searchController.clear();
        _searchQuery = '';
      }
    });
  }

  void _handleSearch(String query) {
    ref.logDebug(
        LogService.FRIEND, '[FRIENDS_SCREEN] Tìm kiếm với từ khóa: "$query"');
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  // List<T> _filterSearchResults<T>(List<T> items, String Function(T) getName) {
  //   if (_searchQuery.isEmpty) return items;
  //   final filtered = items
  //       .where((item) => getName(item).toLowerCase().contains(_searchQuery))
  //       .toList();
  //   ref.logDebug(LogService.FRIEND,
  //       '[FRIENDS_SCREEN] Lọc kết quả tìm kiếm: ${items.length} -> ${filtered.length} mục');
  //   return filtered;
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            title: FriendsSearchBar(
              controller: _searchController,
              isSearching: _isSearching,
              onChanged: _handleSearch,
              onSearchToggle: _toggleSearch,
            ),
            actions: [
              IconButton(
                icon: Icon(_isSearching ? Icons.close : Icons.search),
                onPressed: () => _toggleSearch(!_isSearching),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: [
                FriendTab(
                  text: 'friends.list'.tr(),
                  count: 0,
                ),
                FriendTab(
                  text: 'friends.requests'.tr(),
                  count: 0,
                ),
                FriendTab(
                  text: 'friends.suggestions'.tr(),
                  count: 0,
                ),
              ],
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicatorPadding: EdgeInsets.zero,
            ),
            floating: true,
            snap: true,
            pinned: true,
            scrolledUnderElevation: 0,
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            FriendsList(searchQuery: _searchQuery),
            FriendRequestList(searchQuery: _searchQuery),
            FriendSuggestionList(searchQuery: _searchQuery),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    ref.logDebug(LogService.FRIEND, '[FRIENDS_SCREEN] Hủy màn hình bạn bè');
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
