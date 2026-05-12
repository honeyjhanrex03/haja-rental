import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../config/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/database_provider.dart';
import '../../models/category_model.dart';
import '../../models/feedback_model.dart';
import '../../widgets/custom_bottom_bar.dart';

class CustomerDiscoverScreen extends ConsumerWidget {
  const CustomerDiscoverScreen({super.key});

  Widget _buildDrawer(BuildContext context, WidgetRef ref) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: AppColors.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundImage: AssetImage('assets/logo.png'),
                ),
                const SizedBox(height: 10),
                const Text(
                  'HAJA Rentals',
                  style: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: const Text('Home'),
            onTap: () => context.go(RouteName.customerHome),
          ),
          ListTile(
            leading: const Icon(Icons.local_shipping_outlined),
            title: const Text('My Orders'),
            onTap: () => context.go(RouteName.customerTrackOrders),
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
            onTap: () => context.go(RouteName.customerProfile),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () {
              ref.read(authProvider.notifier).logout();
              context.go(RouteName.landing);
            },
          ),
        ],
      ),
    );
  }

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
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Text(
                    'Hi, ${user?.fullName.split(' ').first ?? 'User'}!',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                  const Text(
                    'New arrivals and exclusive deals are waiting.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.black,
                    ),
                  ),
                  const Spacer(),
                  // Promo Banner
                  Expanded(
                    flex: 12,
                    child: _buildPromoBanner(),
                  ),
                  const Spacer(),
                  // Categories
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Categories',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.black,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.push(RouteName.customerCategory),
                        child: const Text('See all', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ),
                    ],
                  ),
                  Expanded(
                    flex: 10,
                    child: _buildCategoriesList(context, ref),
                  ),
                  const Spacer(),
                  // Feedbacks
                  const Text(
                    'Feedbacks',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Expanded(
                    flex: 8,
                    child: _buildFeedbackList(ref),
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

  Widget _buildHeader(BuildContext context, double screenHeight, String location) {
    return Container(
      height: screenHeight * 0.22,
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
          const Text(
            'Current Session',
            style: TextStyle(color: AppColors.white, fontSize: 12),
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.person_pin_circle, color: AppColors.white, size: 20),
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
              Row(
                children: [
                  Builder(
                    builder: (context) => GestureDetector(
                      onTap: () => Scaffold.of(context).openDrawer(),
                      child: _headerIcon(Icons.menu),
                    ),
                  ),
                  const SizedBox(width: 10),
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
          const Spacer(),
          // Search Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            height: 45,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white24),
            ),
            child: const TextField(
              style: TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search for clothes...',
                hintStyle: TextStyle(color: Colors.white70, fontSize: 12),
                border: InputBorder.none,
                icon: Icon(Icons.search, color: Colors.white, size: 20),
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

  Widget _buildPromoBanner() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
        image: const DecorationImage(
          image: AssetImage('assets/promo_banner.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('SUMMER SALE', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              Text('Get 20% OFF on Rentals', style: TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesList(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider(CategoryType.rental));

    return categoriesAsync.when(
      data: (categories) => ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return GestureDetector(
            onTap: () => context.push(RouteName.customerCategory, extra: {'category': category.name, 'isRental': true}),
            child: Container(
              width: 100,
              margin: const EdgeInsets.only(right: 15),
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        image: DecorationImage(
                          image: category.imageUrl.startsWith('assets/')
                              ? AssetImage(category.imageUrl) as ImageProvider
                              : NetworkImage(category.imageUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Center(
                      child: Text(
                        category.name,
                        style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildFeedbackList(WidgetRef ref) {
    final feedbacksAsync = ref.watch(feedbacksProvider);

    return feedbacksAsync.when(
      data: (feedbacks) {
        if (feedbacks.isEmpty) {
          return const Center(child: Text('No feedbacks yet.'));
        }
        return ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: feedbacks.length,
          itemBuilder: (context, index) => Container(
            width: 300,
            margin: const EdgeInsets.only(right: 15),
            child: _buildFeedbackCard(feedbacks[index]),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildFeedbackCard(FeedbackModel feedback) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 15,
            backgroundColor: AppColors.primary,
            child: Icon(Icons.person, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(feedback.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                    Row(
                      children: List.generate(
                        5,
                        (index) => Icon(
                          Icons.star,
                          color: index < feedback.rating ? Colors.amber : Colors.grey[300],
                          size: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  feedback.comment,
                  style: const TextStyle(fontSize: 9, color: Colors.grey),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
