import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/enums/post_type.dart';
import 'post_provider.dart';
import 'package:better_player_plus/better_player_plus.dart';

import '../models/post_model.dart';
import '../repositories/post_repository.dart';
import 'feed_state.dart';

/// Provider cho main feed (hiển thị bài viết text và image)
final mainFeedProvider = StateNotifierProvider<FeedNotifier, FeedState>((ref) {
  return FeedNotifier(
    ref.watch(postRepositoryProvider),
    initialFilterType: PostType.image,
  );
});

/// Provider cho video feed (hiển thị bài viết có video)
final videoFeedProvider = StateNotifierProvider<FeedNotifier, FeedState>((ref) {
  return FeedNotifier(
    ref.watch(postRepositoryProvider),
    initialFilterType: PostType.video,
  );
});

/// Provider cho user feed (hiển thị bài viết của một user cụ thể)
final userFeedProvider =
    StateNotifierProvider.family<FeedNotifier, FeedState, String>(
        (ref, userId) {
  return FeedNotifier(
    ref.watch(postRepositoryProvider),
    initialFilterType: PostType.image,
    initialUserId: userId,
  );
});

/// Notifier quản lý logic của feed posts
class FeedNotifier extends StateNotifier<FeedState> {
  final PostRepository _repository;
  final Set<String> _processedPostIds = {};

  FeedNotifier(
    this._repository, {
    PostType? initialFilterType,
    String? initialUserId,
  }) : super(FeedState(
          filterType: initialFilterType,
          userId: initialUserId,
        )) {
    loadInitial();
  }

  /// Số lượng items mỗi trang
  int get pageSize => 15;

  /// Load trang đầu tiên
  Future<void> loadInitial() async {
    if (state.items.isLoading) return;

    state = state.copyWith(
      items: const AsyncValue.loading(),
    );

    try {
      final snapshot = await queryItems(
        lastDocument: null,
        limit: pageSize,
      );

      final items = _processDocuments(snapshot.docs);

      if (!mounted) return;
      state = FeedState(
        items: AsyncValue.data(items),
        lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
        hasMore: items.length >= pageSize,
        filterType: state.filterType,
        userId: state.userId,
      );
    } catch (error, stackTrace) {
      if (!mounted) return;
      state = state.copyWith(
        items: AsyncValue.error(error, stackTrace),
      );
    }
  }

  /// Load thêm items
  Future<void> loadMore() async {
    if (!state.hasMore || state.loadMoreStatus.isLoading) return;

    state = state.copyWith(
      loadMoreStatus: const AsyncValue.loading(),
    );

    try {
      final snapshot = await queryItems(
        lastDocument: state.lastDocument,
        limit: pageSize,
      );

      final newItems = _processDocuments(snapshot.docs);
      final allItems = [...state.currentItems, ...newItems];

      if (!mounted) return;
      state = state.copyWith(
        items: AsyncValue.data(allItems),
        lastDocument:
            snapshot.docs.isNotEmpty ? snapshot.docs.last : state.lastDocument,
        hasMore: newItems.length >= pageSize,
        loadMoreStatus: const AsyncValue.data(null),
      );
    } catch (error, stackTrace) {
      if (!mounted) return;
      state = state.copyWith(
        loadMoreStatus: AsyncValue.error(error, stackTrace),
      );
    }
  }

  /// Tải lại danh sách
  Future<void> refresh() async {
    if (state.items.isLoading) return;

    _processedPostIds.clear();
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

      final items = _processDocuments(snapshot.docs);

      if (!mounted) return;
      state = FeedState(
        items: AsyncValue.data(items),
        lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
        hasMore: items.length >= pageSize,
        filterType: state.filterType,
        userId: state.userId,
      );
    } catch (error, stackTrace) {
      if (!mounted) return;
      state = previousState.copyWith(
        items: AsyncValue.error(error, stackTrace),
      );
    }
  }

  /// Xử lý documents từ Firestore
  List<PostModel> _processDocuments(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    return docs
        .map((doc) {
          final postId = doc.id;
          if (_processedPostIds.contains(postId)) {
            return null;
          }
          _processedPostIds.add(postId);
          return convertDocumentToItem(doc);
        })
        .whereType<PostModel>()
        .toList();
  }

  /// Query để lấy items từ Firestore
  Future<QuerySnapshot<Map<String, dynamic>>> queryItems({
    required DocumentSnapshot? lastDocument,
    required int limit,
  }) {
    return _repository.getFeedPosts(
      lastDocument: lastDocument,
      type: state.filterType,
      userId: state.userId,
    );
  }

  /// Chuyển đổi document thành item
  PostModel convertDocumentToItem(DocumentSnapshot<Map<String, dynamic>> doc) {
    return PostModel.fromMap({...doc.data()!, 'postId': doc.id});
  }

  /// Xóa một bài viết khỏi feed
  void removePost(String postId) {
    final currentItems = state.currentItems;
    final updatedItems =
        currentItems.where((item) => item.postId != postId).toList();
    _processedPostIds.remove(postId);

    state = state.copyWith(
      items: AsyncValue.data(updatedItems),
    );
  }
}
