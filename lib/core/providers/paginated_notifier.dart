import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'paginated_state.dart';

/// Base class cho logic phân trang
/// [T] là kiểu dữ liệu của item trong danh sách
abstract class PaginatedNotifier<T> extends StateNotifier<PaginatedState<T>> {
  static const int defaultPageSize = 20;

  PaginatedNotifier() : super(const PaginatedState()) {
    // Load items khi khởi tạo
    loadInitial();
  }

  /// Số lượng items mỗi trang
  int get pageSize => defaultPageSize;

  /// Load trang đầu tiên
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

      state = PaginatedState(
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

  /// Load thêm items
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

  /// Tải lại danh sách
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

      state = PaginatedState(
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

  /// Query để lấy items từ Firestore
  /// Override phương thức này để định nghĩa cách lấy dữ liệu
  Future<QuerySnapshot<Map<String, dynamic>>> queryItems({
    required DocumentSnapshot? lastDocument,
    required int limit,
  });

  /// Chuyển đổi document thành item
  /// Override phương thức này để định nghĩa cách chuyển đổi
  T convertDocumentToItem(DocumentSnapshot<Map<String, dynamic>> doc);

  /// Xóa một item khỏi danh sách
  void removeItem(bool Function(T item) test) {
    final currentItems = state.currentItems;
    final updatedItems = currentItems.where((item) => !test(item)).toList();

    state = state.copyWith(
      items: AsyncValue.data(updatedItems),
    );
  }

  /// Thêm một item vào đầu danh sách
  void addItem(T item) {
    final currentItems = state.currentItems;
    state = state.copyWith(
      items: AsyncValue.data([item, ...currentItems]),
    );
  }

  /// Cập nhật một item trong danh sách
  void updateItem(bool Function(T item) test, T Function(T item) update) {
    final currentItems = state.currentItems;
    final updatedItems = currentItems.map((item) {
      if (test(item)) {
        return update(item);
      }
      return item;
    }).toList();

    state = state.copyWith(
      items: AsyncValue.data(updatedItems),
    );
  }
}
