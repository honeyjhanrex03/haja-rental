import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../config/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/seller_bottom_bar.dart';
import '../../widgets/app_widgets.dart';
import '../../providers/database_provider.dart';
import '../../widgets/real_time_clock.dart';

class SellerHomeScreen extends ConsumerStatefulWidget {
  const SellerHomeScreen({super.key});

  @override
  ConsumerState<SellerHomeScreen> createState() => _SellerHomeScreenState();
}

class _SellerHomeScreenState extends ConsumerState<SellerHomeScreen> {
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: AppColors.white,
      drawer: _buildDrawer(context),
      bottomNavigationBar: SellerBottomNavBar(currentIndex: 0),
      body: Column(
        children: [
          _buildCustomHeader(screenHeight),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hi, ${user?.fullName.split(' ').first ?? 'Seller'}!',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppColors.gold,
                    ),
                  ),
                  const Text(
                    'What would you like to manage today?',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: AppColors.textPlaceholder,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Stats Section
                  SizedBox(
                    height: 110,
                    child: ref.watch(sellerAnalyticsProvider).when(
                      data: (stats) => ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        children: [
                          _buildStatCard('Total Views', stats['views'].toString(), Icons.visibility_outlined),
                          _buildStatCard('Favorites', stats['favorites'].toString(), Icons.favorite_border),
                          _buildStatCard('Earnings', '₱${stats['earnings']}', Icons.account_balance_wallet_outlined),
                        ],
                      ),
                      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
                      error: (e, s) => const Text('Failed to load stats'),
                    ),
                  ),
                                   const SizedBox(height: 20),
                  
                  // Main Actions Grid
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                      children: [
                        _buildActionCard(
                          'View Rentals',
                          Icons.vpn_key_outlined,
                          AppColors.gold,
                          onTap: () => context.push(RouteName.sellerViewShopRentals, extra: 0),
                        ),
                        _buildActionCard(
                          'Manage Orders',
                          Icons.shopping_bag_outlined,
                          AppColors.primary,
                          onTap: () => context.push(RouteName.sellerViewShopRentals, extra: 2),
                        ),
                        _buildActionCard(
                          'Shop Items',
                          Icons.storefront_outlined,
                          Colors.purple,
                          onTap: () => context.push(RouteName.sellerViewShopRentals, extra: 1),
                        ),
                        _buildActionCard(
                          'Add Listing',
                          Icons.add_circle_outline,
                          Colors.green,
                          onTap: () => context.push(RouteName.sellerAddListing),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
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
                  'HAJA Seller Portal',
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
              context.go(RouteName.sellerHome);
            },
          ),
          ListTile(
            leading: const Icon(Icons.add_box_outlined),
            title: const Text('Add Listing'),
            onTap: () {
              Navigator.pop(context);
              context.push(RouteName.sellerAddListing);
            },
          ),
          ListTile(
            leading: const Icon(Icons.store_outlined),
            title: const Text('My Shop'),
            onTap: () {
              Navigator.pop(context);
              context.push(RouteName.sellerViewShopRentals);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout'),
            onTap: () async {
              Navigator.pop(context);
              final confirm = await AppAlert.showConfirm(
                context,
                title: 'Logout',
                message: 'Are you sure you want to log out of your shop?',
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

  Widget _buildCustomHeader(double screenHeight) {
    final user = ref.read(authProvider).user; // Use read here since it's already watched in build
    
    return Container(
      height: screenHeight * 0.18,
      padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => context.push(RouteName.customerProfile),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  user?.fullName ?? 'Haja Shop',
                  style: const TextStyle(color: AppColors.textDark, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: AppColors.gold, size: 16),
                    const SizedBox(width: 5),
                    Text(
                      (user?.address != null && user!.address!.isNotEmpty) 
                          ? user.address! 
                          : 'Location not set',
                      style: TextStyle(color: AppColors.textDark.withValues(alpha: 0.6), fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                const RealTimeClock(),
              ],
            ),
          ),
          Row(
            children: [
              Builder(builder: (context) {
                return GestureDetector(
                  onTap: () => Scaffold.of(context).openDrawer(),
                  child: _headerIcon(Icons.menu),
                );
              }),
              const SizedBox(width: 12),
              Consumer(
                builder: (context, ref, child) {
                  final unreadCount = ref.watch(totalNotificationCountProvider);
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
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
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                    ),
                    builder: (context) => Container(
                      padding: const EdgeInsets.all(30),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Seller Settings',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                          const SizedBox(height: 20),
                          ListTile(
                            leading: const Icon(Icons.store_outlined, color: AppColors.gold),
                            title: const Text('Shop Profile'),
                            onTap: () {
                              Navigator.pop(context);
                              context.go(RouteName.customerProfile);
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.payment_outlined, color: AppColors.gold),
                            title: const Text('Payout Methods'),
                            onTap: () {
                              Navigator.pop(context);
                              AppAlert.showInfo(context, 'Payout methods configuration will be available soon.');
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.help_outline, color: AppColors.gold),
                            title: const Text('Help Center'),
                            onTap: () {
                              Navigator.pop(context);
                              AppAlert.showInfo(context, 'Help Center is under maintenance.');
                            },
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  );
                },
                child: _headerIcon(Icons.settings_outlined),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
          ),
        ],
      ),
      child: Icon(icon, color: AppColors.textDark, size: 24),
    );
  }


  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.gold, size: 20),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11, 
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                fontFamily: 'Inter',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
