import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/notification_provider.dart';

/// Widget hiển thị số lượng thông báo chưa đọc
class NotificationBadge extends ConsumerWidget {
  final Widget child;
  final double badgeSize;
  final Color badgeColor;
  final Color textColor;
  final EdgeInsets padding;

  const NotificationBadge({
    Key? key,
    required this.child,
    this.badgeSize = 20,
    this.badgeColor = Colors.red,
    this.textColor = Colors.white,
    this.padding = const EdgeInsets.only(left: 12, top: 0),
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCountAsync = ref.watch(unreadNotificationsCountProvider);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        unreadCountAsync.when(
          data: (count) {
            if (count <= 0) return const SizedBox.shrink();

            return Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: padding,
                child: Container(
                  width: badgeSize,
                  height: badgeSize,
                  decoration: BoxDecoration(
                    color: badgeColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      count > 9 ? '9+' : count.toString(),
                      style: TextStyle(
                        color: textColor,
                        fontSize: badgeSize * 0.6,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}
