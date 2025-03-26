import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../presentation/widgets/post_image_view.dart';
import '../models/post_model.dart';
import '../providers/post_provider.dart';
import '../widgets/post_info_tile.dart';
import '../widgets/post_interactions.dart';
import '../widgets/comment_sheet.dart';
import '../providers/comment_notifier.dart';

class PostDetailScreen extends ConsumerWidget {
  final String postId;

  const PostDetailScreen({
    super.key,
    required this.postId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postAsync = ref.watch(getPostByIdProvider(postId));
    final commentsState = ref.watch(commentProvider(postId));

    return Scaffold(
      appBar: AppBar(
        title: Text('post_detail.title'.tr()),
      ),
      body: postAsync.when(
        data: (post) {
          if (post == null) {
            return Center(
              child: Text('post_detail.not_found'.tr()),
            );
          }

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PostInfoTile(
                        datePublished: post.createdAt,
                        userId: post.userId,
                        post: post,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        post.content,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      if (post.fileUrls != null &&
                          post.fileUrls!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        PostImageView(
                          imageUrls: post.fileUrls!,
                          heroTagPrefix: 'post_detail_${post.postId}',
                        ),
                      ],
                      const Divider(height: 32),
                      PostInteractions(
                        post: post,
                        onShowComments: () {},
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Bình luận',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      commentsState.items.when(
                        data: (comments) {
                          if (comments.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: Text('Chưa có bình luận nào'),
                              ),
                            );
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: comments.length,
                            itemBuilder: (context, index) {
                              final comment = comments[index];
                              return CommentTile(
                                userId: comment.userId,
                                content: comment.content,
                                createdAt: comment.createdAt,
                                likeCount: comment.likeCount,
                                postId: postId,
                                commentId: comment.commentId,
                              );
                            },
                          );
                        },
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        error: (error, _) => Center(
                          child: Text('Lỗi: $error'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _buildCommentInput(context, ref, post),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => Center(
          child: Text('Lỗi: $error'),
        ),
      ),
    );
  }

  Widget _buildCommentInput(
      BuildContext context, WidgetRef ref, PostModel post) {
    final textController = TextEditingController();

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 8,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: Colors.grey[300]!,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: textController,
              decoration: const InputDecoration(
                hintText: 'Viết bình luận...',
                border: InputBorder.none,
              ),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (content) => _handleSubmitComment(
                context: context,
                ref: ref,
                content: content,
                textController: textController,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () => _handleSubmitComment(
              context: context,
              ref: ref,
              content: textController.text,
              textController: textController,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSubmitComment({
    required BuildContext context,
    required WidgetRef ref,
    required String content,
    required TextEditingController textController,
  }) async {
    if (content.trim().isEmpty) return;

    try {
      await ref
          .read(commentProvider(postId).notifier)
          .addComment(content.trim());
      textController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể gửi bình luận: $e')),
      );
    }
  }
}
