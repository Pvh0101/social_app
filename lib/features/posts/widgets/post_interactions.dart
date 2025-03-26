import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/enums/content_type.dart';
import '../../../core/utils/log_utils.dart';
import '../models/post_model.dart';
import '../providers/like_provider.dart';

enum PostInteractionsStyle {
  feed, // Style for feed screen
  video // Style for video screen
}

class PostInteractions extends ConsumerStatefulWidget {
  final PostModel post;
  final VoidCallback onShowComments;
  final PostInteractionsStyle style;

  const PostInteractions({
    super.key,
    required this.post,
    required this.onShowComments,
    this.style = PostInteractionsStyle.feed,
  });

  @override
  ConsumerState<PostInteractions> createState() => _PostInteractionsState();
}

class _LikeStatusWidget extends ConsumerWidget {
  final String postId;
  final int defaultLikeCount;
  final VoidCallback onLike;

  const _LikeStatusWidget({
    required this.postId,
    required this.defaultLikeCount,
    required this.onLike,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final likeStatus =
        ref.watch(likeStateProvider.select((value) => value[postId] ?? false));
    final likeCount = ref.watch(
        likeCountProvider.select((value) => value[postId] ?? defaultLikeCount));

    return TextButton.icon(
      onPressed: onLike,
      icon: Icon(
        likeStatus ? Icons.favorite : Icons.favorite_border,
        color:
            likeStatus ? Colors.red : Theme.of(context).colorScheme.onSurface,
      ),
      label: Text(
        'Yêu thích',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

class _PostInteractionsState extends ConsumerState<PostInteractions> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLikeState();
    });
  }

  void _initializeLikeState() async {
    if (!mounted) return;

    // Khởi tạo trạng thái like
    final currentLikeStatus = ref.read(likeStateProvider)[widget.post.postId];

    // Khởi tạo số lượng like từ model nếu chưa có trong provider
    final currentLikeCount = ref.read(likeCountProvider)[widget.post.postId];

    if (currentLikeCount == null) {
      logDebug(LogService.POST,
          '[POST_UI] Khởi tạo số lượng like cho postId: ${widget.post.postId}');
      ref
          .read(likeCountProvider.notifier)
          .setLikeCount(widget.post.postId, widget.post.likeCount);
    }

    if (currentLikeStatus == null) {
      logDebug(LogService.POST,
          '[POST_UI] Khởi tạo trạng thái like cho postId: ${widget.post.postId}');
      ref.read(likeStateProvider.notifier).initLikeStatus([widget.post.postId]);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lấy trạng thái like từ provider
    final likeStatus = ref.watch(likeStateProvider
        .select((value) => value[widget.post.postId] ?? false));

    // Lấy số lượng like từ provider thay vì từ model
    final likeCount = ref.watch(likeCountProvider
        .select((value) => value[widget.post.postId] ?? widget.post.likeCount));

    if (widget.style == PostInteractionsStyle.video) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildVideoButton(
            icon: likeStatus ? Icons.favorite : Icons.favorite_border,
            iconColor: likeStatus ? Colors.red : null,
            count: likeCount,
            onTap: _handleLike,
          ),
          const SizedBox(height: 16),
          _buildVideoButton(
            icon: Icons.mode_comment_outlined,
            count: widget.post.commentCount,
            onTap: widget.onShowComments,
          ),
          const SizedBox(height: 16),
          _buildVideoButton(
            icon: Icons.share,
            count: 0,
            onTap: () {
              // TODO: Implement share functionality
            },
          ),
        ],
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, left: 16, right: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$likeCount lượt thích'),
              const SizedBox(width: 15),
              GestureDetector(
                onTap: widget.onShowComments,
                child: Text('${widget.post.commentCount} bình luận'),
              ),
            ],
          ),
        ),
        Row(
          children: [
            Expanded(
              child: TextButton.icon(
                onPressed: _handleLike,
                icon: Icon(
                  likeStatus ? Icons.favorite : Icons.favorite_border,
                  color: likeStatus
                      ? Colors.red
                      : Theme.of(context).colorScheme.onSurface,
                ),
                label: Text(
                  'Yêu thích',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
            Expanded(
              child: TextButton.icon(
                onPressed: widget.onShowComments,
                icon: Icon(
                  Icons.mode_comment_outlined,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                label: Text(
                  'Bình luận',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
            Expanded(
              child: TextButton.icon(
                onPressed: () {},
                icon: Icon(
                  Icons.share_outlined,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                label: Text(
                  'Chia sẻ',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVideoButton({
    required IconData icon,
    Color? iconColor,
    required int count,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        IconButton(
          onPressed: onTap,
          icon: Icon(icon, size: 28, color: iconColor ?? Colors.white70),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        Text(
          _formatCount(count),
          style: TextStyle(
            fontSize: 14,
            color: iconColor ?? Colors.white70,
          ),
        ),
      ],
    );
  }

  String _formatCount(int count) {
    if (count < 1000) return count.toString();
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }

  void _handleLike() {
    try {
      logDebug(LogService.POST,
          '[POST_UI] Thực hiện thao tác like cho postId: ${widget.post.postId}');

      // Lấy trạng thái like hiện tại để log
      final currentLikeStatus =
          ref.read(likeStateProvider)[widget.post.postId] ?? false;
      final currentLikeCount =
          ref.read(likeCountProvider)[widget.post.postId] ??
              widget.post.likeCount;
      logDebug(LogService.POST,
          '[POST_UI] Trạng thái like trước khi toggle: $currentLikeStatus, Số lượng like: $currentLikeCount');

      // Sử dụng Future.microtask để tránh xung đột với gesture event
      Future.microtask(() {
        ref.read(likeStateProvider.notifier).toggleLike(
              widget.post.postId,
              ContentType.post,
            );
      });
    } catch (e, stackTrace) {
      logError(LogService.POST, '[POST_UI] Lỗi khi thực hiện like: $e', e,
          stackTrace);
    }
  }
}
