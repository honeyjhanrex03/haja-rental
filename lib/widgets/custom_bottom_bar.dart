import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_colors.dart';
import '../config/app_router.dart';
import '../screens/customer/chatbot_screen.dart';
import '../providers/chat_provider.dart';
import '../providers/direct_chat_provider.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context,
                index: 0,
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Home',
                route: RouteName.customerHome,
              ),
              _buildNavItem(
                context,
                index: 1,
                icon: Icons.chat_bubble_outline,
                activeIcon: Icons.chat_bubble,
                label: 'Messages',
                route: RouteName.customerMessages,
              ),
              const SizedBox(width: 60), // Space for the floating button
              _buildNavItem(
                context,
                index: 2,
                icon: Icons.local_shipping_outlined,
                activeIcon: Icons.local_shipping,
                label: 'Tracking',
                route: RouteName.customerTrackOrders,
              ),
              _buildNavItem(
                context,
                index: 3,
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'Profile',
                route: RouteName.customerProfile,
              ),
            ],
          ),
        ),
        Positioned(
          top: -35,
          left: MediaQuery.of(context).size.width / 2 - 40,
          child: GestureDetector(
            onTap: () {
              // Open Chatbot as a persistent bottom sheet or full screen
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => Container(
                  height: MediaQuery.of(context).size.height * 0.85,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: ChatBotScreen(provider: customerChatProvider),
                ),
              );
            },
            child: Container(
              height: 80,
              width: 80,
              decoration: BoxDecoration(
                image: const DecorationImage(
                  image: AssetImage('assets/icons/ai_stylist.png'),
                  fit: BoxFit.cover,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const SizedBox.shrink(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required String route,
  }) {
    final isActive = currentIndex == index;
    final color = isActive ? AppColors.gold : Colors.grey;

    return GestureDetector(
      onTap: () {
        if (!isActive) {
          context.go(route);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Consumer(
              builder: (context, ref, child) {
                final unreadCount = label == 'Messages' 
                    ? ref.watch(unreadMessageCountProvider).maybeWhen(data: (count) => count, orElse: () => 0) 
                    : 0;
                
                return Badge(
                  label: Text(unreadCount.toString()),
                  isLabelVisible: unreadCount > 0,
                  backgroundColor: Colors.red,
                  child: Icon(
                    isActive ? activeIcon : icon,
                    color: color,
                    size: 26,
                  ),
                );
              },
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
