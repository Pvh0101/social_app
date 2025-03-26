import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import '../../../../core/constants/routes_constants.dart';

class MessageButton extends ConsumerStatefulWidget {
  final String otherUserId;
  final double? size;
  final Color? color;
  final bool showText;

  const MessageButton({
    Key? key,
    required this.otherUserId,
    this.size,
    this.color,
    this.showText = false,
  }) : super(key: key);

  @override
  ConsumerState<MessageButton> createState() => _MessageButtonState();
}

class _MessageButtonState extends ConsumerState<MessageButton> {
  bool _isLoading = false;
  final logger = Logger();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: widget.color ?? theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(25),
          onTap: _isLoading
              ? null
              : () async {
                  try {
                    setState(() => _isLoading = true);
                    logger.i('===== NHẤN NÚT GỬI TIN NHẮN =====');
                    logger.i('Người dùng hiện tại: $currentUserId');
                    logger.i('Người nhận: ${widget.otherUserId}');

                    if (!mounted) return;

                    // Chuyển đến màn hình chat chỉ với userId của người nhận
                    logger.i(
                        'Chuyển hướng đến màn hình chat với receiverId: ${widget.otherUserId}');
                    Navigator.pushNamed(
                      context,
                      RouteConstants.chat,
                      arguments: {
                        'receiverId': widget.otherUserId,
                        'isGroup': false,
                      },
                    );
                    logger.i('Đã chuyển hướng thành công');
                  } catch (e) {
                    logger.e('Lỗi khi mở màn hình chat: $e');
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Không thể mở cuộc trò chuyện: $e'),
                        backgroundColor: theme.colorScheme.error,
                      ),
                    );
                  } finally {
                    if (mounted) {
                      setState(() => _isLoading = false);
                    }
                  }
                },
          child: Center(
            child: _isLoading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.onPrimary,
                      ),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Nhắn tin',
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
