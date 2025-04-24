import 'package:easy_localization/easy_localization.dart';
import 'package:social_app/core/utils/datetime_helper.dart';

extension DateTimeX on DateTime? {
  /// Format ngày tháng theo định dạng cụ thể
  /// Ví dụ:
  /// - dd/MM/yyyy -> 06/03/2024
  /// - HH:mm -> 15:30
  String format([String pattern = 'dd/MM/yyyy']) {
    return this == null ? '' : DateFormat(pattern).format(this!);
  }

  /// Lấy thời gian relative cho trạng thái online/offline
  String get timeAgo => DateTimeHelper.getLastSeen(this);

  /// Chuyển đổi sang Timestamp cho Firestore
  dynamic get toFirestore => DateTimeHelper.toMap(this);

  /// Format thời gian thông minh cho bài viết, bình luận,...:
  /// - Dưới 7 ngày: hiển thị relative time (vd: 2 giờ trước)
  /// - Sau 7 ngày: hiển thị ngày tháng năm (vd: 06/03/2024)
  String get smartFormat => DateTimeHelper.getRelativeTime(this);

  /// Trạng thái online/offline
  String get onlineStatus {
    if (this == null) return 'datetime.offline'.tr();
    return DateTimeHelper.getLastSeen(this);
  }
}

// Các extension khác nếu có
