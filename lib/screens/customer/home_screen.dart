import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../config/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/database_provider.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/custom_bottom_bar.dart';

class CustomerHomeScreen extends ConsumerWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenHeight = MediaQuery.of(context).size.height;
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: AppColors.white,
      drawer: _buildDrawer(context, ref),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 0),
      body: Column(
        children: [
          _buildHeader(context, screenHeight, user?.address ?? 'Your Location'),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hi, ${user?.fullName.split(' ').first ?? 'User'}!',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                  const Text(
                    'What would you like to do?',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: AppColors.black,
                    ),
                  ),
                  const Spacer(),
                  Expanded(
                    flex: 10,
                    child: _buildSelectionCard(
                      context,
                      'Rent Now!',
                      [AppColors.gold, Color(0xFFB8860B)], // Gold gradient
                      'assets/rent_now.png',
                      () => context.push(RouteName.customerCategory, extra: {'isRental': true}),
                    ),
                  ),
                  const Spacer(),
                  Expanded(
                    flex: 10,
                    child: _buildSelectionCard(
                      context,
                      'Shop Now!',
                      [AppColors.primary, Color(0xFF333333)],
                      'assets/shop_now.png',
                      () => context.push(RouteName.customerCategory, extra: {'isRental': false}),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, WidgetRef ref) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: AppColors.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: AssetImage('assets/logo.png'),
                ),
                SizedBox(height: 10),
                Text(
                  'HAJA Rentals',
                  style: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context);
              context.go(RouteName.customerHome);
            },
          ),
          ListTile(
            leading: const Icon(Icons.local_shipping_outlined),
            title: const Text('My Orders'),
            onTap: () {
              Navigator.pop(context);
              context.go(RouteName.customerTrackOrders);
            },
          ),
          ListTile(
            leading: const Icon(Icons.favorite_border),
            title: const Text('Favorites'),
            onTap: () {
              Navigator.pop(context);
              context.push(RouteName.customerFavorites);
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pop(context);
              context.go(RouteName.customerProfile);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () async {
              Navigator.pop(context);
              final confirm = await AppAlert.showConfirm(
                context,
                title: 'Logout',
                message: 'Are you sure you want to log out?',
                confirmText: 'Logout',
                color: Colors.red,
                icon: Icons.logout,
              );
              if (confirm) {
                ref.read(authProvider.notifier).logout();
                if (context.mounted) {
                  context.go(RouteName.landing);
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, double screenHeight, String location) {
    return Container(
      padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current Location',
                    style: TextStyle(color: AppColors.white, fontSize: 12),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: AppColors.white, size: 16),
                      const SizedBox(width: 5),
                      Text(
                        location.length > 25 ? '${location.substring(0, 22)}...' : location,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  Builder(
                    builder: (context) => GestureDetector(
                      onTap: () => Scaffold.of(context).openDrawer(),
                      child: _headerIcon(Icons.menu),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Consumer(
                    builder: (context, ref, child) {
                      final unreadCount = ref.watch(totalNotificationCountProvider);
                      return GestureDetector(
                        onTap: () => context.push(RouteName.customerNotifications),
                        child: Badge(
                          label: Text(unreadCount.toString()),
                          isLabelVisible: unreadCount > 0,
                          backgroundColor: Colors.red,
                          child: _headerIcon(Icons.notifications_none),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Search Bar (Single Oblong)
          GestureDetector(
            onTap: () => context.push(RouteName.customerCategory, extra: {'isRental': true}),
            child: TextField(
              enabled: false, // Tapping redirects
              decoration: InputDecoration(
                hintText: 'Search for rentals or items...',
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: AppColors.white, size: 24),
    );
  }

  Widget _buildSelectionCard(BuildContext context, String title, List<Color> colors, String imagePath, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: colors.map((c) => c.withValues(alpha: 0.8)).toList(),
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          image: DecorationImage(
            image: AssetImage(imagePath),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              colors.first.withValues(alpha: 0.4),
              BlendMode.darken,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: colors.first.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            const Positioned(
              right: -20,
              top: -20,
              child: Icon(Icons.shopping_bag_outlined, size: 150, color: Colors.white10),
            ),
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white24),
                ),
                child: Center(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 20,
              left: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.contains('Rent') ? 'EASY RENTALS' : 'PREMIUM SHOP',
                    style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Explore Collection',
                    style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w300),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
