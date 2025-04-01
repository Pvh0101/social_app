import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/enums/message_type.dart';
import '../../../../core/utils/global_method.dart';
import '../../../../core/widgets/simple_media_picker.dart';
import '../../../../core/services/media/media_service.dart';
import '../../../../core/services/media/media_types.dart';
import '../../../../core/widgets/media_preview.dart';
import '../../providers/chat_providers.dart';

class MessageInput extends ConsumerStatefulWidget {
  final Function(String, MessageType, String?) onSend;
  final String chatId;
  final FocusNode? focusNode;

  const MessageInput({
    Key? key,
    required this.onSend,
    required this.chatId,
    this.focusNode,
  }) : super(key: key);

  @override
  ConsumerState<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends ConsumerState<MessageInput> {
  final TextEditingController _controller = TextEditingController();
  late FocusNode _focusNode;
  bool _isComposing = false;
  bool _isUploading = false;
  File? _selectedMedia;
  MessageType _selectedMediaType = MessageType.text;
  double _uploadProgress = 0.0;
  final _mediaService = MediaService();

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _handleSubmitted(String text) {
    if (_selectedMedia != null) {
      _uploadAndSendMedia(text);
    } else if (text.trim().isNotEmpty) {
      try {
        widget.onSend(text, MessageType.text, null);
        _controller.clear();
        setState(() {
          _isComposing = false;
        });
      } catch (e) {
        showToastMessage(text: 'Lỗi gửi tin nhắn: $e');
      }
    }
  }

  void _handleTextChange(String text) {
    setState(() {
      _isComposing = text.trim().isNotEmpty || _selectedMedia != null;
    });
  }

  void _handleMediaSelected(File file, MediaType type) {
    // Cập nhật state với file đã chọn
    setState(() {
      _selectedMedia = file;
      _selectedMediaType = _convertMediaType(type);
      _isComposing = true;
    });
  }

  MessageType _convertMediaType(MediaType type) {
    switch (type) {
      case MediaType.image:
        return MessageType.image;
      case MediaType.video:
        return MessageType.video;
      case MediaType.audio:
        return MessageType.audio;
      default:
        return MessageType.text;
    }
  }

  MediaType _convertToMediaServiceType(MessageType type) {
    switch (type) {
      case MessageType.image:
        return MediaType.image;
      case MessageType.video:
        return MediaType.video;
      case MessageType.audio:
        return MediaType.audio;
      default:
        return MediaType.image;
    }
  }

  Future<void> _uploadAndSendMedia(String caption) async {
    if (_selectedMedia == null) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      // Hiển thị thanh tiến trình xác định trong quá trình upload ở repository
      // Vì không thể nhận callback trực tiếp từ repository, nên sử dụng timer để mô phỏng tiến trình
      // Trong thực tế, bạn có thể cân nhắc sử dụng một provider trạng thái khác để theo dõi tiến trình upload
      setState(() {
        _uploadProgress = 0.1; // Bắt đầu với 10%
      });

      // Định nghĩa các mốc tiến độ để hiển thị cho người dùng
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_isUploading)
          setState(() {
            _uploadProgress = 0.2;
          });
      });

      Future.delayed(const Duration(milliseconds: 800), () {
        if (_isUploading)
          setState(() {
            _uploadProgress = 0.4;
          });
      });

      // Sử dụng uploadMediaProvider từ repository
      final mediaUrl = await ref.read(uploadMediaProvider(
        UploadMediaParams(
          chatId: widget.chatId,
          file: _selectedMedia!,
        ),
      ).future);

      // Đã hoàn thành upload
      setState(() {
        _uploadProgress = 1.0;
      });

      final messageContent = caption.isEmpty
          ? 'Đã gửi ${_selectedMediaType.displayText}'
          : caption;

      widget.onSend(
        messageContent,
        _selectedMediaType,
        mediaUrl,
      );

      _controller.clear();
      setState(() {
        _selectedMedia = null;
        _isComposing = false;
        _isUploading = false;
      });
    } catch (e) {
      showToastMessage(text: 'Không thể tải lên file: $e');
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        // Hiển thị xem trước media nếu có
        if (_selectedMedia != null)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: Container(
                  width: double.infinity,
                  constraints: BoxConstraints(
                    maxHeight: _selectedMediaType == MessageType.video
                        ? 400
                        : 300, // Tăng chiều cao cho video
                    minHeight: _selectedMediaType == MessageType.video
                        ? 250
                        : 150, // Tăng chiều cao tối thiểu cho video
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(20),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: MediaPreview(
                    media: _selectedMedia!,
                    type: _convertToMediaServiceType(_selectedMediaType),
                    onRemove: () {
                      setState(() {
                        _selectedMedia = null;
                        _selectedMediaType = MessageType.text;
                        _isComposing = _controller.text.trim().isNotEmpty;
                      });
                    },
                    onEdit: _selectedMediaType == MessageType.image
                        ? (file) {
                            setState(() {
                              _selectedMedia = file;
                            });
                          }
                        : null,
                    isUploading: _isUploading,
                    uploadProgress: _uploadProgress,
                  ),
                ),
              ),
            ],
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          color: colorScheme.surface,
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isUploading)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: LinearProgressIndicator(
                      value: _uploadProgress,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(colorScheme.primary),
                      backgroundColor: colorScheme.surfaceVariant,
                    ),
                  ),
                Row(
                  children: [
                    // Nút media tích hợp - vô hiệu hóa nếu đã chọn media
                    SimpleMediaPicker(
                      onMediaSelected: _selectedMedia == null
                          ? _handleMediaSelected
                          : (_,
                              __) {}, // Cung cấp một hàm trống nếu đã có media
                      iconColor: _selectedMedia == null
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant.withOpacity(0.5),
                      iconSize: 24,
                      title: _selectedMedia == null
                          ? 'Chọn media'
                          : 'Đã chọn media',
                    ),

                    // Ô nhập tin nhắn
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.brightness == Brightness.dark
                              ? colorScheme.surfaceVariant
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: TextField(
                                  controller: _controller,
                                  focusNode: _focusNode,
                                  onChanged: _handleTextChange,
                                  onSubmitted:
                                      _isComposing ? _handleSubmitted : null,
                                  decoration: InputDecoration(
                                    hintText: _selectedMedia != null
                                        ? 'Nhập chú thích (${_selectedMediaType.displayText} đã chọn)'
                                        : 'Nhắn tin...',
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                    hintStyle: TextStyle(
                                      color: colorScheme.onSurfaceVariant
                                          .withOpacity(0.7),
                                    ),
                                  ),
                                  style: TextStyle(
                                    color: colorScheme.onSurface,
                                  ),
                                  minLines: 1,
                                  maxLines: 5,
                                ),
                              ),
                            ),
                            // Nút emoji
                            IconButton(
                              icon: const Icon(Icons.emoji_emotions_outlined),
                              onPressed: () {
                                // TODO: Implement emoji picker
                              },
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Nút gửi hoặc ghi âm
                    _isComposing
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.send),
                                onPressed: () =>
                                    _handleSubmitted(_controller.text),
                                color: colorScheme.primary,
                              ),
                            ],
                          )
                        : IconButton(
                            icon: const Icon(Icons.mic),
                            onPressed: () async {
                              // Hiển thị dialog ghi âm
                              final File? audioFile =
                                  await _showAudioRecordingDialog();

                              // Xử lý file ghi âm nếu có
                              if (audioFile != null) {
                                _handleMediaSelected(
                                    audioFile, MediaType.audio);
                              }
                            },
                            color: colorScheme.primary,
                          ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Hiển thị dialog ghi âm
  Future<File?> _showAudioRecordingDialog() async {
    File? resultFile;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Biến để theo dõi thời gian ghi âm
            int recordingDuration = 0;
            bool isRecording = false;

            // Hàm dừng ghi âm và lưu file
            Future<void> stopAndSave() async {
              isRecording = false;
              final file = await _mediaService.stopAudioRecording();
              resultFile = file;
              Navigator.of(context).pop();
            }

            // Hàm bắt đầu đếm thời gian
            void startTimer() {
              isRecording = true;
              Future.delayed(const Duration(seconds: 1), () {
                if (isRecording) {
                  setState(() {
                    recordingDuration++;
                  });
                  // Kiểm tra thời gian tối đa (5 phút)
                  if (recordingDuration >= 300) {
                    stopAndSave();
                  } else {
                    startTimer();
                  }
                }
              });
            }

            // Bắt đầu ghi âm khi hiển thị dialog
            _mediaService.startAudioRecording().then((success) {
              if (success) {
                startTimer();
              } else {
                Navigator.of(context).pop();
              }
            });

            // Định dạng thời gian hiển thị
            String formatDuration(int seconds) {
              final minutes = seconds ~/ 60;
              final remainingSeconds = seconds % 60;
              return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
            }

            return AlertDialog(
              title: const Text('Đang ghi âm'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.mic,
                    color: Colors.red,
                    size: 50,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    formatDuration(recordingDuration),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Đang ghi âm... Nhấn Lưu khi hoàn tất.'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    isRecording = false;
                    _mediaService.cancelAudioRecording();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Hủy'),
                ),
                TextButton(
                  onPressed: stopAndSave,
                  child: const Text('Lưu'),
                ),
              ],
            );
          },
        );
      },
    );

    return resultFile;
  }
}
