import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../config/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_widgets.dart';

class LoginSellerScreen extends ConsumerStatefulWidget {
  const LoginSellerScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _LoginSellerScreenState();
}

class _LoginSellerScreenState extends ConsumerState<LoginSellerScreen> {
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          // Top Text Section
          Positioned(
            top: size.height * 0.08,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go(RouteName.landing);
                    }
                  },
                  child: const Icon(
                    Icons.arrow_back,
                    color: AppColors.black,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'Sign In',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  'Welcome back! Sign in to manage\nyour listings, track orders, and grow\nyour rental business.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textDark,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),

          // Bottom Dark Container Form Section
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: size.height * 0.6,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(37),
                  topRight: Radius.circular(37),
                ),
              ),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Error message
                      if (authState.error != null) ...[
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            authState.error!,
                            style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                      ],

                      // Full Name Field (Email Controller logic kept for now)
                      TextFormField(
                        controller: _emailController,
                        style: const TextStyle(color: AppColors.white),
                        decoration: InputDecoration(
                          hintText: 'Full Name',
                          hintStyle: const TextStyle(
                            fontFamily: 'Inter',
                            color: AppColors.textPlaceholder,
                          ),
                          filled: true,
                          fillColor: AppColors.inputBackground.withValues(
                            alpha: 0.3,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(32),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 25,
                            vertical: 20,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your full name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        style: const TextStyle(color: AppColors.white),
                        decoration: InputDecoration(
                          hintText: 'Password',
                          hintStyle: const TextStyle(
                            fontFamily: 'Inter',
                            color: AppColors.textPlaceholder,
                          ),
                          filled: true,
                          fillColor: AppColors.inputBackground.withValues(
                            alpha: 0.3,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(32),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 25,
                            vertical: 20,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),

                      // Forgot Password
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Forgot Password?',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Sign In Button
                      SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              await ref
                                  .read(authProvider.notifier)
                                  .login(
                                    _emailController.text,
                                    _passwordController.text,
                                  );
                              
                              final state = ref.read(authProvider);
                              if (state.isAuthenticated && state.error == null && context.mounted) {
                                AppAlert.showSuccess(context, 'Shop access granted. Welcome back!');
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.white,
                            foregroundColor: AppColors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(32),
                            ),
                          ),
                          child: authState.isLoading
                              ? const CircularProgressIndicator()
                              : const Text(
                                  'Sign In',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Sign Up Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Don\'t have account? ',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              color: AppColors.textPlaceholder,
                              fontSize: 14,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => context.go('/signup?role=seller'),
                            child: const Text(
                              'Sign Up',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                color: AppColors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
