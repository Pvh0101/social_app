import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/enums/content_type.dart';
import '../../../core/utils/datetime_helper.dart';
import '../../../core/utils/global_method.dart';
import '../../../core/widgets/display_user_image.dart';
import '../../../features/widgets/expandable_text.dart';
import '../../authentication/providers/get_user_info_by_id_provider.dart';
import '../../authentication/providers/get_user_info_provider.dart';
import '../providers/comment_notifier.dart';
import '../providers/like_provider.dart';
import '../../../core/constants/routes_constants.dart';

class CommentTile extends ConsumerStatefulWidget {
  final String userId;
  final String content;
  final DateTime createdAt;
  final int likeCount;
  final String postId;
  final String commentId;

  const CommentTile({
    super.key,
    required this.userId,
    required this.content,
    required this.createdAt,
    required this.postId,
    required this.commentId,
    this.likeCount = 0,
  });

  @override
  ConsumerState<CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends ConsumerState<CommentTile> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLikeState();
    });
  }

  void _initializeLikeState() async {
    if (!mounted) return;
    debugPrint('Khởi tạo trạng thái like cho commentId: \\${widget.commentId}');
    ref.read(likeCountProvider.notifier).setLikeCount(
          widget.commentId,
          widget.likeCount,
        );
    ref.read(likeStateProvider.notifier).initLikeStatus([widget.commentId]);
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _handleLike() {
    try {
      ref.read(likeStateProvider.notifier).toggleLike(
            widget.commentId,
            ContentType.comment,
          );
    } catch (e) {
      showToastMessage(text: 'Không thể thực hiện thao tác like');
    }
  }

  String _formatLikeCount(int count) {
    if (count < 1000) return count.toString();
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }

  @override
  Widget build(BuildContext context) {
    final userInfo = ref.watch(getUserInfoByIdProvider(widget.userId));
    final currentUser = ref.watch(getUserInfoProvider);
    final likeStatus = ref.watch(likeStateProvider)[widget.commentId] ?? false;
    final likeCount =
        ref.watch(likeCountProvider)[widget.commentId] ?? widget.likeCount;

    return userInfo.when(
      data: (user) {
        final isCommentOwner = currentUser.value?.uid == widget.userId;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pushNamed(
                    RouteConstants.profile,
                    arguments: widget.userId,
                  );
                },
                child: DisplayUserImage(
                  imageUrl: user.profileImage,
                  radius: 22,
                  isOnline: user.isOnline,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.fullName,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    ExpandableText(
                      text: widget.content,
                      maxLength: 100,
                      textStyle: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          DateTimeHelper.getRelativeTime(widget.createdAt),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                        ),
                        if (isCommentOwner) ...[
                          const SizedBox(width: 25),
                          GestureDetector(
                            onTap: () =>
                                _showCommentOptions(context, isCommentOwner),
                            child: Text(
                              'post.comment.delete'.tr(),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    iconSize: 20,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: _handleLike,
                    icon: Icon(
                      likeStatus ? Icons.favorite : Icons.favorite_border,
                      color: likeStatus ? Colors.red : Colors.grey,
                      size: 16,
                    ),
                  ),
                  if (likeCount > 0) ...[
                    Text(
                      _formatLikeCount(likeCount),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
      error: (error, stackTrace) {
        return Text(error.toString());
      },
      loading: () {
        return const SizedBox.shrink();
      },
    );
  }

  void _showCommentOptions(BuildContext context, bool isCommentOwner) {
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
            if (isCommentOwner) ...[
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text('post.comment.delete_comment'.tr(),
                    style: const TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    await ref
                        .read(commentProvider(widget.postId).notifier)
                        .deleteComment(widget.commentId);
                    showToastMessage(text: 'post.comment.delete_success'.tr());
                  } catch (e) {
                    showToastMessage(
                        text: '${'post.comment.delete_error'.tr()}: $e');
                  }
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.report),
              title: Text('common.report'.tr()),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement report comment
              },
            ),
          ],
        ),
      ),
    );
  }
}
