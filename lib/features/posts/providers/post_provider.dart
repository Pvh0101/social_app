import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../repositories/post_repository.dart';
import '../models/post_model.dart';
import '../../../features/notification/providers/notification_provider.dart';
import '../../../core/utils/log_utils.dart';

/// Provider cho PostRepository
/// Được sử dụng bởi các providers khác để truy cập vào repository
final postRepositoryProvider = Provider<PostRepository>((ref) {
  logDebug(LogService.POST, '[POST_PROVIDER] Khởi tạo PostRepository');
  final notificationRepository = ref.watch(notificationRepositoryProvider);
  return PostRepository(
    notificationRepository: notificationRepository,
    ref: ref,
  );
});

/// Provider để lấy thông tin bài viết theo ID
final getPostByIdProvider =
    FutureProvider.family<PostModel?, String>((ref, postId) async {
  logDebug(LogService.POST,
      '[POST_PROVIDER] Lấy thông tin bài viết với ID: $postId');
  final postRepository = ref.watch(postRepositoryProvider);
  final post = await postRepository.getPostById(postId);
  if (post != null) {
    logDebug(LogService.POST,
        '[POST_PROVIDER] Đã lấy thông tin bài viết: ${post.postId}');
  } else {
    logWarning(LogService.POST,
        '[POST_PROVIDER] Không tìm thấy bài viết với ID: $postId');
  }
  return post;
});
