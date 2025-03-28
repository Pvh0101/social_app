import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:social_app/features/posts/widgets/comment_input.dart';
import '../providers/post_provider.dart';
import '../widgets/post_info_tile.dart';
import '../widgets/post_content.dart';
import '../widgets/comment_list.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  final String postId;
  final bool focusComment;

  const PostDetailScreen({
    super.key,
    required this.postId,
    this.focusComment = false,
  });

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  // Focus node cho ô nhập comment
  final FocusNode _commentFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Request focus sau khi widget được build hoàn thành
    if (widget.focusComment) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _commentFocusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _commentFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final postAsync = ref.watch(getPostByIdProvider(widget.postId));

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        centerTitle: false,
        title: postAsync.when(
          data: (post) {
            if (post == null) return const SizedBox.shrink();
            return PostInfoTile(
              datePublished: post.createdAt,
              userId: post.userId,
              post: post,
              showOptions: true,
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PostContent(
                        post: post,
                        isDetailView: true,
                      ),
                      const SizedBox(height: 16),
                      CommentList(
                        post: post,
                      ),
                    ],
                  ),
                ),
              ),
              CommentInput(
                post: post,
                focusNode: _commentFocusNode,
              ),
            ],
          );
        },
        loading: () => const Center(
          child: SizedBox.shrink(),
        ),
        error: (error, stackTrace) => Center(
          child: Text('Lỗi: $error'),
        ),
      ),
    );
  }
}
