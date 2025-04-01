import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/global_method.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../../services/chatroom_service.dart';
import '../widgets/chat_widgets.dart';
import 'chat_screen.dart';

// Widget cho các tùy chọn của nhóm
class GroupOptionsSection extends StatelessWidget {
  final bool isPublic;
  final ValueChanged<bool> onPublicChanged;

  const GroupOptionsSection({
    Key? key,
    required this.isPublic,
    required this.onPublicChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('Loại nhóm:'),
        const SizedBox(width: 16),
        ChoiceChip(
          label: const Text('Công khai'),
          selected: isPublic,
          onSelected: (selected) {
            if (selected) {
              onPublicChanged(true);
            }
          },
        ),
        const SizedBox(width: 8),
        ChoiceChip(
          label: const Text('Riêng tư'),
          selected: !isPublic,
          onSelected: (selected) {
            if (selected) {
              onPublicChanged(false);
            }
          },
        ),
      ],
    );
  }
}

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _selectedMembers = <String>{};
  File? _groupImage;
  bool _isPublic = true;
  bool _isLoading = false;
  // ignore: unused_field
  final _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onImageSelected(File file) {
    setState(() {
      _groupImage = file;
    });
  }

  void _onFriendToggled(String friendId) {
    setState(() {
      if (_selectedMembers.contains(friendId)) {
        _selectedMembers.remove(friendId);
      } else {
        _selectedMembers.add(friendId);
      }
    });
  }

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Sử dụng ChatroomService để tạo nhóm
      final chatroomService = ref.read(chatroomServiceProvider);
      final chatId = await chatroomService.createGroupChat(
        name: _nameController.text,
        members: _selectedMembers.toList(),
        isPublic: _isPublic,
        groupImage: _groupImage,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      if (chatId != null && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              chatId: chatId,
              isGroup: true,
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      showToastMessage(text: 'Lỗi: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo nhóm chat'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _createGroup,
            ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sử dụng GroupImagePicker thay vì GroupHeaderSection
                  Center(
                    child: GroupImagePicker(
                      selectedImage: _groupImage,
                      onImageSelected: _onImageSelected,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Sử dụng GroupNameField thay vì TextFormField trực tiếp
                  GroupNameField(
                    controller: _nameController,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập tên nhóm';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Phần cài đặt loại nhóm (công khai/riêng tư)
                  GroupOptionsSection(
                    isPublic: _isPublic,
                    onPublicChanged: (value) {
                      setState(() {
                        _isPublic = value;
                      });
                    },
                  ),
                  const SizedBox(height: 24),

                  // Sử dụng FriendSelectionList thay vì FriendSelectionSection
                  FriendSelectionList(
                    selectedIds: _selectedMembers,
                    onFriendToggled: _onFriendToggled,
                    useCheckbox: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
