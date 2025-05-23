import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/routes_constants.dart';
import '../../../../core/screens/error_screen.dart';
import '../../../../core/widgets/display_user_image.dart';
import '../../../authentication/providers/get_user_info_as_stream_by_id_provider.dart';

class ChatTitle extends ConsumerWidget {
  final String userId;
  final bool? isOnline;
  final double? avatarRadius;

  final VoidCallback? onButtonPressed; // Callback cho nút mới

  const ChatTitle({
    super.key,
    required this.userId,
    this.isOnline,
    this.avatarRadius,
    this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userData = ref.watch(getUserInfoAsStreamByIdProvider(userId));

    return userData.when(
      data: (user) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  RouteConstants.userProfile,
                  arguments: userId,
                );
              },
              child: DisplayUserImage(
                imageUrl: user.profileImage,
                userName: user.fullName,
                isOnline: user.isOnline,
                radius: avatarRadius ?? 22,
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  RouteConstants.userProfile,
                  arguments: userId,
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    user.fullName,
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.lastSeenText,
                    style: Theme.of(context).textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ],
        );
      },
      error: (error, stackTrace) {
        return ErrorScreen(error: error.toString());
      },
      loading: () {
        return const SizedBox.shrink();
      },
    );
  }
}
