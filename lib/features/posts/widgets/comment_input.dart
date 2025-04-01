import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/core.dart';
import '../models/post_model.dart';
import '../providers/comment_notifier.dart';

class CommentInput extends ConsumerWidget {
  final PostModel post;
  final FocusNode? focusNode;

  const CommentInput({
    super.key,
    required this.post,
    this.focusNode,
  });

  Future<void> _handleSubmitComment({
    required BuildContext context,
    required WidgetRef ref,
    required String content,
    required TextEditingController textController,
  }) async {
    if (content.trim().isEmpty) return;

    try {
      await ref
          .read(commentProvider(post.postId).notifier)
          .addComment(content.trim());
      textController.clear();
    } catch (e) {
      showToastMessage(text: '${'post.comment.error'.tr()}: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              focusNode: focusNode,
              decoration: InputDecoration(
                hintText: 'post.comment.write'.tr(),
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
}
