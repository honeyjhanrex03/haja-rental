import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../config/app_router.dart';
import '../../providers/direct_chat_provider.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/seller_bottom_bar.dart';
import '../../providers/auth_provider.dart';

class ConversationListScreen extends ConsumerWidget {
  const ConversationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(conversationsProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      bottomNavigationBar: ref.watch(authProvider).user?.role == UserRole.seller
          ? const SellerBottomNavBar(currentIndex: 1)
          : const CustomBottomNavBar(currentIndex: 1),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'Messages',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
        ),
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
        centerTitle: true,
      ),
      body: conversationsAsync.when(
        data: (conversations) {
          if (conversations.isEmpty) {
            return _buildEmptyState();
          }
          return ListView.separated(
            padding: const EdgeInsets.all(15),
            itemCount: conversations.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final conversation = conversations[index];
              return Dismissible(
                key: Key(conversation.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: Colors.red,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Conversation'),
                      content: const Text('Are you sure you want to delete this chat?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Delete', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (direction) async {
                  try {
                    await ref.read(directChatServiceProvider).deleteConversation(conversation.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Conversation deleted')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to delete: $e')),
                      );
                    }
                  }
                },
                child: ListTile(
                  onTap: () => context.push(RouteName.customerDirectChat, extra: conversation),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                  leading: CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.cardBackground,
                    backgroundImage: conversation.otherUserAvatar != null 
                      ? NetworkImage(conversation.otherUserAvatar!) 
                      : null,
                    child: conversation.otherUserAvatar == null 
                      ? const Icon(Icons.person, color: AppColors.primary) 
                      : null,
                  ),
                  title: Text(
                    conversation.otherUserName ?? 'Unknown Seller',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: const Text(
                    'Tap to view messages',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
        error: (e, s) => Center(child: Text('Error loading messages: $e')),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 20),
          const Text(
            'No messages yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 10),
          const Text(
            'Contact a seller to start a conversation!',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
