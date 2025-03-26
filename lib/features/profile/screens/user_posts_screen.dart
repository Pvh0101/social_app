import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../posts/screens/feed_screen.dart';

class UserPostsScreen extends ConsumerWidget {
  final String userId;
  final String userName;

  const UserPostsScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bài viết của $userName'),
      ),
      body: FeedScreen(
        userId: userId,
        showAppBar: false,
      ),
    );
  }
}
