import 'package:flutter/material.dart';
import 'package:flux_localization/flux_localization.dart';
import 'package:provider/provider.dart';

import '../../../../common/constants.dart';
import '../../../../models/user_model.dart';
import '../../../../widgets/common/user_avatar_by_name_widget.dart';

class ShopifyAccountScreen extends StatelessWidget {
  const ShopifyAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = context.read<UserModel>().user!;

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).shopifyAccountManagement),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _UserProfileCard(),
            const SizedBox(height: 24),
            _ActionCard(
              icon: Icons.person_outline,
              title: S.of(context).personalInformation,
              subtitle: S.of(context).personalInformationSubtitle,
              onTap: () => _navigateToPersonalInfo(context),
            ),
            if (user.allowChangePassword && user.isSocial != true) ...[
              const SizedBox(height: 12),
              _ActionCard(
                icon: Icons.lock_outline,
                title: S.of(context).changePassword,
                subtitle: S.of(context).changePasswordSubtitle,
                onTap: () => _navigateToChangePassword(context),
              )
            ],
            const SizedBox(height: 12),
            _ActionCard(
              icon: Icons.location_on_outlined,
              title: S.of(context).addressManagement,
              subtitle: S.of(context).addressManagementSubtitle,
              onTap: () => _navigateToAddressManagement(context),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToPersonalInfo(BuildContext context) {
    Navigator.pushNamed(context, RouteList.personalInfo);
  }

  void _navigateToChangePassword(BuildContext context) {
    Navigator.pushNamed(context, RouteList.changePassword);
  }

  void _navigateToAddressManagement(BuildContext context) {
    Navigator.pushNamed(context, RouteList.addressManagement);
  }
}

class _UserProfileCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Consumer<UserModel>(
      builder: (context, userModel, child) {
        final user = userModel.user;

        if (user == null) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Avatar
              UserAvatarByNameWidget(
                user: user,
                size: 80,
              ),
              const SizedBox(height: 16),

              // User Name
              Text(
                user.name ?? S.of(context).undefined,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),

              // Email
              if (user.email?.isNotEmpty == true)
                Text(
                  user.email!,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.2),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: colorScheme.onPrimaryContainer,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow
              Icon(
                Icons.arrow_forward_ios,
                color: colorScheme.onSurfaceVariant,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
