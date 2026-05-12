import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../config/app_router.dart';
import '../../widgets/seller_bottom_bar.dart';
import '../../providers/auth_provider.dart';
import '../../providers/database_provider.dart';

class SellerProfileScreen extends ConsumerWidget {
  const SellerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.white,
      bottomNavigationBar: const SellerBottomNavBar(currentIndex: 3),
      body: Column(
        children: [
          _buildCustomHeader(context),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // Profile Picture
                    const CircleAvatar(
                      radius: 60,
                      backgroundImage: AssetImage('assets/logo.png'), // Placeholder
                    ),
                    const SizedBox(height: 40),

                    // Fields
                    _buildProfileField('Shop Name', 'Haja Shop', showEditIcon: true),
                    const SizedBox(height: 20),
                    _buildProfileField('Address', 'Panabo City, Davao del Norte'),
                    const SizedBox(height: 20),
                    _buildProfileField('Contact Number', '09091376490'),
                    const SizedBox(height: 20),
                    _buildProfileField('Email Address', 'hajateam@gmail.com'),
                    const SizedBox(height: 30),

                    // Logout Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () {
                          ref.read(authProvider.notifier).logout();
                          context.go('/welcome');
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.black),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: const [
                             Icon(Icons.logout, color: AppColors.black),
                             SizedBox(width: 10),
                             Text('Logout', style: TextStyle(color: AppColors.black, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.white),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(RouteName.sellerHome);
                  }
                },
              ),
              const Text(
                'Profile',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Consumer(
                builder: (context, ref, child) {
                  final unreadCount = ref.watch(totalNotificationCountProvider);
                  return GestureDetector(
                    onTap: () => context.push(RouteName.customerNotifications),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.inputBackground.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Badge(
                        label: Text(unreadCount.toString()),
                        isLabelVisible: unreadCount > 0,
                        backgroundColor: Colors.red,
                        child: const Icon(Icons.notifications_none, color: AppColors.white, size: 20),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.inputBackground.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.menu, color: AppColors.white, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileField(String label, String value, {bool showEditIcon = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label == 'Contact Number' || label == 'Email Address')
          Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.black),
          ),
        const SizedBox(height: 5),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.black, width: 0.8),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.textPlaceholder),
              ),
              if (showEditIcon)
                const Icon(Icons.edit_outlined, size: 18, color: AppColors.black),
            ],
          ),
        ),
      ],
    );
  }
}

