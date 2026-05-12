import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../config/app_sizes.dart';
import '../../config/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_widgets.dart';

class SignupSellerScreen extends ConsumerStatefulWidget {
  const SignupSellerScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _SignupSellerScreenState();
}

class _SignupSellerScreenState extends ConsumerState<SignupSellerScreen> {
  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _storeNameController;
  late TextEditingController _locationController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _storeNameController = TextEditingController();
    _locationController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _storeNameController.dispose();
    _locationController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
          child: _buildSignupForm(context, authState, isMobile),
        ),
      ),
    );
  }

  Widget _buildSignupForm(BuildContext context, AuthState authState, bool isMobile) {
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
              'Create a seller account, list your outfits, and start earning from every rental.',
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
                key: _formKey,
                child: Column(
                  children: [
                    // Error message
                    if (authState.error != null)
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
                                authState.error!,
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (authState.error != null) const SizedBox(height: AppSizes.lg),

                    // Full Name field
                    AppTextField(
                      label: 'Full Name',
                      hint: 'Enter your full name',
                      controller: _fullNameController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your full name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSizes.lg),

                    // Email field
                    AppTextField(
                      label: 'Email Address',
                      hint: 'Enter your email',
                      controller: _emailController,
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
                      label: 'Phone Number',
                      hint: 'Enter your phone number',
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSizes.lg),

                    // Store Name field
                    AppTextField(
                      label: 'Store / Shop Name',
                      hint: 'Enter your shop name',
                      controller: _storeNameController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your store name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSizes.lg),

                    // Location field
                    AppTextField(
                      label: 'Location / Address',
                      hint: 'Enter your location',
                      controller: _locationController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your location';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSizes.lg),

                    // Password field
                    AppTextField(
                      label: 'Password',
                      hint: 'Create a strong password',
                      controller: _passwordController,
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
                      controller: _confirmPasswordController,
                      keyboardType: TextInputType.visiblePassword,
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSizes.xl),

                    // Sign up button
                    PrimaryButton(
                      text: 'Sign Up',
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          await ref.read(authProvider.notifier).signUp(
                            email: _emailController.text,
                            password: _passwordController.text,
                            fullName: _fullNameController.text,
                            role: UserRole.seller,
                            contactNumber: _phoneController.text,
                          );
                        }
                      },
                      isLoading: authState.isLoading,
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
                          onTap: () => context.go('/login?role=seller'),
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

