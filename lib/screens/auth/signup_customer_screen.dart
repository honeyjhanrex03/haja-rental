import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../config/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_widgets.dart';

class SignupCustomerScreen extends ConsumerStatefulWidget {
  const SignupCustomerScreen({super.key});

  @override
  ConsumerState<SignupCustomerScreen> createState() => _SignupCustomerScreenState();
}

class _SignupCustomerScreenState extends ConsumerState<SignupCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  UserRole _selectedRole = UserRole.customer;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SingleChildScrollView(
        child: SizedBox(
          height: screenHeight,
          child: Column(
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
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 30),
                child: Text(
                  'Sign Up',
                  style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 30),
                child: Text(
                  'Join HAJA. Select your role to get started.',
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
                        // Role Selection Toggle
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _selectedRole = UserRole.customer),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: _selectedRole == UserRole.customer ? AppColors.primary : Colors.transparent,
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Customer',
                                        style: TextStyle(
                                          color: _selectedRole == UserRole.customer ? AppColors.white : AppColors.textDark,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _selectedRole = UserRole.seller),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: _selectedRole == UserRole.seller ? AppColors.primary : Colors.transparent,
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Seller',
                                        style: TextStyle(
                                          color: _selectedRole == UserRole.seller ? AppColors.white : AppColors.textDark,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        AppTextField(
                          label: '',
                          hint: 'Email Address',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          fillColor: AppColors.white,
                          validator: (v) => v!.contains('@') ? null : 'Enter a valid email',
                        ),
                        const SizedBox(height: 10),
                        AppTextField(
                          label: '',
                          hint: 'Password',
                          controller: _passwordController,
                          obscureText: true,
                          fillColor: AppColors.white,
                          validator: (v) => v!.length >= 6 ? null : 'Password too short',
                        ),
                        const SizedBox(height: 10),
                        AppTextField(
                          label: '',
                          hint: 'Confirm Password',
                          controller: _confirmPasswordController,
                          obscureText: true,
                          fillColor: AppColors.white,
                          validator: (v) => v == _passwordController.text ? null : 'Passwords do not match',
                        ),
                        const SizedBox(height: 10),
                        AppTextField(
                          label: '',
                          hint: 'Full Name',
                          controller: _fullNameController,
                          fillColor: AppColors.white,
                          validator: (v) => v!.isNotEmpty ? null : 'Enter your name',
                        ),
                        const Spacer(),
                        PrimaryButton(
                          text: 'Sign Up as ${_selectedRole.name.toUpperCase()}',
                          backgroundColor: AppColors.primary,
                          textColor: AppColors.white,
                          isLoading: authState.isLoading,
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              await ref.read(authProvider.notifier).signUp(
                                email: _emailController.text,
                                password: _passwordController.text,
                                fullName: _fullNameController.text,
                                role: _selectedRole,
                              );
                              
                              if (!context.mounted) return;
                              
                              if (ref.read(authProvider).error != null) {
                                await AppAlert.showError(context, ref.read(authProvider).error!);
                              } else {
                                // NO Verification message needed!
                                // The router will automatically forward the user.
                                await AppAlert.showSuccess(context, 'Account created! Welcome to HAJA.');
                              }
                            }
                          },
                        ),
                        const SizedBox(height: 15),
                        const TextDivider(text: 'or', textColor: AppColors.textDark),
                        const SizedBox(height: 15),
                        SocialLoginButton(
                          label: 'Continue with Google',
                          onPressed: () => ref.read(authProvider.notifier).signInWithGoogle(role: _selectedRole),
                          iconPath: 'assets/images/google.webp',
                        ),
                        const SizedBox(height: 10),
                        SocialLoginButton(
                          label: 'Continue with Facebook',
                          onPressed: () => AppAlert.showInfo(context, 'Facebook Sign-In is coming soon!'),
                          iconPath: 'assets/images/facebook.png',
                        ),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                             const Text('Already have an account? ', style: TextStyle(color: AppColors.textDark, fontSize: 12)),
                            GestureDetector(
                              onTap: () => context.go(RouteName.login),
                              child: const Text('Sign In', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 12)),
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
        ),
      ),
    );
  }
}
