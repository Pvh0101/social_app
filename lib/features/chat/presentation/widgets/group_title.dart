import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/routes_constants.dart';
import '../../../../core/widgets/display_user_image.dart';
import '../../providers/chat_providers.dart';

class GroupTitle extends ConsumerWidget {
  final String chatId;
  final double? avatarRadius;
  final VoidCallback? onButtonPressed;

  const GroupTitle({
    super.key,
    required this.chatId,
    this.avatarRadius,
    this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatAsync = ref.watch(chatProvider(chatId));

    return chatAsync.when(
      data: (chat) {
        if (chat == null) {
          return Text('chat.not_exist'.tr());
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  RouteConstants.chatInfo,
                  arguments: chatId,
                );
              },
              child: DisplayUserImage(
                imageUrl: chat.avatar,
                userName: chat.name ?? 'chat.group.default_name'.tr(),
                isOnline: false, // Nhóm chat không có trạng thái online
                radius: avatarRadius ?? 22,
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  RouteConstants.chatInfo,
                  arguments: chatId,
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    chat.name ?? 'chat.group.default_name'.tr(),
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${chat.members.length} ${'chat.group.members'.tr()}',
                    style: Theme.of(context).textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  RouteConstants.chatInfo,
                  arguments: chatId,
                );
              },
              icon: const Icon(Icons.more_vert),
            ),
          ],
        );
      },
      error: (error, stackTrace) {
        return Text('${'common.error'.tr()}: $error',
            style: const TextStyle(color: Colors.red));
      },
      loading: () {
        return Row(
          children: [
            const CircularProgressIndicator(strokeWidth: 2),
            const SizedBox(width: 12),
            Text('common.loading'.tr(),
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        );
      },
    );
  }
}
