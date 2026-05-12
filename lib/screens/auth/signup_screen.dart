import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../config/app_sizes.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_widgets.dart';
import '../../config/app_router.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  late TextEditingController _phoneController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _phoneController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: ResponsiveSignupLayout(
            isMobile: isMobile,
            formKey: _formKey,
            nameController: _nameController,
            emailController: _emailController,
            passwordController: _passwordController,
            confirmPasswordController: _confirmPasswordController,
            phoneController: _phoneController,
            isLoading: authState.isLoading,
            error: authState.error,
            onSignUpPressed: () async {
              if (_formKey.currentState!.validate()) {
                await ref.read(authProvider.notifier).signUp(
                  email: _emailController.text,
                  password: _passwordController.text,
                  fullName: _nameController.text,
                  role: UserRole.customer,
                  contactNumber: _phoneController.text,
                );
                
                if (ref.read(authProvider).error == null && context.mounted) {
                  _showSuccessDialog(context);
                }
              }
            },
            onSignInPressed: () => context.go('/login'),
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 20),
            const Text('Welcome!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
            const SizedBox(height: 10),
            const Text('Your account has been successfully created. We\'ve sent a welcome email to your inbox.', textAlign: TextAlign.center),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  context.go('/customer/home');
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: const Text('Start Styling', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ResponsiveSignupLayout extends StatelessWidget {
  final bool isMobile;
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final TextEditingController phoneController;
  final bool isLoading;
  final String? error;
  final VoidCallback onSignUpPressed;
  final VoidCallback onSignInPressed;

  const ResponsiveSignupLayout({
    super.key,
    required this.isMobile,
    required this.formKey,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.phoneController,
    required this.isLoading,
    required this.error,
    required this.onSignUpPressed,
    required this.onSignInPressed,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = isMobile ? screenWidth : 500.0;

    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? AppSizes.md : AppSizes.lg,
          vertical: AppSizes.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back button
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
                color: AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(height: AppSizes.xl),

            // Title
            Text(
              'Sign Up',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontSize: isMobile ? 36 : 40,
                    color: AppColors.textDark,
                  ),
            ),
            const SizedBox(height: AppSizes.md),

            // Subtitle
            Text(
              'Good to see you again. Let\'s pour something good.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 16,
                    color: AppColors.textPlaceholder,
                  ),
            ),
            const SizedBox(height: AppSizes.xl),

            // Dark card container
            Container(
              padding: const EdgeInsets.all(AppSizes.lg),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppSizes.radiusXl),
              ),
              child: Form(
                key: formKey,
                child: Column(
                  children: [
                    // Error message
                    if (error != null)
                      Container(
                        padding: const EdgeInsets.all(AppSizes.md),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline,
                                color: AppColors.error, size: 20),
                            const SizedBox(width: AppSizes.md),
                            Expanded(
                              child: Text(
                                error!,
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (error != null) const SizedBox(height: AppSizes.lg),

                    // Name field
                    AppTextField(
                      label: 'Full Name',
                      hint: 'Enter your full name',
                      controller: nameController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your full name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSizes.lg),

                    // Email field (for customer)
                    AppTextField(
                      label: 'Email',
                      hint: 'Enter your email',
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSizes.lg),

                    // Phone field
                    AppTextField(
                      label: 'Contact Number',
                      hint: 'Enter your phone number',
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSizes.lg),

                    // Password field
                    AppTextField(
                      label: 'Create Password',
                      hint: 'Create a strong password',
                      controller: passwordController,
                      keyboardType: TextInputType.visiblePassword,
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSizes.lg),

                    // Confirm password field
                    AppTextField(
                      label: 'Confirm Password',
                      hint: 'Confirm your password',
                      controller: confirmPasswordController,
                      keyboardType: TextInputType.visiblePassword,
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSizes.xl),

                    // Sign up button
                    PrimaryButton(
                      text: 'Sign Up',
                      onPressed: onSignUpPressed,
                      isLoading: isLoading,
                    ),
                    const SizedBox(height: AppSizes.xl),

                    // Divider
                    TextDivider(
                      text: 'or',
                      lineColor: AppColors.inputBorder,
                      textColor: AppColors.textLight,
                    ),
                    const SizedBox(height: AppSizes.lg),

                    // Social buttons
                    SocialLoginButton(
                      label: 'Continue with Google',
                      onPressed: () {},
                      iconPath: 'assets/images/google_icon.png',
                    ),
                    const SizedBox(height: AppSizes.md),
                    SocialLoginButton(
                      label: 'Continue with Facebook',
                      onPressed: () {},
                      iconPath: 'assets/images/facebook_icon.png',
                    ),
                    const SizedBox(height: AppSizes.lg),

                    // Sign in link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textLight,
                              ),
                        ),
                        GestureDetector(
                          onTap: onSignInPressed,
                          child: Text(
                            'Sign In',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: AppColors.white,
                                  fontSize: 16,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

