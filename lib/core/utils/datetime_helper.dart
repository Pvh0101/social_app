import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';

/// DateTimeHelper - Lớp tiện ích xử lý thời gian
///
/// Cung cấp các phương thức tiện ích để:
/// - Chuyển đổi giữa các định dạng thời gian
/// - Định dạng thời gian hiển thị
/// - So sánh thời gian
/// - Lấy thông tin về ngày, tháng
class DateTimeHelper {
  //
  // PHẦN 1: CHUYỂN ĐỔI ĐỊNH DẠNG
  //

  /// Chuyển đổi từ dynamic sang DateTime
  /// Hỗ trợ các kiểu dữ liệu:
  /// - Timestamp (Firestore)
  /// - int (millisecondsSinceEpoch)
  /// - null
  static DateTime? fromMap(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }

  /// Chuyển đổi từ DateTime sang Timestamp cho Firestore
  static dynamic toMap(DateTime? dateTime) {
    if (dateTime == null) return null;
    return Timestamp.fromDate(dateTime);
  }

  //
  // PHẦN 2: ĐỊNH DẠNG HIỂN THỊ THỜI GIAN
  //

  /// Format thời gian relative cho trạng thái online/last seen
  ///
  /// Kết quả:
  /// - Nếu null: trả về chuỗi rỗng (để model tự xử lý)
  /// - Dưới 1 phút: "Vừa xong"
  /// - Dưới 1 giờ: "X phút trước"
  /// - Dưới 1 ngày: "X giờ trước"
  /// - Còn lại: "X ngày trước"
  static String getLastSeen(DateTime? dateTime) {
    if (dateTime == null) return '';

    final difference = DateTime.now().difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'datetime.just_now'.tr();
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes ${'datetime.minutes'.tr()}';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${'datetime.hours'.tr()}';
    } else {
      final days = difference.inDays;
      return '$days ${'datetime.days'.tr()}';
    }
  }

  /// Format thời gian relative cho bài viết, bình luận,...
  ///
  /// Kết quả:
  /// - Nếu null: trả về chuỗi rỗng
  /// - Dưới 1 phút: "Vừa xong"
  /// - Dưới 1 giờ: "X phút trước"
  /// - Dưới 1 ngày: "X giờ trước"
  /// - Dưới 5 ngày: "X ngày trước"
  /// - Sau 5 ngày: ngày/tháng/năm
  static String getRelativeTime(DateTime? dateTime) {
    if (dateTime == null) return '';

    final difference = DateTime.now().difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'datetime.just_now'.tr();
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes ${'datetime.minutes'.tr()}';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${'datetime.hours'.tr()}';
    } else if (difference.inDays < 5) {
      final days = difference.inDays;
      return '$days ${'datetime.days'.tr()}';
    } else {
      return DateFormat('dd/MM/yyyy').format(dateTime);
    }
  }

  /// Format thời gian hiển thị cho tin nhắn (giờ:phút)
  ///
  /// Theo định dạng Messenger: HH:mm (24h)
  /// Ví dụ: "15:30"
  static String getTimeString(DateTime? dateTime) {
    if (dateTime == null) return '';
    return DateFormat('HH:mm').format(dateTime);
  }

  /// Định dạng ngày tháng dạng đầy đủ cho divider của chat
  ///
  /// Cách hiển thị:
  /// - Nếu trong hôm nay: Chỉ hiển thị giờ (VD: "15:30")
  /// - Nếu trong tuần này: Hiển thị giờ và thứ (VD: "15:30, Thứ Hai")
  /// - Nếu ngoài tuần: Hiển thị đầy đủ (VD: "15:30, Thứ Hai, 15/5/2023")
  static String getFormattedDate(DateTime? dateTime) {
    if (dateTime == null) return '';

    // Lấy chuỗi giờ:phút
    final timeString = getTimeString(dateTime);

    if (isToday(dateTime)) {
      // Nếu trong hôm nay, chỉ hiển thị giờ
      return timeString;
    } else if (isThisWeek(dateTime)) {
      // Nếu trong tuần này, hiển thị giờ và thứ
      final weekdayName = getWeekdayName(dateTime.weekday);
      return '$timeString, $weekdayName';
    } else {
      // Nếu ngoài tuần, hiển thị đầy đủ với định dạng ngày/tháng/năm
      final weekdayName = getWeekdayName(dateTime.weekday);
      final dateFormatted =
          '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      return '$timeString, $weekdayName, $dateFormatted';
    }
  }

  /// Lấy tên tiếng Việt của thứ trong tuần
  static String getWeekdayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Thứ Hai';
      case 2:
        return 'Thứ Ba';
      case 3:
        return 'Thứ Tư';
      case 4:
        return 'Thứ Năm';
      case 5:
        return 'Thứ Sáu';
      case 6:
        return 'Thứ Bảy';
      case 7:
        return 'Chủ Nhật';
      default:
        return '';
    }
  }

  //
  // PHẦN 3: SO SÁNH VÀ KIỂM TRA THỜI GIAN
  //

  /// Kiểm tra xem có nên hiển thị thời gian giữa 2 tin nhắn không
  ///
  /// Quy tắc: Hiển thị thời gian nếu hai tin nhắn cách nhau > 15 phút
  ///
  /// Tham số:
  /// - [olderTime] là thời gian của tin nhắn cũ hơn
  /// - [newerTime] là thời gian của tin nhắn mới hơn
  static bool shouldShowTimestamp(DateTime? olderTime, DateTime? newerTime) {
    if (olderTime == null || newerTime == null) return true;

    // Thời gian giữa 2 tin nhắn (phút)
    final difference = newerTime.difference(olderTime).inMinutes;

    // Hiển thị thời gian nếu khoảng cách lớn hơn 15 phút
    return difference.abs() >= 15;
  }

  /// Kiểm tra xem hai DateTime có cùng ngày không
  ///
  /// Hai ngày được coi là cùng ngày nếu chúng có cùng năm, tháng và ngày
  static bool isSameDay(DateTime? date1, DateTime? date2) {
    if (date1 == null || date2 == null) return false;

    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Kiểm tra xem dateTime có phải là ngày hôm nay không
  static bool isToday(DateTime? dateTime) {
    if (dateTime == null) return false;

    final now = DateTime.now();
    return dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;
  }

  /// Kiểm tra xem dateTime có phải là ngày hôm qua không
  static bool isYesterday(DateTime? dateTime) {
    if (dateTime == null) return false;

    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    return dateTime.year == yesterday.year &&
        dateTime.month == yesterday.month &&
        dateTime.day == yesterday.day;
  }

  /// Kiểm tra xem dateTime có phải là trong tuần này không
  ///
  /// Tuần được định nghĩa là 7 ngày gần nhất (không phải từ thứ Hai đến Chủ Nhật)
  static bool isThisWeek(DateTime? dateTime) {
    if (dateTime == null) return false;

    final now = DateTime.now();
    final difference = now.difference(dateTime).inDays;

    // Trong vòng 7 ngày gần nhất
    return difference < 7;
  }
}
