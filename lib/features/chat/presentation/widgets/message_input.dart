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
      final mediaUrl = await ref.read(uploadMediaProvider(
        UploadMediaParams(
          chatId: widget.chatId,
          file: _selectedMedia!,
        ),
      ).future);

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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Container(
              constraints: const BoxConstraints(
                maxHeight: 300, // Giới hạn chiều cao tối đa
                minHeight: 100, // Đảm bảo chiều cao tối thiểu
              ),
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
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
                    // Nút media tích hợp
                    SimpleMediaPicker(
                      onMediaSelected: _handleMediaSelected,
                      iconColor: colorScheme.primary,
                      iconSize: 24,
                      title: 'Chọn media',
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
                              // Hiển thị biểu tượng media nếu có file được chọn
                              if (_selectedMedia != null)
                                Padding(
                                  padding: const EdgeInsets.only(right: 4.0),
                                  child: Icon(
                                    _getMediaIcon(),
                                    color: colorScheme.primary,
                                    size: 18,
                                  ),
                                ),
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

  // Lấy biểu tượng dựa trên loại media
  IconData _getMediaIcon() {
    switch (_selectedMediaType) {
      case MessageType.image:
        return Icons.image;
      case MessageType.video:
        return Icons.videocam;
      case MessageType.audio:
        return Icons.audiotrack;
      default:
        return Icons.attach_file;
    }
  }

  Future<void> _selectMedia() async {
    try {
      // Hiển thị bottom sheet để chọn media
      showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return SafeArea(
            child: Wrap(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: const Text('Chụp ảnh mới'),
                  onTap: () async {
                    Navigator.pop(context);
                    final mediaService = MediaService();
                    final file = await mediaService.pickImageFromCamera();
                    if (file != null) {
                      _handleMediaSelected(file, MediaType.image);
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Chọn ảnh từ thư viện'),
                  onTap: () async {
                    Navigator.pop(context);
                    final mediaService = MediaService();
                    final files = await mediaService.pickImagesFromGallery(
                      multiple: false,
                    );
                    if (files.isNotEmpty) {
                      _handleMediaSelected(files.first, MediaType.image);
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.video_library),
                  title: const Text('Chọn video từ thư viện'),
                  onTap: () async {
                    Navigator.pop(context);
                    final mediaService = MediaService();
                    final file = await mediaService.pickVideoFromGallery();
                    if (file != null) {
                      _handleMediaSelected(file, MediaType.video);
                    }
                  },
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      showToastMessage(text: 'Lỗi khi chọn media: $e');
    }
  }

  // Hiển thị dialog ghi âm
  Future<File?> _showAudioRecordingDialog() async {
    final mediaService = MediaService();
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
              final file = await mediaService.stopAudioRecording();
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
            mediaService.startAudioRecording().then((success) {
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
                    mediaService.cancelAudioRecording();
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
