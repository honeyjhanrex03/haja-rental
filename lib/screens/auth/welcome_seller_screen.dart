import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';

class WelcomeSellerScreen extends StatelessWidget {
  const WelcomeSellerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          // Top Logo Section
          Positioned(
            top: size.height * 0.1,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Image.asset(
                  'assets/logo.png',
                  height: size.height * 0.25,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 10),
                const Text(
                  'H A J A',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 48,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),
                ),
                const Text(
                  'Rentals & Apparel',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 27,
                    fontWeight: FontWeight.w200,
                    color: AppColors.black,
                  ),
                ),
              ],
            ),
          ),
          
          // Bottom Dark Container Section
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: size.height * 0.55,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 50),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(37),
                  topRight: Radius.circular(37),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome, Seller',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 27,
                      fontWeight: FontWeight.w900,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Turn your wardrobe into income.\nList your outfits, manage rentals,\nand connect with customers\nlooking for stylish pieces.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: AppColors.white,
                      height: 1.5,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 58,
                          child: ElevatedButton(
                            onPressed: () => context.go('/login?role=seller'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.inputBackground,
                              foregroundColor: AppColors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(32),
                              ),
                            ),
                            child: const Text(
                              'Sign In',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: SizedBox(
                          height: 58,
                          child: ElevatedButton(
                            onPressed: () => context.go('/signup?role=seller'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.white,
                              foregroundColor: AppColors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(32),
                              ),
                            ),
                            child: const Text(
                              'Sign Up',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
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
