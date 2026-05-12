import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';

class WelcomeCustomerScreen extends StatelessWidget {
  const WelcomeCustomerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          // Top black section
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipPath(
              clipper: TopDiagonalClipper(),
              child: Container(
                height: 250,
                color: AppColors.primary,
              ),
            ),
          ),
          // Bottom black section
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipPath(
              clipper: BottomDiagonalClipper(),
              child: Container(
                height: 250,
                color: AppColors.primary,
              ),
            ),
          ),
          // Center Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () => context.push('/landing'), // Navigate to the next welcome screen
                  child: Image.asset(
                    'assets/logo.png',
                    width: 280,
                    height: 280,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.shopping_bag, size: 150),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'H A J A',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 10,
                    color: AppColors.black,
                  ),
                ),
                const Text(
                  'Rentals & Apparel',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w300,
                    color: AppColors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TopDiagonalClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height * 0.7);
    path.quadraticBezierTo(size.width * 0.5, size.height * 1.2, size.width, size.height * 0.5);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class BottomDiagonalClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.moveTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, size.height * 0.3);
    path.quadraticBezierTo(size.width * 0.5, -size.height * 0.2, 0, size.height * 0.5);
    path.close();
    return path;
  }
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
