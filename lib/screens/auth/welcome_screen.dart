import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../config/app_sizes.dart';
import '../../widgets/app_widgets.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  String? selectedRole;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            constraints: BoxConstraints(minHeight: screenHeight),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.md,
              vertical: AppSizes.lg,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Logo section
                Column(
                  children: [
                    // Logo placeholder
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                      ),
                      child: Center(
                        child: Text(
                          'H A J A',
                          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                color: AppColors.white,
                                fontSize: 40,
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.md),
                    Text(
                      'Rentals & Apparel',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: 20,
                            color: AppColors.textDark,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.xl),

                // Welcome message
                Column(
                  children: [
                    Text(
                      'Welcome to HAJA',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            fontSize: 28,
                            color: AppColors.textDark,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSizes.md),
                    Text(
                      'Choose your role to get started',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 16,
                            color: AppColors.textPlaceholder,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.xl),

                // Role selection
                ResponsiveRoleSelector(
                  isMobile: isMobile,
                  onRoleSelected: (role) {
                    setState(() {
                      selectedRole = role;
                    });
                  },
                ),
                const SizedBox(height: AppSizes.xl),

                // Buttons
                Column(
                  children: [
                    PrimaryButton(
                      text: 'Sign In',
                      onPressed: selectedRole != null
                          ? () => context.go('/login?role=$selectedRole')
                          : () {},
                    ),
                    const SizedBox(height: AppSizes.md),
                    SecondaryButton(
                      text: 'Sign Up',
                      onPressed: selectedRole != null
                          ? () => context.go('/signup?role=$selectedRole')
                          : () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ResponsiveRoleSelector extends StatelessWidget {
  final bool isMobile;
  final Function(String) onRoleSelected;

  const ResponsiveRoleSelector({
    super.key,
    required this.isMobile,
    required this.onRoleSelected,
  });

  @override
  Widget build(BuildContext context) {
    final roles = [
      {
        'label': 'Customer',
        'description': 'Browse & rent items',
        'value': 'customer',
        'icon': Icons.shopping_bag,
      },
      {
        'label': 'Seller',
        'description': 'Manage & sell items',
        'value': 'seller',
        'icon': Icons.store,
      },
      {
        'label': 'Admin',
        'description': 'Manage platform',
        'value': 'admin',
        'icon': Icons.admin_panel_settings,
      },
    ];

    if (isMobile) {
      return Column(
        children: roles.map((role) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.md),
            child: RoleCard(
              label: role['label'] as String,
              description: role['description'] as String,
              icon: role['icon'] as IconData,
              onTap: () => onRoleSelected(role['value'] as String),
            ),
          );
        }).toList(),
      );
    } else {
      return Row(
        children: roles.map((role) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm),
              child: RoleCard(
                label: role['label'] as String,
                description: role['description'] as String,
                icon: role['icon'] as IconData,
                onTap: () => onRoleSelected(role['value'] as String),
              ),
            ),
          );
        }).toList(),
      );
    }
  }
}

class RoleCard extends StatelessWidget {
  final String label;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  const RoleCard({
    super.key,
    required this.label,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Column(
            children: [
              Icon(
                icon,
                size: 48,
                color: AppColors.primary,
              ),
              const SizedBox(height: AppSizes.md),
              Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
              ),
              const SizedBox(height: AppSizes.sm),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textPlaceholder,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
