import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_router.dart';
import '../../config/app_colors.dart';
import '../../models/chat_models.dart';
import '../../providers/direct_chat_provider.dart';
import '../../providers/database_provider.dart';

class DirectChatScreen extends ConsumerStatefulWidget {
  final Conversation conversation;
  const DirectChatScreen({super.key, required this.conversation});

  @override
  ConsumerState<DirectChatScreen> createState() => _DirectChatScreenState();
}

class _DirectChatScreenState extends ConsumerState<DirectChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _markAsRead();
  }

  void _markAsRead() {
    ref.read(directChatServiceProvider).markAsRead(widget.conversation.id);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messagesProvider(widget.conversation.id));
    
    // Mark as read whenever the messages stream updates and we are currently viewing the screen
    ref.listen(messagesProvider(widget.conversation.id), (prev, next) {
      if (next.hasValue) {
        _markAsRead();
      }
    });

    final supabase = ref.watch(supabaseClientProvider);
    final currentUserId = supabase.auth.currentUser?.id;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.white.withValues(alpha: 0.2),
              backgroundImage: widget.conversation.otherUserAvatar != null 
                ? NetworkImage(widget.conversation.otherUserAvatar!) 
                : null,
              child: widget.conversation.otherUserAvatar == null 
                ? const Icon(Icons.person, color: AppColors.white, size: 20) 
                : null,
            ),
            const SizedBox(width: 10),
            Text(
              widget.conversation.otherUserName ?? 'Chat',
              style: const TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(RouteName.customerMessages);
            }
          },
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.white),
            onSelected: (value) async {
              if (value == 'delete') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Conversation'),
                    content: const Text('Are you sure you want to delete this chat permanently?'),
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

                if (confirm == true) {
                  await ref.read(directChatServiceProvider).deleteConversation(widget.conversation.id);
                  if (context.mounted) {
                    context.pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Conversation deleted')),
                    );
                  }
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    SizedBox(width: 10),
                    Text('Delete Chat', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                _scrollToBottom();
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(20),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == currentUserId;
                    return _buildMessageBubble(message, isMe);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
              error: (e, s) => Center(child: Text('Error: $e')),
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(DirectMessage message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : AppColors.cardBackground,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMe ? 20 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 20),
          ),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: isMe ? AppColors.white : AppColors.textDark,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message.formattedTime,
              style: TextStyle(
                color: (isMe ? AppColors.white : Colors.grey).withValues(alpha: 0.6),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -5),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  border: InputBorder.none,
                ),
                onSubmitted: (val) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            onPressed: _sendMessage,
            icon: const Icon(Icons.send, color: AppColors.gold),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;
    ref.read(directChatServiceProvider).sendMessage(
      widget.conversation.id,
      _controller.text,
    );
    _controller.clear();
    _scrollToBottom();
  }
}
