import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/utils/datetime_helper.dart';
import '../../../core/utils/global_method.dart';
import '../../../core/widgets/display_user_image.dart';
import '../../authentication/providers/get_user_info_by_id_provider.dart';
import '../../authentication/providers/get_user_info_provider.dart';
import '../../profile/screens/user_profile_screen.dart';
import '../models/post_model.dart';
import '../providers/feed_provider.dart';
import '../providers/post_provider.dart';
import '../screens/create_post_screen.dart';

enum PostInfoStyle { feed, video }

class PostInfoTile extends ConsumerWidget {
  final DateTime datePublished;
  final String userId;
  final PostModel post;
  final PostInfoStyle style;
  final bool showOptions;

  const PostInfoTile({
    super.key,
    required this.datePublished,
    required this.userId,
    required this.post,
    this.style = PostInfoStyle.feed,
    this.showOptions = true,
  });

  void _showDeleteConfirmDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('common.confirm').tr(),
        content: const Text('common.delete_confirm').tr(),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('common.cancel').tr(),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(postRepositoryProvider).deletePost(post.postId);
                ref.read(mainFeedProvider.notifier).removePost(post.postId);
                showToastMessage(text: 'common.delete_success'.tr());
              } catch (e) {
                if (context.mounted) {
                  showToastMessage(text: 'common.delete_error'.tr());
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('common.delete').tr(),
          ),
        ],
      ),
    );
  }

  void _showPostOptions(
      BuildContext context, String currentUserId, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            if (userId == currentUserId) ...[
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('edit_post.title').tr(),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreatePostScreen(post: post),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('edit_post.delete',
                        style: TextStyle(color: Colors.red))
                    .tr(),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmDialog(context, ref);
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.report),
              title: const Text('common.report').tr(),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userInfo = ref.watch(getUserInfoByIdProvider(userId));
    final currentUser = ref.watch(getUserInfoProvider);

    return userInfo.when(
      data: (user) {
        final isVideo = style == PostInfoStyle.video;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserProfileScreen(
                      userId: user.uid,
                    ),
                  ),
                );
              },
              child: DisplayUserImage(
                imageUrl: user.profileImage,
                radius: isVideo ? 20 : 25,
                isOnline: user.isOnline,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserProfileScreen(
                        userId: user.uid,
                      ),
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      user.fullName,
                      style: isVideo
                          ? const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            )
                          : Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      DateTimeHelper.getRelativeTime(datePublished),
                      style: isVideo
                          ? const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            )
                          : Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            if (showOptions)
              GestureDetector(
                onTap: () => _showPostOptions(
                  context,
                  currentUser.value?.uid ?? '',
                  ref,
                ),
                child: Icon(
                  Icons.more_horiz,
                  color: isVideo ? Colors.white : null,
                ),
              ),
          ],
        );
      },
      error: (error, stackTrace) => Text(error.toString()),
      loading: () => const SizedBox.shrink(),
    );
  }
}
