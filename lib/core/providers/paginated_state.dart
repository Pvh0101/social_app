import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Base class cho trạng thái phân trang
/// [T] là kiểu dữ liệu của item trong danh sách
class PaginatedState<T> {
  /// Danh sách items với trạng thái loading/error
  final AsyncValue<List<T>> items;

  /// Trạng thái khi load thêm items
  final AsyncValue<void> loadMoreStatus;

  /// Document cuối cùng để phân trang
  final DocumentSnapshot? lastDocument;

  /// Còn items để load không
  final bool hasMore;

  const PaginatedState({
    this.items = const AsyncValue.data([]),
    this.loadMoreStatus = const AsyncValue.data(null),
    this.lastDocument,
    this.hasMore = true,
  });

  /// Tạo state mới với các giá trị được cập nhật
  PaginatedState<T> copyWith({
    AsyncValue<List<T>>? items,
    AsyncValue<void>? loadMoreStatus,
    DocumentSnapshot? lastDocument,
    bool? hasMore,
  }) {
    return PaginatedState<T>(
      items: items ?? this.items,
      loadMoreStatus: loadMoreStatus ?? this.loadMoreStatus,
      lastDocument: lastDocument ?? this.lastDocument,
      hasMore: hasMore ?? this.hasMore,
    );
  }

  /// Đang tải dữ liệu lần đầu
  bool get isLoading => items.isLoading;

  /// Đang tải lại dữ liệu (có data cũ)
  bool get isRefreshing => items.isLoading && items.valueOrNull != null;

  /// Đang tải thêm items
  bool get isLoadingMore => loadMoreStatus.isLoading;

  /// Có lỗi khi tải dữ liệu
  bool get hasError => items.hasError;

  /// Có lỗi khi tải thêm
  bool get hasLoadMoreError => loadMoreStatus.hasError;

  /// Không có items nào
  bool get isEmpty => items.valueOrNull?.isEmpty ?? true;

  /// Lấy danh sách items hiện tại
  List<T> get currentItems => items.valueOrNull ?? [];
}
