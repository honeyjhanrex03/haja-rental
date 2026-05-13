import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../config/app_router.dart';
import '../../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Check if user is already logged in
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).checkAuthStatus();
    });
    _navigateToNext();
  }

  void _navigateToNext() async {
    // Wait for 3 seconds then go to landing
    await Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        final authState = ref.read(authProvider);
        if (!authState.isAuthenticated) {
          context.go(RouteName.landing);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          // Top beige section
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipPath(
              clipper: TopDiagonalClipper(),
              child: Container(
                height: 250,
                color: AppColors.beige,
              ),
            ),
          ),
          // Bottom beige section
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipPath(
              clipper: BottomDiagonalClipper(),
              child: Container(
                height: 250,
                color: AppColors.beige,
              ),
            ),
          ),
          // Center Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/logo.png',
                  width: 350,
                  height: 350,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.shopping_bag, size: 150),
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
