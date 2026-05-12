import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../config/app_sizes.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_widgets.dart';
import '../../config/app_router.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
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
    // Clear error when leaving the screen
    Future.microtask(() => ref.read(authProvider.notifier).clearError());
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
          child: ResponsiveLoginLayout(
            isMobile: isMobile,
            formKey: _formKey,
            emailController: _emailController,
            passwordController: _passwordController,
            isLoading: authState.isLoading,
            error: authState.error,
            onLoginPressed: () async {
              if (_formKey.currentState!.validate()) {
                await ref.read(authProvider.notifier).login(
                  _emailController.text,
                  _passwordController.text,
                );
                
                final state = ref.read(authProvider);
                if (state.isAuthenticated && state.error == null && context.mounted) {
                  AppAlert.showSuccess(context, 'Welcome back, ${state.user?.fullName}!');
                }
              }
            },
            onSignUpPressed: () => context.go('/signup'),
          ),
        ),
      ),
    );
  }
}

class ResponsiveLoginLayout extends StatelessWidget {
  final bool isMobile;
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isLoading;
  final String? error;
  final VoidCallback onLoginPressed;
  final VoidCallback onSignUpPressed;

  const ResponsiveLoginLayout({
    super.key,
    required this.isMobile,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.isLoading,
    required this.error,
    required this.onLoginPressed,
    required this.onSignUpPressed,
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
              onTap: () => context.go(RouteName.landing),
              child: Icon(
                Icons.arrow_back,
                color: AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(height: AppSizes.xl),

            // Title
            Text(
              'Sign In',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontSize: isMobile ? 36 : 40,
                    color: AppColors.textDark,
                  ),
            ),
            const SizedBox(height: AppSizes.md),

            // Subtitle
            Text(
              'Welcome back. Let\'s find your perfect style.',
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

                    // Email field
                    AppTextField(
                      label: 'Email Address',
                      hint: 'Enter your email',
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSizes.lg),

                    // Password field
                    AppTextField(
                      label: 'Password',
                      hint: 'Enter your password',
                      controller: passwordController,
                      keyboardType: TextInputType.visiblePassword,
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSizes.md),

                    // Forgot password
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {
                          AppAlert.showSuccess(context, 'Reset link sent to your email!');
                        },
                        child: Text(
                          'Forgot Password?',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: AppColors.textLight,
                                fontSize: 14,
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.xl),

                    // Login button
                    PrimaryButton(
                      text: 'Sign In',
                      onPressed: onLoginPressed,
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

                    // Sign up link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Don\'t have account? ',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textLight,
                              ),
                        ),
                        GestureDetector(
                          onTap: onSignUpPressed,
                          child: Text(
                            'Sign Up',
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

