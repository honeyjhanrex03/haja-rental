import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../config/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/admin_provider.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    final statsAsync = ref.watch(adminProvider);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.white,
      endDrawer: _buildDrawer(),
      body: statsAsync.when(
        data: (stats) => Column(
          children: [
            _buildCustomHeader(screenHeight),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Analytics',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.black),
                    ),
                    const SizedBox(height: 5),
                    Expanded(flex: 3, child: _buildTotalIncomeCard(stats.totalIncome)),
                    const SizedBox(height: 10),
                    Expanded(
                      flex: 2,
                      child: Row(
                        children: [
                          Expanded(child: _buildSmallStatCard('Total Users', stats.totalUsers.toString())),
                          const SizedBox(width: 10),
                          Expanded(child: _buildSmallStatCard('Total Seller', stats.totalSellers.toString())),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Management Shortcuts',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.black),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildQuickAction(context, 'Users', Icons.person_search, RouteName.adminUsers),
                        const SizedBox(width: 10),
                        _buildQuickAction(context, 'Coupons', Icons.discount_outlined, RouteName.adminCoupons),
                        const SizedBox(width: 10),
                        _buildQuickAction(context, 'Orders', Icons.receipt_long, RouteName.customerTrackOrders), // Reusing track orders or a list
                      ],
                    ),
                    const Spacer(),
                    const Text(
                      'Category Performance',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.black),
                    ),
                    const SizedBox(height: 5),
                    Expanded(flex: 3, child: _buildContextualCard()),
                    const Spacer(),
                    const Text(
                      'Monthly Sales',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.black),
                    ),
                    const SizedBox(height: 5),
                    Expanded(flex: 3, child: _buildLineChartPlaceholder()),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildCustomHeader(double screenHeight) {
    return Container(
      height: screenHeight * 0.15,
      padding: const EdgeInsets.only(top: 50, left: 20, right: 20),
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
          const Text(
            'Hi, Admin!',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.white),
          ),
          Row(
            children: [
              _headerIcon(Icons.notifications_none),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
                child: _headerIcon(Icons.menu),
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
        color: AppColors.inputBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: AppColors.white, size: 20),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: AppColors.white,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Image.asset('assets/logo.png', height: 100),
            const Text('H A J A', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.black)),
            const SizedBox(height: 30),
            _buildDrawerItem(context, 'Dashboard', Icons.dashboard, () => context.pop()),
            _buildDrawerItem(context, 'User Management', Icons.people, () => context.push(RouteName.adminUsers)),
            _buildDrawerItem(context, 'Coupon Management', Icons.confirmation_number, () => context.push(RouteName.adminCoupons)),
            _buildDrawerItem(context, 'View Seller Records', Icons.store, () => context.push(RouteName.adminUsers)), // Reusing user management for now
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              onTap: () async {
                await ref.read(authProvider.notifier).logout();
                if (mounted) context.go(RouteName.landing);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }

  Widget _buildTotalIncomeCard(double income) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.gold,
        borderRadius: BorderRadius.circular(30),
      ),

      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Total Income', style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: AppColors.textLight)),
              Text('₱${income.toStringAsFixed(0)}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.white)),
            ],
          ),
          const Icon(Icons.bar_chart, color: AppColors.white, size: 40),
        ],
      ),
    );
  }

  Widget _buildSmallStatCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: AppColors.textPlaceholder)),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.black)),
        ],
      ),
    );
  }

  Widget _buildContextualCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Container(
            height: 70,
            width: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.gold.withValues(alpha: 0.3),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.5), width: 10),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('Photoshoots'),
                _buildLegendItem('Formal Wear'),
                _buildLegendItem('Cosmetics'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String title) {
    return Row(
      children: [
        const CircleAvatar(radius: 3, backgroundColor: AppColors.gold),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: AppColors.textLight)),
      ],
    );
  }

  Widget _buildLineChartPlaceholder() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.inputBackground.withValues(alpha: 0.3)),
      ),
      child: const Center(child: Icon(Icons.show_chart, color: AppColors.primary, size: 50)),
    );
  }

  Widget _buildQuickAction(BuildContext context, String title, IconData icon, String route) {
    return Expanded(
      child: InkWell(
        onTap: () => context.push(route),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(height: 5),
              Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
