import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'comment_input.dart';
import 'comment_list.dart';
import 'package:easy_localization/easy_localization.dart';
import '../models/post_model.dart';

class CommentSheet extends ConsumerWidget {
  final PostModel post;

  const CommentSheet({
    super.key,
    required this.post,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Text(
                  'post.comment.title'.tr(),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: CommentList(
              post: post,
              scrollController: scrollController,
            ),
          ),
          CommentInput(post: post),
        ],
      ),
    );
  }
}
