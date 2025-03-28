import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../presentation/widgets/post_image_view.dart';

import '../../../core/constants/routes_constants.dart';
import '../models/post_model.dart';
import '../providers/feed_provider.dart';
import '../providers/feed_state.dart';
import 'create_post_screen.dart';
import '../widgets/comment_sheet.dart';
import '../widgets/post_info_tile.dart';
import '../widgets/post_interactions.dart';
import '../../chat/providers/chat_providers.dart';
import '../widgets/post_content.dart';

/// Provider quản lý postId cần hiển thị
final selectedPostIdProvider = StateProvider<String?>((ref) => null);

class FeedScreen extends ConsumerStatefulWidget {
  final String?
      userId; // Nếu null thì hiển thị feed chung, nếu có thì hiển thị feed của user đó
  final bool showAppBar;

  const FeedScreen({
    super.key,
    this.userId,
    this.showAppBar = true,
  });

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen>
    with AutomaticKeepAliveClientMixin {
  late final ScrollController _scrollController;
  bool _isLoadingMore = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isLoadingMore) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final delta = MediaQuery.of(context).size.height * 0.2;

    if (maxScroll - currentScroll <= delta) {
      _isLoadingMore = true;
      final provider = widget.userId != null
          ? userFeedProvider(widget.userId!)
          : mainFeedProvider;
      ref.read(provider.notifier).loadMore().then((_) {
        _isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final provider = widget.userId != null
        ? userFeedProvider(widget.userId!)
        : mainFeedProvider;
    final state = ref.watch(provider);

    return Scaffold(
      body: state.items.when(
        data: (posts) {
          if (posts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('create_post.no_posts'.tr()),
                  if (widget.userId == null) ...[
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _navigateToCreatePost(),
                      child: Text('create_post.create'.tr()),
                    ),
                  ],
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(provider.notifier).refresh(),
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                if (widget.showAppBar)
                  SliverAppBar(
                    title: Text('create_post.title'.tr()),
                    floating: true,
                    snap: false,
                    pinned: false,
                    elevation: 0,
                    surfaceTintColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    actions: [
                      if (widget.userId == null) ...[
                        IconButton(
                          onPressed: () => _navigateToCreatePost(),
                          icon: const Icon(Icons.add),
                          tooltip: 'Tạo bài viết',
                        ),
                        Builder(builder: (context) {
                          final unreadMessagesCount =
                              ref.watch(totalUnreadMessagesProvider).maybeWhen(
                                    data: (count) => count,
                                    orElse: () => 0,
                                  );

                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              IconButton(
                                onPressed: () => Navigator.pushNamed(
                                  context,
                                  RouteConstants.chatList,
                                ),
                                icon: const Icon(Icons.send_rounded),
                                tooltip: 'Tin nhắn',
                              ),
                              if (unreadMessagesCount > 0)
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color:
                                          Theme.of(context).colorScheme.error,
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 16,
                                      minHeight: 16,
                                    ),
                                    child: Center(
                                      child: Text(
                                        unreadMessagesCount > 99
                                            ? '99+'
                                            : unreadMessagesCount.toString(),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        }),
                      ],
                    ],
                  ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index == posts.length) {
                        return _buildLoadMoreIndicator(state);
                      }

                      final post = posts[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: PostCard(
                          key: ValueKey('post_${post.postId}'),
                          post: post,
                        ),
                      );
                    },
                    childCount: posts.length + (state.hasMore ? 1 : 0),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Text('Lỗi: $error'),
        ),
      ),
    );
  }

  Widget _buildLoadMoreIndicator(FeedState state) {
    if (!state.hasMore) return const SizedBox();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      alignment: Alignment.center,
      child: const CircularProgressIndicator(),
    );
  }

  void _navigateToCreatePost() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreatePostScreen(),
      ),
    );
  }
}

class PostCard extends ConsumerWidget {
  final PostModel post;

  const PostCard({
    super.key,
    required this.post,
  });

  void _navigateToPostDetail(BuildContext context) {
    Navigator.pushNamed(
      context,
      RouteConstants.postDetail,
      arguments: {
        'postId': post.postId,
        'focusComment': false,
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _navigateToPostDetail(context),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: PostInfoTile(
                datePublished: post.createdAt,
                userId: post.userId,
                post: post,
                showOptions: true,
              ),
            ),
            PostContent(
              post: post,
            ),
          ],
        ),
      ),
    );
  }
}
