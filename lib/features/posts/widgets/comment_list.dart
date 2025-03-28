import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_app/features/posts/widgets/comment_tile.dart';
import '../models/post_model.dart';
import '../providers/comment_notifier.dart';

class CommentList extends ConsumerWidget {
  final PostModel post;
  final ScrollController? scrollController;

  const CommentList({
    super.key,
    required this.post,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commentsState = ref.watch(commentProvider(post.postId));

    return commentsState.items.when(
      data: (comments) {
        if (comments.isEmpty) {
          return const Center(
            child: Text('Chưa có bình luận nào'),
          );
        }

        return ListView.builder(
          controller: scrollController,
          shrinkWrap: true,
          physics: const ClampingScrollPhysics(),
          itemCount: comments.length,
          itemBuilder: (context, index) {
            final comment = comments[index];
            return CommentTile(
              userId: comment.userId,
              content: comment.content,
              createdAt: comment.createdAt,
              likeCount: comment.likeCount,
              postId: post.postId,
              commentId: comment.commentId,
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stack) => Center(
        child: Text('Lỗi: $error'),
      ),
    );
  }
}
