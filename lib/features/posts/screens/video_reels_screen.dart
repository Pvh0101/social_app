import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'; // Thêm import cho kBottomNavigationBarHeight
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:better_player_plus/better_player_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../../../core/utils/log_utils.dart';
import '../providers/video_player_provider.dart';
import '../providers/feed_provider.dart';
import '../widgets/post_info_tile.dart';
import '../widgets/post_interactions.dart';
import '../widgets/comment_sheet.dart';
import '../models/post_model.dart';
import '../../../main.dart'; // Để lấy routeObserver

class VideoReelsScreen extends ConsumerStatefulWidget {
  const VideoReelsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<VideoReelsScreen> createState() => _VideoReelsScreenState();
}

class _VideoReelsScreenState extends ConsumerState<VideoReelsScreen>
    implements RouteAware {
  @override
  void initState() {
    super.initState();
    logInfo(LogService.POST, '[VIDEO_REELS] Khởi tạo VideoReelsScreen');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Đăng ký RouteObserver
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
      logDebug(LogService.POST, '[VIDEO_REELS] Đăng ký RouteObserver');
    }
  }

  @override
  void dispose() {
    // Hủy đăng ký RouteObserver
    routeObserver.unsubscribe(this);
    logInfo(LogService.POST, '[VIDEO_REELS] Hủy VideoReelsScreen');
    super.dispose();
  }

  // Khi màn hình bị che khuất bởi màn hình khác đè lên
  @override
  void didPushNext() {
    if (!mounted) return;
    logInfo(
        LogService.POST, '[VIDEO_REELS] Màn hình bị che khuất (didPushNext)');

    // Dừng video khi chuyển màn hình
    final provider = ref.read(reelsPlayerProvider);
    try {
      provider.reelsController?.pause();
    } catch (e) {
      logError(LogService.POST, '[VIDEO_REELS] Lỗi khi dừng video: $e', e);
    }
  }

  // Khi màn hình hiện ra sau khi màn hình trên cùng bị pop
  @override
  void didPopNext() {
    if (!mounted) return;
    logInfo(LogService.POST,
        '[VIDEO_REELS] Màn hình trở lại hiển thị (didPopNext)');

    // Có thể tự động tiếp tục phát video nếu muốn
    // Hoặc để người dùng chủ động phát lại
  }

  // Các phương thức bắt buộc của RouteAware
  @override
  void didPop() {}
  @override
  void didPush() {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Consumer(
        builder: (context, ref, child) {
          final provider = ref.watch(reelsPlayerProvider);
          final feedState = ref.watch(videoFeedProvider);

          return feedState.items.when(
            data: (posts) {
              if (provider.loading) {
                return const Center(
                    child: CircularProgressIndicator(color: Colors.white));
              }

              if (posts.isEmpty) {
                return const Center(
                  child: Text(
                    'Chưa có video nào',
                  ),
                );
              }
              return PageView.builder(
                physics: const CustomPageViewScrollPhysics(),
                itemCount: posts.length,
                scrollDirection: Axis.vertical,
                onPageChanged: (index) {
                  provider.onPageChange(index);
                },
                itemBuilder: (context, index) {
                  return index != provider.currentReelIndex
                      ? _buildThumbnailItem(provider, index)
                      : _buildVideoItem(provider, index);
                },
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            error: (error, stack) => Center(
              child: Text(
                'Có lỗi xảy ra: $error',
              ),
            ),
          );
        },
      ),
      extendBody: true,
      extendBodyBehindAppBar: true,
    );
  }

  /// Xây dựng item hiển thị thumbnail
  Widget _buildThumbnailItem(ReelsPlayerProvider provider, int index) {
    if (index >= provider.videosList.length) return const SizedBox();

    return Stack(
      children: [
        // Thumbnail chính
        SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: ClipRRect(
            child: Container(
              color: Theme.of(context).colorScheme.surface,
              child: CachedNetworkImage(
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                imageUrl: provider.videosList[index].thumbnailUrl ?? '',
                placeholder: (context, url) => Container(color: Colors.black),
                errorWidget: (context, url, error) => const Center(
                  child: Icon(Icons.error, color: Colors.white),
                ),
              ),
            ),
          ),
        ),

        // Overlay UI (Tương tác, Like, Comment...)
        _buildVideoOverlay(provider, index),
      ],
    );
  }

  /// Xây dựng item hiển thị video
  Widget _buildVideoItem(ReelsPlayerProvider provider, int index) {
    if (index >= provider.videosList.length) return const SizedBox();

    final isVideoReady =
        provider.reelsController?.videoPlayerController != null &&
            provider.reelsController!.isVideoInitialized()!;

    if (!isVideoReady) {
      return _buildThumbnailItem(provider, index);
    }

    return Stack(
      children: [
        // Video chính
        Positioned.fill(
          child: VisibilityDetector(
            key: Key('video_${provider.videosList[index].postId}'),
            onVisibilityChanged: (info) {
              if (info.visibleFraction >= 0.99) {
                provider.playVideo();
              }
            },
            child: GestureDetector(
              onTap: () {
                // Kiểm tra trạng thái đang phát để thực hiện hành động ngược lại
                if (provider.isPlaying) {
                  logDebug(LogService.POST,
                      '[VIDEO_REELS] Dừng video khi chạm vào màn hình');
                  provider.pauseVideo();
                } else {
                  logDebug(LogService.POST,
                      '[VIDEO_REELS] Phát video khi chạm vào màn hình');
                  provider.playVideo();
                }
              },
              child: BetterPlayer(
                controller: provider.reelsController!,
              ),
            ),
          ),
        ),

        // Overlay UI (Tương tác, Like, Comment...)
        _buildVideoOverlay(provider, index),
      ],
    );
  }

  /// Xây dựng lớp overlay trên video (info, tương tác)
  Widget _buildVideoOverlay(ReelsPlayerProvider provider, int index) {
    if (index >= provider.videosList.length) {
      return const SizedBox();
    }

    final post = provider.videosList[index];

    return Stack(
      children: [
        // Gradient overlay phía dưới cho text dễ đọc
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            height: 150,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black87,
                ],
              ),
            ),
          ),
        ),

        // Tương tác (likes, comments, shares)
        Positioned(
          right: 6,
          bottom: 100,
          child: PostInteractions(
              post: post,
              style: PostInteractionsStyle.video,
              onShowComments: () => {}),
        ),

        // Thông tin video
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              PostInfoTile(
                datePublished: post.createdAt,
                userId: post.userId,
                post: post,
                style: PostInfoStyle.video,
                showOptions: true,
              ),
              const SizedBox(height: 8),
              Text(
                post.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // void _showCommentSheet(BuildContext context, PostModel post) {
  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     shape: const RoundedRectangleBorder(
  //       borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  //     ),
  //     builder: (_) => CommentSheet(postId: post.postId),
  //   );
  // }
}

/// Physics tùy chỉnh cho PageView
class CustomPageViewScrollPhysics extends ScrollPhysics {
  const CustomPageViewScrollPhysics({super.parent});

  @override
  CustomPageViewScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return CustomPageViewScrollPhysics(parent: buildParent(ancestor)!);
  }

  @override
  SpringDescription get spring => const SpringDescription(
        mass: 120,
        stiffness: 120,
        damping: 1,
      );
}
