import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../models/notification_model.dart';
import '../../providers/notification_provider.dart';
import '../../repository/notification_repository.dart';
import '../widgets/notification_item.dart';
import '../../../../core/utils/global_method.dart';
import '../../../../core/services/notification_navigation_service.dart';

/// Màn hình hiển thị danh sách thông báo
class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final repository = ref.watch(notificationRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'notification.title'.tr(),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz),
            onPressed: () => _showNotificationOptions(context, repository),
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'notification.empty'.tr(),
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(notificationsProvider);
            },
            child: ListView.builder(
              itemCount: notifications.length + 1, // +1 for header
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildNotificationHeader(context, repository);
                }

                final notification = notifications[index - 1];
                return NotificationItem(
                  notification: notification,
                  onTap: () =>
                      _handleNotificationTap(context, notification, ref),
                );
              },
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Text('${'common.error'.tr()}: $error'),
        ),
      ),
    );
  }

  Widget _buildNotificationHeader(
      BuildContext context, NotificationRepository repository) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'notification.new'.tr(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextButton(
            onPressed: () async {
              try {
                await repository.markAllAsRead();
                if (context.mounted) {
                  showToastMessage(
                      text: 'notification.actions.mark_read_success'.tr());
                }
              } catch (e) {
                if (context.mounted) {
                  showToastMessage(text: '${'common.error'.tr()}: $e');
                }
              }
            },
            child: Text('notification.mark_all_read'.tr()),
          ),
        ],
      ),
    );
  }

  void _showNotificationOptions(
      BuildContext context, NotificationRepository repository) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.done_all),
            title: Text('notification.mark_all_read'.tr()),
            onTap: () async {
              Navigator.pop(context);
              try {
                await repository.markAllAsRead();
                if (context.mounted) {
                  showToastMessage(
                      text: 'notification.actions.mark_read_success'.tr());
                }
              } catch (e) {
                if (context.mounted) {
                  showToastMessage(text: '${'common.error'.tr()}: $e');
                }
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_sweep),
            title: Text('notification.options.delete_all'.tr()),
            onTap: () {
              Navigator.pop(context);
              _deleteAll(context, repository);
            },
          ),
        ],
      ),
    );
  }

  /// Xử lý khi nhấn vào thông báo
  void _handleNotificationTap(
      BuildContext context, NotificationModel notification, WidgetRef ref) {
    NotificationNavigationService.handleNotificationNavigation(
      context,
      notification.type,
      postId: notification.postId,
      chatId: notification.chatId,
      senderId: notification.senderId,
      notificationId: notification.id,
      ref: ref,
    );
  }

  /// Xóa tất cả thông báo
  Future<void> _deleteAll(
      BuildContext context, NotificationRepository repository) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('common.confirm'.tr()),
            content: Text('notification.options.delete_all_confirm'.tr()),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('common.cancel'.tr()),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('common.delete'.tr(),
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            ],
          ),
        ) ??
        false;

    if (confirmed) {
      try {
        await repository.deleteAllNotifications();
        if (context.mounted) {
          showToastMessage(
              text: 'notification.actions.delete_all_success'.tr());
        }
      } catch (e) {
        if (context.mounted) {
          showToastMessage(text: '${'common.error'.tr()}: $e');
        }
      }
    }
  }
}
