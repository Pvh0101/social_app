import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/paginated_state.dart';
import '../models/comment_model.dart';

/// State quản lý danh sách comments của một bài viết
class CommentState extends PaginatedState<CommentModel> {
  const CommentState({
    super.items = const AsyncValue.data([]),
    super.loadMoreStatus = const AsyncValue.data(null),
    super.lastDocument,
    super.hasMore = true,
  });

  @override
  CommentState copyWith({
    AsyncValue<List<CommentModel>>? items,
    AsyncValue<void>? loadMoreStatus,
    DocumentSnapshot? lastDocument,
    bool? hasMore,
  }) {
    return CommentState(
      items: items ?? this.items,
      loadMoreStatus: loadMoreStatus ?? this.loadMoreStatus,
      lastDocument: lastDocument ?? this.lastDocument,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}
