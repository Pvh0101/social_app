import 'package:easy_localization/easy_localization.dart';

enum MessageType {
  text,
  image,
  video,
  audio;

  static MessageType fromString(String value) {
    return MessageType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => MessageType.text,
    );
  }

  String get displayText {
    switch (this) {
      case MessageType.text:
        return 'chat.message_type.text'.tr();
      case MessageType.image:
        return 'chat.message_type.image'.tr();
      case MessageType.video:
        return 'chat.message_type.video'.tr();
      case MessageType.audio:
        return 'chat.message_type.audio'.tr();
    }
  }
}
