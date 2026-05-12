import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../config/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_widgets.dart';

class LoginCustomerScreen extends ConsumerStatefulWidget {
  const LoginCustomerScreen({super.key});

  @override
  ConsumerState<LoginCustomerScreen> createState() => _LoginCustomerScreenState();
}

class _LoginCustomerScreenState extends ConsumerState<LoginCustomerScreen> {
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
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: screenHeight * 0.06),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, size: 30),
              onPressed: () => context.go(RouteName.landing),
            ),
          ),
          SizedBox(height: screenHeight * 0.02),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 30),
            child: Text(
              'Sign In',
              style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 30),
            child: Text(
              'Welcome back. Let\'s find your perfect style.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),
          SizedBox(height: screenHeight * 0.04),
          // Dark Container
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
              decoration: const BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(50),
                  topRight: Radius.circular(50),
                ),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    AppTextField(
                      label: '',
                      hint: 'Email',
                      controller: _emailController,
                      fillColor: AppColors.white,
                    ),
                    const SizedBox(height: 15),
                    AppTextField(
                      label: '',
                      hint: 'Password',
                      controller: _passwordController,
                      obscureText: true,
                      fillColor: AppColors.white,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        child: const Text('Forgot Password?', style: TextStyle(color: AppColors.textDark, fontSize: 12)),
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            await ref.read(authProvider.notifier).login(
                              _emailController.text,
                              _passwordController.text,
                            );
                            
                            if (!context.mounted) return;
                            
                            if (ref.read(authProvider).error != null) {
                              await AppAlert.showError(context, ref.read(authProvider).error!);
                            } else {
                              await AppAlert.showSuccess(context, 'Login Successful!');
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                        ),
                        child: const Text('Sign In', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const TextDivider(text: 'or', textColor: AppColors.textDark),
                    const SizedBox(height: 20),
                    // Google Button
                    SocialLoginButton(
                      label: 'Continue with Google',
                      onPressed: () => ref.read(authProvider.notifier).signInWithGoogle(),
                      iconPath: 'assets/images/google.webp',
                    ),
                    const SizedBox(height: 10),
                    // Facebook Button
                    SocialLoginButton(
                      label: 'Continue with Facebook',
                      onPressed: () => AppAlert.showInfo(context, 'Facebook Sign-In is coming soon!'),
                      iconPath: 'assets/images/facebook.png',
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have account? ", style: TextStyle(color: AppColors.textDark, fontSize: 12)),
                        GestureDetector(
                          onTap: () => context.go('/signup'),
                          child: const Text("Sign Up", style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
