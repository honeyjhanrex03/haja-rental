import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../config/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/direct_chat_provider.dart';
import '../../providers/database_provider.dart';
import '../../models/order_model.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadMessages = ref.watch(unreadMessageCountProvider).maybeWhen(data: (count) => count, orElse: () => 0);
    final ordersAsync = ref.watch(userOrdersProvider);
    final sellerOrdersAsync = ref.watch(sellerOrdersProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              final user = ref.read(authProvider).user;
              if (user?.role == UserRole.seller) {
                context.go(RouteName.sellerHome);
              } else {
                context.go(RouteName.customerHome);
              }
            }
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (unreadMessages > 0)
            _buildNotificationCard(
              context,
              title: 'New Messages',
              subtitle: 'You have $unreadMessages unread messages.',
              icon: Icons.chat_bubble_outline,
              color: Colors.blue,
              onTap: () => context.push(RouteName.customerMessages),
            ),
          
          ordersAsync.when(
            data: (orders) {
              final pendingOrders = orders.where((o) => o.status == OrderStatus.toPay || o.status == OrderStatus.toShip).toList();
              if (pendingOrders.isEmpty) return const SizedBox.shrink();
              return _buildNotificationCard(
                context,
                title: 'Order Updates',
                subtitle: 'You have ${pendingOrders.length} pending orders.',
                icon: Icons.local_shipping_outlined,
                color: AppColors.gold,
                onTap: () => context.push(RouteName.customerTrackOrders),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (e, s) => const SizedBox.shrink(),
          ),

          sellerOrdersAsync.when(
            data: (orders) {
              final newOrders = orders.where((o) => o.status == OrderStatus.toPay || o.status == OrderStatus.toShip).toList();
              if (newOrders.isEmpty) return const SizedBox.shrink();
              return _buildNotificationCard(
                context,
                title: 'New Sales',
                subtitle: 'You have ${newOrders.length} new orders to process!',
                icon: Icons.storefront,
                color: Colors.green,
                onTap: () => context.push(RouteName.sellerViewShopRentals),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (e, s) => const SizedBox.shrink(),
          ),

          if (unreadMessages == 0)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 100),
                child: Column(
                  children: [
                    Icon(Icons.notifications_none, size: 80, color: Colors.grey),
                    SizedBox(height: 20),
                    Text('No new notifications', style: TextStyle(color: Colors.grey, fontSize: 16)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
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
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(15),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 13)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      ),
    );
  }
}
