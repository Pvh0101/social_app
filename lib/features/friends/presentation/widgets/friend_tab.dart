import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/log_utils.dart';

class FriendTab extends ConsumerWidget {
  final String text;
  final int count;

  const FriendTab({
    super.key,
    required this.text,
    required this.count,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.logDebug(LogService.FRIEND,
        '[FRIEND_TAB] Xây dựng tab "$text" với số lượng: $count');

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(text,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          if (count > 0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                count.toString(),
                style: textTheme.labelMedium?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
