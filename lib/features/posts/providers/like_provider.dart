import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/enums/content_type.dart';
import '../../../core/utils/log_utils.dart';
import '../repositories/post_repository.dart';
import 'post_provider.dart';

/// State lưu trữ trạng thái like của các content
/// Key: contentId, Value: isLiked
final likeStateProvider =
    StateNotifierProvider<LikeStateNotifier, Map<String, bool>>((ref) {
  final postRepository = ref.watch(postRepositoryProvider);
  return LikeStateNotifier(postRepository, ref);
});

/// State lưu trữ số lượng like của các content
/// Key: contentId, Value: likeCount
final likeCountProvider =
    StateNotifierProvider<LikeCountNotifier, Map<String, int>>((ref) {
  return LikeCountNotifier();
});

class LikeCountNotifier extends StateNotifier<Map<String, int>> {
  LikeCountNotifier() : super({});

  void setLikeCount(String contentId, int count) {
    logDebug(LogService.POST,
        '[POST_PROVIDER] Đặt số lượng like cho contentId: $contentId thành $count');
    final newState = Map<String, int>.from(state);
    newState[contentId] = count;
    state = newState;
  }

  void incrementLikeCount(String contentId) {
    final currentCount = state[contentId] ?? 0;
    logDebug(LogService.POST,
        '[POST_PROVIDER] Tăng số lượng like cho contentId: $contentId. Số lượng hiện tại: $currentCount');
    final newState = Map<String, int>.from(state);
    newState[contentId] = currentCount + 1;
    state = newState;
  }

  void decrementLikeCount(String contentId) {
    final currentCount = state[contentId] ?? 0;
    logDebug(LogService.POST,
        '[POST_PROVIDER] Giảm số lượng like cho contentId: $contentId. Số lượng hiện tại: $currentCount');
    if (currentCount > 0) {
      final newState = Map<String, int>.from(state);
      newState[contentId] = currentCount - 1;
      state = newState;
    }
  }

  void clearCounts() {
    logDebug(LogService.POST, '[POST_PROVIDER] Xóa tất cả số lượng like');
    state = {};
  }
}

class LikeStateNotifier extends StateNotifier<Map<String, bool>> {
  final PostRepository _postRepository;
  final Ref _ref;

  LikeStateNotifier(this._postRepository, this._ref) : super({});

  /// Khởi tạo trạng thái like cho danh sách content
  Future<void> initLikeStatus(List<String> contentIds) async {
    try {
      logDebug(LogService.POST,
          '[POST_PROVIDER] Khởi tạo trạng thái like cho contentIds: $contentIds');
      final likeStatus =
          await _postRepository.getLikeStatus(contentIds: contentIds);
      final newState = Map<String, bool>.from(state);
      newState.addAll(likeStatus);
      state = newState;
    } catch (e, stackTrace) {
      logError(
          LogService.POST,
          '[POST_PROVIDER] Lỗi khi khởi tạo trạng thái like: $e',
          e,
          stackTrace);
    }
  }

  /// Toggle like với optimistic update
  Future<void> toggleLike(String contentId, ContentType contentType) async {
    // Lấy trạng thái like hiện tại
    final currentLikeStatus = state[contentId] ?? false;
    logDebug(LogService.POST,
        '[POST_PROVIDER] Chuyển đổi trạng thái like cho contentId: $contentId. Trạng thái hiện tại: $currentLikeStatus');

    // Cập nhật state với trạng thái mới (optimistic update)
    final newState = Map<String, bool>.from(state);
    newState[contentId] = !currentLikeStatus;
    state = newState;

    // Cập nhật số lượng like (optimistic update)
    if (!currentLikeStatus) {
      _ref.read(likeCountProvider.notifier).incrementLikeCount(contentId);
    } else {
      _ref.read(likeCountProvider.notifier).decrementLikeCount(contentId);
    }

    try {
      // Gọi API để cập nhật trên server
      await _postRepository.toggleLike(contentId, contentType);
      logDebug(LogService.POST,
          '[POST_PROVIDER] Đã cập nhật thành công trạng thái like trên server');
    } catch (e, stackTrace) {
      logError(
          LogService.POST,
          '[POST_PROVIDER] Lỗi khi chuyển đổi trạng thái like cho contentId: $contentId: $e',
          e,
          stackTrace);

      // Rollback lại trạng thái cũ nếu có lỗi
      final rollbackState = Map<String, bool>.from(state);
      rollbackState[contentId] = currentLikeStatus;
      state = rollbackState;

      // Rollback số lượng like
      if (currentLikeStatus) {
        _ref.read(likeCountProvider.notifier).incrementLikeCount(contentId);
      } else {
        _ref.read(likeCountProvider.notifier).decrementLikeCount(contentId);
      }

      logInfo(LogService.POST,
          '[POST_PROVIDER] Đã rollback trạng thái like do lỗi');
      rethrow;
    }
  }

  /// Clear state khi logout hoặc cần reset
  void clearState() {
    logDebug(LogService.POST, '[POST_PROVIDER] Xóa trạng thái like');
    state = {};
    _ref.read(likeCountProvider.notifier).clearCounts();
  }
}
