import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/comment_model.dart';
import 'comment_state.dart';
import 'post_provider.dart';
import '../repositories/post_repository.dart';

/// Provider quản lý danh sách comments của một bài viết
/// Sử dụng [CommentNotifier] để quản lý state
final commentProvider =
    StateNotifierProvider.family<CommentNotifier, CommentState, String>(
  (ref, postId) => CommentNotifier(
    postId: postId,
    repository: ref.watch(postRepositoryProvider),
  ),
);

/// Notifier quản lý logic của danh sách comments
class CommentNotifier extends StateNotifier<CommentState> {
  final PostRepository _repository;
  final String _postId;

  CommentNotifier({
    required String postId,
    required PostRepository repository,
  })  : _postId = postId,
        _repository = repository,
        super(const CommentState()) {
    loadInitial();
  }

  /// Số lượng comments mỗi trang
  int get pageSize => 20;

  /// Load trang đầu tiên của comments
  Future<void> loadInitial() async {
    if (state.isLoading) return;

    state = state.copyWith(
      items: const AsyncValue.loading(),
    );

    try {
      final snapshot = await queryItems(
        lastDocument: null,
        limit: pageSize,
      );

      final items = snapshot.docs.map(convertDocumentToItem).toList();

      state = CommentState(
        items: AsyncValue.data(items),
        lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
        hasMore: items.length >= pageSize,
      );
    } catch (error, stackTrace) {
      state = state.copyWith(
        items: AsyncValue.error(error, stackTrace),
      );
    }
  }

  /// Load thêm comments (infinite scroll)
  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore) return;

    state = state.copyWith(
      loadMoreStatus: const AsyncValue.loading(),
    );

    try {
      final snapshot = await queryItems(
        lastDocument: state.lastDocument,
        limit: pageSize,
      );

      final newItems = snapshot.docs.map(convertDocumentToItem).toList();
      final allItems = [...state.currentItems, ...newItems];

      state = state.copyWith(
        items: AsyncValue.data(allItems),
        lastDocument:
            snapshot.docs.isNotEmpty ? snapshot.docs.last : state.lastDocument,
        hasMore: newItems.length >= pageSize,
        loadMoreStatus: const AsyncValue.data(null),
      );
    } catch (error, stackTrace) {
      state = state.copyWith(
        loadMoreStatus: AsyncValue.error(error, stackTrace),
      );
    }
  }

  /// Tải lại danh sách comments
  Future<void> refresh() async {
    final previousState = state;

    state = state.copyWith(
      items: const AsyncValue.loading(),
      lastDocument: null,
      hasMore: true,
    );

    try {
      final snapshot = await queryItems(
        lastDocument: null,
        limit: pageSize,
      );

      final items = snapshot.docs.map(convertDocumentToItem).toList();

      state = CommentState(
        items: AsyncValue.data(items),
        lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
        hasMore: items.length >= pageSize,
      );
    } catch (error, stackTrace) {
      state = previousState.copyWith(
        items: AsyncValue.error(error, stackTrace),
      );
    }
  }

  /// Query để lấy comments từ Firestore
  Future<QuerySnapshot<Map<String, dynamic>>> queryItems({
    required DocumentSnapshot? lastDocument,
    required int limit,
  }) {
    return _repository.getComments(
      postId: _postId,
      lastDocument: lastDocument,
      limit: limit,
    );
  }

  /// Chuyển đổi document thành CommentModel
  CommentModel convertDocumentToItem(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    return CommentModel.fromMap({...doc.data()!, 'commentId': doc.id});
  }

  /// Thêm comment mới vào danh sách
  Future<void> addComment(String content) async {
    try {
      // Tăng số lượng comment ngay lập tức
      final currentCount = state.items.value?.length ?? 0;
      state = state.copyWith(
        items: AsyncValue.data([
          ...state.currentItems,
          CommentModel(
              commentId: '',
              postId: _postId,
              userId: '',
              content: content,
              createdAt: DateTime.now())
        ]),
      );

      // Tạo comment mới
      final commentId = await _repository.createComment(
        postId: _postId,
        content: content,
      );

      // Tải lại danh sách comments
      await refresh();
    } catch (e) {
      // Rollback nếu có lỗi
      final currentItems = state.currentItems;
      state = state.copyWith(
        items:
            AsyncValue.data(currentItems.sublist(0, currentItems.length - 1)),
      );
      rethrow;
    }
  }

  /// Xóa comment khỏi danh sách
  Future<void> deleteComment(String commentId) async {
    try {
      // Giảm số lượng comment ngay lập tức
      final currentItems = state.currentItems;
      final updatedItems =
          currentItems.where((item) => item.commentId != commentId).toList();

      state = state.copyWith(
        items: AsyncValue.data(updatedItems),
      );

      await _repository.deleteComment(
        postId: _postId,
        commentId: commentId,
      );

      // Tải lại danh sách comments
      await refresh();
    } catch (e) {
      // Rollback nếu có lỗi
      rethrow;
    }
  }
}
