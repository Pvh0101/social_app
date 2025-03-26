import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/core.dart';
import '../../../authentication/models/user_model.dart';
import '../../../authentication/presentation/screens/user_information_screen.dart';
import '../../../authentication/providers/auth_provider.dart';
import '../../../authentication/providers/get_user_info_as_stream_provider.dart';

class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userStream = ref.watch(getUserInfoAsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Menu'),
      ),
      body: userStream.when(
        data: (user) => _buildMenuContent(context, ref, user),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text(error.toString())),
      ),
    );
  }

  Widget _buildMenuContent(
      BuildContext context, WidgetRef ref, UserModel? user) {
    if (user == null) return const SizedBox.shrink();

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        // User Profile Section
        _buildUserProfileSection(context, user),
        const Divider(),

        // Account Section
        _buildSectionTitle(context, 'menu_sections.account'.tr()),
        _buildMenuItem(
          context: context,
          icon: Icons.person_outline,
          title: 'menu_items.edit_profile'.tr(),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  const UserInformationScreen(isEditing: true),
            ),
          ),
        ),
        _buildMenuItem(
          context: context,
          icon: Icons.people_outline,
          title: 'menu_items.manage_friends'.tr(),
          onTap: () => Navigator.pushNamed(context, RouteConstants.friends),
        ),

        const Divider(),

        // Preferences Section
        _buildSectionTitle(context, 'menu_sections.preferences'.tr()),
        _buildMenuItem(
          context: context,
          icon: Icons.language_outlined,
          title: 'menu_items.change_language'.tr(),
          onTap: () => _showLanguageDialog(context),
        ),
        _buildMenuItem(
          context: context,
          icon: Icons.palette_outlined,
          title: 'menu_items.change_theme'.tr(),
          onTap: () =>
              Navigator.pushNamed(context, RouteConstants.themeSettings),
        ),
        _buildMenuItem(
          context: context,
          icon: Icons.notifications_outlined,
          title: 'menu_items.manage_notifications'.tr(),
          onTap: () {
            // TODO: Implement notifications settings
            showToastMessage(text: 'Tính năng đang được phát triển');
          },
        ),

        const Divider(),

        // Other Section
        _buildSectionTitle(context, 'menu_sections.other'.tr()),
        _buildMenuItem(
          context: context,
          icon: Icons.info_outline,
          title: 'menu_items.view_about'.tr(),
          onTap: () => _showAboutDialog(context),
        ),
        _buildMenuItem(
          context: context,
          icon: Icons.privacy_tip_outlined,
          title: 'menu_items.view_privacy'.tr(),
          onTap: () {
            // TODO: Implement privacy policy screen
            showToastMessage(text: 'Tính năng đang được phát triển');
          },
        ),
        _buildMenuItem(
          context: context,
          icon: Icons.description_outlined,
          title: 'menu_items.view_terms'.tr(),
          onTap: () {
            // TODO: Implement terms and conditions screen
            showToastMessage(text: 'Tính năng đang được phát triển');
          },
        ),
        _buildMenuItem(
          context: context,
          icon: Icons.logout,
          title: 'menu_items.sign_out'.tr(),
          iconColor: Colors.red,
          textColor: Colors.red,
          onTap: () => _handleLogout(context, ref),
        ),

        // App Version
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'v1.0.0',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildUserProfileSection(BuildContext context, UserModel user) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          DisplayUserImage(
            userName: user.fullName,
            imageUrl: user.profileImage,
            radius: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(
        title,
        style: textColor != null ? TextStyle(color: textColor) : null,
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('auth.logout.title'.tr()),
        content: Text('auth.logout.confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text('auth.logout.title'.tr()),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (!context.mounted) return;

    try {
      await ref.read(authProvider).logout();

      if (!context.mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        RouteConstants.login,
        (route) => false,
      );
    } catch (e) {
      if (!context.mounted) return;
      showToastMessage(text: e.toString());
    }
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('menu_items.change_language'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Tiếng Việt'),
              onTap: () {
                context.setLocale(const Locale('vi'));
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('English'),
              onTap: () {
                context.setLocale(const Locale('en'));
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Social App',
      applicationVersion: 'v1.0.0',
      applicationIcon: const FlutterLogo(size: 50),
      children: [
        const Text(
          'Một ứng dụng mạng xã hội đơn giản được xây dựng bằng Flutter và Firebase.',
        ),
      ],
    );
  }
}
