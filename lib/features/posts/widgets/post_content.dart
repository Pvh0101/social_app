import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_app/features/posts/presentation/widgets/post_image_view.dart';
import 'package:social_app/features/widgets/expandable_text.dart';
import '../models/post_model.dart';
import '../../../core/constants/routes_constants.dart';
import 'post_interactions.dart';

class PostContent extends ConsumerWidget {
  final PostModel post;
  final VoidCallback? onShowComments;
  final bool isDetailView;

  const PostContent({
    super.key,
    required this.post,
    this.onShowComments,
    this.isDetailView = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
          child: ExpandableText(
            text: post.content,
            maxLength: 150,
            textStyle: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        if (post.fileUrls != null && post.fileUrls!.isNotEmpty)
          PostImageView(
            imageUrls: post.fileUrls!,
            heroTagPrefix: 'post_${post.postId}',
          ),
        const Divider(height: 1),
        PostInteractions(
          post: post,
          onShowComments: () => _handleCommentAction(context, ref),
        ),
      ],
    );
  }

  void _handleCommentAction(BuildContext context, WidgetRef ref) {
    // Nếu đang ở màn hình chi tiết bài viết rồi thì không làm gì cả
    if (isDetailView) {
      return;
    }

    // Nếu có callback riêng thì gọi callback
    if (onShowComments != null) {
      onShowComments!();
    } else {
      // Chuyển đến màn hình chi tiết bài viết với tham số focusComment = true
      Navigator.pushNamed(
        context,
        RouteConstants.postDetail,
        arguments: {
          'postId': post.postId,
          'focusComment': true,
        },
      );
    }
  }
}
