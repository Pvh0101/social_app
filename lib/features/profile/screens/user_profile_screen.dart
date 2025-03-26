import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:social_app/features/chat/presentation/widgets/message_button.dart';

import '../../../core/constants/routes_constants.dart';
import '../../../core/widgets/display_user_image.dart';
import '../../../core/widgets/buttons/round_button_fill.dart';
import '../../authentication/authentication.dart';
import '../../friends/presentation/widgets/friendship_button.dart';
import './user_posts_screen.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  final String userId;

  const UserProfileScreen({
    super.key,
    required this.userId,
  });

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final userStream =
        ref.watch(getUserInfoAsStreamByIdProvider(widget.userId));
    final currentUserStream = ref.watch(getUserInfoAsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: userStream.when(
          data: (user) => Text(user.fullName),
          loading: () => const Text('Đang tải...'),
          error: (_, __) => const Text('Lỗi'),
        ),
      ),
      body: SingleChildScrollView(
        child: userStream.when(
          data: (user) => currentUserStream.when(
            data: (currentUser) => Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Profile Image - Centered and Larger
                  DisplayUserImage(
                    imageUrl: user.profileImage,
                    userName: user.fullName,
                    radius: 50,
                    isOnline: user.isOnline,
                  ),
                  const SizedBox(height: 16),

                  // Username
                  Text(
                    user.fullName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),

                  // User Email
                  Text(
                    user.email,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                  const SizedBox(height: 16),

                  // Bio
                  if (user.decs != null && user.decs!.isNotEmpty)
                    Text(
                      user.decs!,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 16),

                  // Personal Information
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (user.birthDay != null) ...[
                          _buildInfoItem(
                            context: context,
                            icon: Icons.cake_outlined,
                            label: 'Ngày sinh:',
                            value:
                                DateFormat('dd/MM/yyyy').format(user.birthDay!),
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (user.phoneNumber != null) ...[
                          _buildInfoItem(
                            context: context,
                            icon: Icons.phone_outlined,
                            label: 'Điện thoại:',
                            value: user.phoneNumber!,
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (user.address != null)
                          _buildInfoItem(
                            context: context,
                            icon: Icons.location_on_outlined,
                            label: 'Địa chỉ:',
                            value: user.address!,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Interaction Buttons
                  if (currentUser.uid != user.uid) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: FriendshipButton(userId: user.uid),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: MessageButton(
                            otherUserId: user.uid,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.more_vert),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              builder: (context) => Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.flag_outlined),
                                    title: const Text('Báo cáo'),
                                    onTap: () {
                                      Navigator.pop(context);
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.block_outlined),
                                    title: const Text('Chặn người dùng'),
                                    onTap: () {
                                      Navigator.pop(context);
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ] else ...[
                    SizedBox(
                      width: double.infinity,
                      child: RoundButtonFill(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            RouteConstants.userInformation,
                            arguments: {'isEditing': true},
                          );
                        },
                        label: 'Chỉnh sửa hồ sơ',
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Nút xem bài viết
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UserPostsScreen(
                              userId: user.uid,
                              userName: user.fullName,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.grid_on),
                      label: const Text('Xem tất cả bài viết'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Center(child: Text('Lỗi')),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Lỗi: $error')),
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
