import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../models/notification_model.dart';
import '../../providers/notification_provider.dart';
import '../../../../core/utils/global_method.dart';
import '../../../../core/widgets/display_user_image.dart';
import '../../../../core/constants/routes_constants.dart';
import '../../../../features/authentication/providers/get_user_info_as_stream_by_id_provider.dart';

class NotificationItem extends ConsumerWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const NotificationItem({
    Key? key,
    required this.notification,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(notificationRepositoryProvider);

    // Sử dụng StreamProvider để lấy thông tin mới nhất của người gửi
    // nhưng chỉ khi cần hiển thị trạng thái online
    final senderStream =
        ref.watch(getUserInfoAsStreamByIdProvider(notification.senderId));

    return GestureDetector(
      onLongPress: () => _showNotificationOptions(context, ref),
      child: InkWell(
        onTap: () async {
          if (!notification.isRead) {
            await repository.markAsRead(notification.id);
          }
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.only(left: 16, right: 0, top: 8, bottom: 8),
          color: notification.isRead
              ? Theme.of(context).scaffoldBackgroundColor
              : Theme.of(context).colorScheme.primary.withAlpha(70),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pushNamed(
                    RouteConstants.profile,
                    arguments: notification.senderId,
                  );
                },
                child: senderStream.when(
                  // Khi có dữ liệu mới nhất, hiển thị với trạng thái online
                  data: (sender) => DisplayUserImage(
                    imageUrl: sender.profileImage, // Sử dụng avatar mới nhất
                    radius: 32,
                    isOnline: sender.isOnline, // Hiển thị trạng thái online
                  ),
                  // Khi đang tải hoặc có lỗi, sử dụng thông tin từ thông báo
                  loading: () => DisplayUserImage(
                    imageUrl: notification.senderAvatar,
                    radius: 32,
                    isOnline: false,
                  ),
                  error: (_, __) => DisplayUserImage(
                    imageUrl: notification.senderAvatar,
                    radius: 32,
                    isOnline: false,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: Theme.of(context).textTheme.bodyMedium,
                              children: [
                                // Sử dụng tên từ stream nếu có, nếu không thì dùng tên từ thông báo
                                TextSpan(
                                  text: senderStream.maybeWhen(
                                    data: (sender) => sender.fullName,
                                    orElse: () =>
                                        notification.senderName ??
                                        'common.unknown_user'.tr(),
                                  ),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                TextSpan(
                                  text:
                                      ' ${notification.type.getTemplateMessageText()}',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          notification.createdAtText,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.more_horiz,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                onPressed: () => _showNotificationOptions(context, ref),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(
                  minWidth: 24,
                  minHeight: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNotificationOptions(BuildContext context, WidgetRef ref) {
    final repository = ref.read(notificationRepositoryProvider);

    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(
              Icons.remove_circle_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              'notification.options.delete'.tr(),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            onTap: () async {
              Navigator.pop(context);
              try {
                await repository.deleteNotification(notification.id);
                if (context.mounted) {
                  showToastMessage(
                      text: 'notification.actions.delete_success'.tr());
                }
              } catch (e) {
                if (context.mounted) {
                  showToastMessage(
                    text:
                        '${'notification.actions.delete_error_prefix'.tr()}$e',
                  );
                }
              }
            },
          ),
          if (!notification.isRead)
            ListTile(
              leading: Icon(
                Icons.done,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(
                'notification.options.mark_read'.tr(),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              onTap: () async {
                Navigator.pop(context);
                try {
                  await repository.markAsRead(notification.id);
                  if (context.mounted) {
                    showToastMessage(
                        text: 'notification.actions.mark_read_success'.tr());
                  }
                } catch (e) {
                  if (context.mounted) {
                    showToastMessage(
                      text:
                          '${'notification.actions.mark_read_error_prefix'.tr()}$e',
                    );
                  }
                }
              },
            ),
        ],
      ),
    );
  }
}
