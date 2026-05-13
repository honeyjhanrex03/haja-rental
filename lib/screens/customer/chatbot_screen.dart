import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/app_colors.dart';
import '../../providers/chat_provider.dart';
import '../../providers/cloudinary_provider.dart';
import '../../providers/database_provider.dart';
import '../../config/app_router.dart';
import 'package:go_router/go_router.dart';

class ChatBotScreen extends ConsumerStatefulWidget {
  final NotifierProvider<ChatNotifier, ChatState> provider;
  const ChatBotScreen({super.key, required this.provider});

  @override
  ConsumerState<ChatBotScreen> createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends ConsumerState<ChatBotScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

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

  Future<void> _handleImageSelection() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    // Show a loading indicator for the upload
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Processing image...')),
    );

    try {
      final cloudinary = ref.read(cloudinaryServiceProvider);
      final bytes = await image.readAsBytes();
      final url = await cloudinary.uploadImage(bytes, image.name);
      
      if (url != null) {
        ref.read(widget.provider.notifier).sendMessage('I uploaded this item. Can you help me with it?', imageUrl: url);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(widget.provider);
    final messages = chatState.messages;
    final chatNotifier = ref.read(widget.provider.notifier);

    final isCustomer = widget.provider == customerChatProvider;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.white,
              backgroundImage: const AssetImage('assets/icons/ai_stylist.png'),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCustomer ? 'Smart Stylist' : 'Seller Support',
                  style: const TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Powered by HAJA AI',
                  style: TextStyle(color: AppColors.white.withValues(alpha: 0.7), fontSize: 11),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.white),
            onPressed: () => chatNotifier.clearChat(),
          ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? _buildEmptyState(isCustomer)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(20),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      return _buildChatBubble(message);
                    },
                  ),
          ),
          if (chatState.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold),
              ),
            ),
          _buildInputArea(chatNotifier),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isCustomer) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Assistant Welcome Bubble
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: AppColors.gold,
                backgroundImage: const AssetImage('assets/icons/ai_stylist.png'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50]?.withValues(alpha: 0.5),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Text(
                    isCustomer 
                      ? "Hi! I'm your style assistant. Send a clothing item and I'll suggest outfits that match it. I can also help if you have questions about sizes, rentals, or categories."
                      : "Hi! I'm your seller support assistant. I can help you manage your shop, list new items, and optimize your sales!",
                    style: TextStyle(color: Colors.blueGrey[800], fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          
          const Text(
            'Quick Action',
            style: TextStyle(color: Colors.blueGrey, fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 15),

          if (isCustomer) ...[
            _buildQuickActionButton('👗 Match my outfit', () => _sendQuickMessage('Help me match an outfit for an upcoming event!')),
            _buildQuickActionButton('💼 Upload clothing item', () => _sendQuickMessage('How do I upload or sell my own items?')),
            _buildQuickActionButton('📏 Help with sizes', () => _sendQuickMessage('Can you help me understand the sizes available?')),
            _buildQuickActionButton('📦 How renting works', () => _sendQuickMessage('Explain how the rental process works step-by-step.')),
          ] else ...[
            _buildQuickActionButton('➕ Add new listing', () => _sendQuickMessage('Help me add a new listing to my shop.')),
            _buildQuickActionButton('📈 How to sell more', () => _sendQuickMessage('Give me tips on how to improve my shop sales.')),
            _buildQuickActionButton('💰 Payout information', () => _sendQuickMessage('When and how do I receive my earnings?')),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.blue[50]?.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Text(
            label,
            style: TextStyle(color: Colors.blueGrey[800], fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }

  void _sendQuickMessage(String text) {
    ref.read(widget.provider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  Widget _buildChatBubble(ChatMessage message) {
    // Check if message contains [ITEM_ID: <id>]
    final productMatch = RegExp(r'\[ITEM_ID:\s*(.*?)\]').firstMatch(message.text);
    final String? productId = productMatch?.group(1)?.trim();
    final String cleanText = message.text.replaceAll(RegExp(r'\[ITEM_ID:\s*.*?\]'), '').trim();

    return Column(
      crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Align(
          alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 15),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            decoration: BoxDecoration(
              color: message.isUser ? AppColors.primary : AppColors.cardBackground,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(message.isUser ? 20 : 0),
                bottomRight: Radius.circular(message.isUser ? 0 : 20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (message.imageUrl != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      message.imageUrl!,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                message.isUser 
                  ? Text(
                      message.text,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 14,
                      ),
                    )
                  : TypewriterText(
                      text: cleanText,
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 14,
                      ),
                    ),
              ],
            ),
          ),
        ),
        if (!message.isUser && productId != null) 
          _buildProductRecommendationCard(productId),
      ],
    );
  }

  Widget _buildProductRecommendationCard(String productId) {
    return Consumer(
      builder: (context, ref, child) {
        final itemAsync = ref.watch(singleItemProvider(productId));
        
        return itemAsync.when(
          data: (item) {
            if (item == null) return const SizedBox.shrink();
            return GestureDetector(
              onTap: () {
                // Navigate to item details
                context.push(RouteName.customerItemDetails, extra: item);
              },
              child: Container(
                margin: const EdgeInsets.only(left: 40, bottom: 20, right: 20),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        item.imageUrl,
                        height: 80,
                        width: 70,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(color: Colors.grey[200], width: 70, height: 80, child: const Icon(Icons.image_outlined)),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.description,
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '₱${item.price}',
                                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.gold,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'View',
                                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.only(left: 40, bottom: 20),
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          error: (e, s) => const SizedBox.shrink(),
        );
      },
    );
  }

  Widget _buildInputArea(ChatNotifier chatNotifier) {
    return Container(
      padding: const EdgeInsets.all(15),
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
          GestureDetector(
            onTap: _handleImageSelection,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_a_photo_outlined, color: AppColors.primary, size: 20),
            ),
          ),
          const SizedBox(width: 10),
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
                  hintText: 'Type your question...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(fontSize: 14, color: AppColors.textPlaceholder),
                ),
                onSubmitted: (val) {
                  chatNotifier.sendMessage(val);
                  _controller.clear();
                  _scrollToBottom();
                },
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () {
              chatNotifier.sendMessage(_controller.text);
              _controller.clear();
              _scrollToBottom();
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppColors.gold,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: AppColors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const TypewriterText({super.key, required this.text, required this.style});

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> with AutomaticKeepAliveClientMixin {
  String _displayedText = '';
  int _currentIndex = 0;
  late final Duration _typingSpeed;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Faster typing for longer messages
    final speed = widget.text.length > 100 ? 5 : 15;
    _typingSpeed = Duration(milliseconds: speed);
    _startTyping();
  }

  void _startTyping() {
    if (_currentIndex < widget.text.length) {
      if (mounted) {
        setState(() {
          _displayedText += widget.text[_currentIndex];
          _currentIndex++;
        });
        Future.delayed(_typingSpeed, _startTyping);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required by AutomaticKeepAliveClientMixin
    return Text(
      _displayedText,
      style: widget.style,
    );
  }
}
