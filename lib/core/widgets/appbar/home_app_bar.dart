import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onAddPressed;

  const HomeAppBar({
    super.key,
    required this.title,
    this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      actions: [
        _buildIconButton(
          icon: const Icon(CupertinoIcons.add),
          onPressed: onAddPressed ?? () {},
        ),
        _buildIconButton(
          icon: const Icon(CupertinoIcons.chat_bubble_2),
          onPressed: () {
            // TODO: Implement messenger action
          },
        ),
        _buildIconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () =>
              Navigator.pushNamed(context, RouteConstants.settingsScreen),
        ),
      ],
    );
  }

  Widget _buildIconButton({
    required Icon icon,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      icon: icon,
      onPressed: onPressed,
      splashRadius: 24,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
