import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../config/app_router.dart';
import '../../widgets/app_widgets.dart';

class LandingScreen extends ConsumerWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          // Logo Section (Top 45% of screen)
          Expanded(
            flex: 45,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Image.asset(
                  'assets/logo.png',
                  height: screenHeight * 0.35,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.shopping_bag, size: 100),
                ),
              ],
            ),
          ),
          // Beige Bottom Container (Bottom 55% of screen)
          Expanded(
            flex: 55,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
              decoration: const BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(50), 
                  topRight: Radius.circular(50),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome', 
                    style: TextStyle(
                      fontSize: 32, 
                      fontWeight: FontWeight.bold, 
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Expanded(
                    child: Text(
                      'A place where style meets elegance. Discover beautiful outfits, rent with ease, and shine on every special occasion."',
                      style: TextStyle(
                        fontSize: 15, 
                        color: AppColors.textDark, 
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: PrimaryButton(
                          text: 'Sign In',
                          backgroundColor: AppColors.white,
                          textColor: AppColors.textDark,
                          onPressed: () => context.push(RouteName.login),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: PrimaryButton(
                          text: 'Sign Up',
                          backgroundColor: AppColors.primary,
                          textColor: AppColors.white,
                          onPressed: () => context.push(RouteName.signup),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
