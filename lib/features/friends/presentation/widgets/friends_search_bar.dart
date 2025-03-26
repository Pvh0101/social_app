import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/log_utils.dart';

class FriendsSearchBar extends ConsumerWidget {
  final TextEditingController controller;
  final bool isSearching;
  final Function(bool) onSearchToggle;
  final Function(String) onChanged;

  const FriendsSearchBar({
    super.key,
    required this.controller,
    required this.isSearching,
    required this.onSearchToggle,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.logDebug(LogService.FRIEND,
        '[FRIENDS_SEARCH_BAR] Xây dựng thanh tìm kiếm, trạng thái tìm kiếm: $isSearching');

    if (!isSearching) {
      return const Text('Bạn bè');
    }

    return TextField(
      controller: controller,
      onChanged: (value) {
        ref.logDebug(LogService.FRIEND,
            '[FRIENDS_SEARCH_BAR] Nhập từ khóa tìm kiếm: "$value"');
        onChanged(value);
      },
      autofocus: true,
      decoration: const InputDecoration(
        hintText: 'Tìm kiếm bạn bè...',
        border: InputBorder.none,
      ),
    );
  }
}
