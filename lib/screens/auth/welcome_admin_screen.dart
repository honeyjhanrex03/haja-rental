import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../config/app_sizes.dart';
import '../../widgets/app_widgets.dart';

class WelcomeAdminScreen extends StatelessWidget {
  const WelcomeAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                    Image.asset(
                      'assets/logo.png',
                      width: 150,
                      height: 150,
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
                      'Welcome Back, Admin',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            fontSize: 32,
                            color: AppColors.textDark,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSizes.lg),
                    Text(
                      'Manage the platform, oversee users, and ensure smooth operations.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 16,
                            color: AppColors.textPlaceholder,
                            height: 1.5,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.xl),

                // Buttons
                Column(
                  children: [
                    PrimaryButton(
                      text: 'Sign In',
                      onPressed: () => context.go('/login?role=admin'),
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
