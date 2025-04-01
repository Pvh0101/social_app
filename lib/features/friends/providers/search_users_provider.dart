import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/log_utils.dart';

final searchUsersProvider =
    StreamProvider.autoDispose.family<List<String>, String>((ref, query) {
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;

  if (query.isEmpty) {
    logDebug(LogService.FRIEND,
        '[FRIEND_SEARCH] Tìm kiếm rỗng, hiển thị danh sách người dùng mặc định');
    return FirebaseFirestore.instance
        .collection('users')
        .where('uid', isNotEqualTo: currentUserId)
        .limit(20)
        .snapshots()
        .map((snapshot) {
      logDebug(LogService.FRIEND,
          '[FRIEND_SEARCH] Query rỗng - Tổng số người dùng: ${snapshot.docs.length}');
      return snapshot.docs.map((doc) => doc.id).toList();
    });
  }

  // Convert query thành lowercase để search case-insensitive
  final searchQuery = query.toLowerCase();
  logDebug(
      LogService.FRIEND, '[FRIEND_SEARCH] Tìm kiếm với từ khóa: $searchQuery');

  return FirebaseFirestore.instance
      .collection('users')
      .where('uid', isNotEqualTo: currentUserId)
      .limit(20)
      .snapshots()
      .map((snapshot) {
    logDebug(LogService.FRIEND,
        '[FRIEND_SEARCH] Tổng số người dùng: ${snapshot.docs.length}');

    final filteredDocs = snapshot.docs.where((doc) {
      final data = doc.data();
      logDebug(
          LogService.FRIEND, '[FRIEND_SEARCH] Kiểm tra người dùng: ${doc.id}');

      if (!data.containsKey('fullName')) {
        logDebug(LogService.FRIEND,
            '[FRIEND_SEARCH] Không tìm thấy trường fullName cho người dùng: ${doc.id}');
        return false;
      }

      final fullName = (data['fullName'] as String).toLowerCase();
      logDebug(LogService.FRIEND,
          '[FRIEND_SEARCH] So sánh: $fullName với $searchQuery');

      final matches = fullName.contains(searchQuery);
      return matches;
    }).toList();

    logDebug(LogService.FRIEND,
        '[FRIEND_SEARCH] Số kết quả sau khi lọc: ${filteredDocs.length}');
    final result = filteredDocs.map((doc) => doc.id).toList();

    logInfo(LogService.FRIEND,
        '[FRIEND_SEARCH] Tìm thấy ${result.length} kết quả cho từ khóa: $searchQuery');
    return result;
  });
});
