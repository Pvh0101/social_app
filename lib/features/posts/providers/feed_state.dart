import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/enums/post_type.dart';
import '../../../core/providers/paginated_state.dart';
import '../models/post_model.dart';

/// State quản lý danh sách bài viết trong feed
class FeedState extends PaginatedState<PostModel> {
  final PostType? filterType;
  final String? userId;

  const FeedState({
    super.items = const AsyncValue.data([]),
    super.loadMoreStatus = const AsyncValue.data(null),
    super.lastDocument,
    super.hasMore = true,
    this.filterType,
    this.userId,
  });

  @override
  FeedState copyWith({
    AsyncValue<List<PostModel>>? items,
    AsyncValue<void>? loadMoreStatus,
    DocumentSnapshot? lastDocument,
    bool? hasMore,
    PostType? filterType,
    String? userId,
  }) {
    return FeedState(
      items: items ?? this.items,
      loadMoreStatus: loadMoreStatus ?? this.loadMoreStatus,
      lastDocument: lastDocument ?? this.lastDocument,
      hasMore: hasMore ?? this.hasMore,
      filterType: filterType ?? this.filterType,
      userId: userId ?? this.userId,
    );
  }
}
