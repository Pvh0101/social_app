import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

import '../../../../core/utils/global_method.dart';
import '../../../../core/widgets/display_user_image.dart';
import '../../../friends/providers/get_all_friends_provider.dart';
import '../../../authentication/providers/get_user_info_as_stream_by_id_provider.dart';
import '../../providers/chat_providers.dart';
import 'chat_screen.dart';

// Constants for logging
const String _logTag = 'CreateGroupScreen';

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

  @override
  void initState() {
    super.initState();
    print('[$_logTag] initState - Screen initialized');
  }

  @override
  void dispose() {
    print('[$_logTag] dispose - Cleaning up resources');
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    print('[$_logTag] _pickImage - Starting image picker');
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      print('[$_logTag] _pickImage - Image selected: ${pickedFile.path}');
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressQuality: 70,
        maxWidth: 500,
        maxHeight: 500,
        compressFormat: ImageCompressFormat.jpg,
      );

      if (croppedFile != null) {
        print('[$_logTag] _pickImage - Image cropped: ${croppedFile.path}');
        setState(() {
          _groupImage = File(croppedFile.path);
        });
      } else {
        print('[$_logTag] _pickImage - Cropping cancelled');
      }
    } else {
      print('[$_logTag] _pickImage - No image selected');
    }
  }

  Future<void> _createGroup() async {
    print('[$_logTag] _createGroup - Starting group creation');
    print('[$_logTag] _createGroup - Group name: ${_nameController.text}');
    print('[$_logTag] _createGroup - Is public: $_isPublic');
    print(
        '[$_logTag] _createGroup - Selected members: ${_selectedMembers.length}');
    print('[$_logTag] _createGroup - Has image: ${_groupImage != null}');

    if (!_formKey.currentState!.validate()) {
      print('[$_logTag] _createGroup - Form validation failed');
      return;
    }

    if (_selectedMembers.isEmpty) {
      print('[$_logTag] _createGroup - No members selected');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng chọn ít nhất một thành viên')),
        );
      }
      return;
    }

    if (!mounted) {
      print('[$_logTag] _createGroup - Widget not mounted');
      return;
    }

    setState(() {
      _isLoading = true;
    });
    print('[$_logTag] _createGroup - Loading state set to true');

    try {
      String? avatarUrl;

      // Tải lên ảnh nhóm nếu có
      if (_groupImage != null) {
        print('[$_logTag] _createGroup - Uploading group image');
        avatarUrl = await uploadFileToFirebase(
          file: _groupImage!,
          reference: 'group_images/${DateTime.now().millisecondsSinceEpoch}',
        );
        print('[$_logTag] _createGroup - Image uploaded, URL: $avatarUrl');
      }

      if (!mounted) {
        print(
            '[$_logTag] _createGroup - Widget not mounted after image upload');
        return;
      }

      // Tạo nhóm chat
      final params = CreateGroupChatParams(
        name: _nameController.text.trim(),
        avatar: avatarUrl,
        members: _selectedMembers.toList(),
        isPublic: _isPublic,
      );
      print('[$_logTag] _createGroup - Creating group with params: $params');

      final chatId = await ref.read(createGroupChatProvider(params).future);
      print(
          '[$_logTag] _createGroup - Group created successfully with ID: $chatId');

      if (!mounted) {
        print(
            '[$_logTag] _createGroup - Widget not mounted after group creation');
        return;
      }

      // Đặt _isLoading = false trước khi điều hướng
      setState(() {
        _isLoading = false;
      });
      print('[$_logTag] _createGroup - Loading state set to false');

      // Sửa phương thức điều hướng để tránh lỗi animation
      print(
          '[$_logTag] _createGroup - Navigating to chat screen with safer navigation');
      if (mounted) {
        // Sử dụng Navigator.of(context).pushReplacement thay vì pushAndRemoveUntil
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
      print('[$_logTag] _createGroup - Error: $e');
      if (!mounted) {
        print('[$_logTag] _createGroup - Widget not mounted after error');
        return;
      }

      setState(() {
        _isLoading = false;
      });
      print('[$_logTag] _createGroup - Loading state set to false after error');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    print('[$_logTag] build - Rebuilding UI');
    final friendsAsync = ref.watch(getAllFriendsProvider);
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    print('[$_logTag] build - Current user ID: $currentUserId');

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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ảnh nhóm
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey[300],
                          backgroundImage: _groupImage != null
                              ? FileImage(_groupImage!)
                              : null,
                          child: _groupImage == null
                              ? const Icon(
                                  Icons.group,
                                  size: 50,
                                  color: Colors.grey,
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Tên nhóm
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên nhóm',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      print('[$_logTag] Form validation - Group name is empty');
                      return 'Vui lòng nhập tên nhóm';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Loại nhóm
                Row(
                  children: [
                    const Text('Loại nhóm:'),
                    const SizedBox(width: 16),
                    ChoiceChip(
                      label: const Text('Công khai'),
                      selected: _isPublic,
                      onSelected: (selected) {
                        print(
                            '[$_logTag] Group type changed to Public: $selected');
                        setState(() {
                          _isPublic = selected;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Riêng tư'),
                      selected: !_isPublic,
                      onSelected: (selected) {
                        print(
                            '[$_logTag] Group type changed to Private: $selected');
                        setState(() {
                          _isPublic = !selected;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Danh sách bạn bè
                const Text(
                  'Chọn thành viên:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                friendsAsync.when(
                  data: (friendIds) {
                    print(
                        '[$_logTag] friendsAsync - Loaded ${friendIds.length} friends');
                    if (friendIds.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'Bạn chưa có bạn bè nào',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: friendIds.length,
                      itemBuilder: (context, index) {
                        final friendId = friendIds[index];
                        final isSelected = _selectedMembers.contains(friendId);
                        final friendStream = ref
                            .watch(getUserInfoAsStreamByIdProvider(friendId));

                        return friendStream.when(
                          data: (friend) {
                            return CheckboxListTile(
                              title: Text(friend.fullName),
                              subtitle: Text(friend.email ?? ''),
                              secondary: DisplayUserImage(
                                imageUrl: friend.profileImage,
                                userName: friend.fullName,
                                radius: 20,
                              ),
                              value: isSelected,
                              onChanged: (value) {
                                print(
                                    '[$_logTag] Member selection changed - Friend: ${friend.fullName}, Selected: $value');
                                setState(() {
                                  if (value == true) {
                                    _selectedMembers.add(friendId);
                                  } else {
                                    _selectedMembers.remove(friendId);
                                  }
                                });
                                print(
                                    '[$_logTag] Selected members count: ${_selectedMembers.length}');
                              },
                            );
                          },
                          loading: () => const ListTile(
                            leading: CircleAvatar(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            title: Text('Đang tải...'),
                          ),
                          error: (error, stack) {
                            print(
                                '[$_logTag] Error loading friend info - Friend ID: $friendId, Error: $error');
                            return ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.error),
                              ),
                              title: const Text('Lỗi'),
                              subtitle: Text(error.toString()),
                            );
                          },
                        );
                      },
                    );
                  },
                  loading: () {
                    print('[$_logTag] friendsAsync - Loading friends list');
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  },
                  error: (error, stack) {
                    print('[$_logTag] friendsAsync - Error: $error');
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text('Lỗi: $error'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
