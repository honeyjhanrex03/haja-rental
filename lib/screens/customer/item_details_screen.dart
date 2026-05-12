import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../config/app_sizes.dart';
import '../../config/app_router.dart';
import '../../models/item_model.dart';
import '../../models/feedback_model.dart';
import '../../widgets/app_widgets.dart';
import '../../providers/database_provider.dart';
import '../../providers/direct_chat_provider.dart';
import '../../widgets/custom_bottom_bar.dart';

class CustomerItemDetailsScreen extends ConsumerStatefulWidget {
  final Item item;
  const CustomerItemDetailsScreen({super.key, required this.item});

  @override
  ConsumerState<CustomerItemDetailsScreen> createState() => _CustomerItemDetailsScreenState();
}

class _CustomerItemDetailsScreenState extends ConsumerState<CustomerItemDetailsScreen> {
  @override
  void initState() {
    super.initState();
    _logView();
  }

  Future<void> _logView() async {
    final supabase = ref.read(supabaseClientProvider);
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await supabase.from('item_views').insert({
        'item_id': widget.item.id,
        'viewer_id': userId,
      });
    } catch (e) {
      debugPrint('Failed to log view: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 0),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image and Size Info
                    _buildTopSection(),
                    const SizedBox(height: 20),
                    
                    Text(
                      widget.item.name,
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      widget.item.description,
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₱ ${widget.item.price}${widget.item.isRental ? "/day" : ""}',
                          style: const TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                        Consumer(
                          builder: (context, ref, child) {
                            final favoritesAsync = ref.watch(userFavoritesProvider);
                            final isFavorite = favoritesAsync.maybeWhen(
                              data: (ids) => ids.contains(widget.item.id),
                              orElse: () => false,
                            );

                            return IconButton(
                              onPressed: () async {
                                final notifier = ref.read(favoriteToggleProvider.notifier);
                                await notifier.toggleFavorite(widget.item.id, isFavorite);
                                if (!isFavorite && context.mounted) {
                                  AppAlert.showSuccess(context, 'Added to Favorites!');
                                }
                              },
                              icon: Icon(
                                isFavorite ? Icons.favorite : Icons.favorite_border,
                                color: isFavorite ? Colors.red : Colors.grey,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    
                    // Seller Info
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            CircleAvatar(radius: 12, backgroundColor: AppColors.primary, child: Icon(Icons.person, color: Colors.white, size: 15)),
                            SizedBox(width: 8),
                            Text(
                              'Verified Seller',
                              style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            final userId = ref.read(supabaseClientProvider).auth.currentUser?.id;
                            if (userId == widget.item.sellerId) {
                              AppAlert.showError(context, "You can't message yourself!");
                              return;
                            }

                            AppAlert.showSuccess(context, 'Connecting to seller...');
                            
                            try {
                              final result = await ref.read(directChatServiceProvider).getOrCreateConversation(
                                sellerId: widget.item.sellerId,
                                itemId: widget.item.id,
                              );

                              // Automatically send item info so the seller knows which item is being discussed
                              if (result.isNew) {
                                await ref.read(directChatServiceProvider).sendMessage(
                                  result.id,
                                  "Hi! I'm interested in your item: ${widget.item.name}.\n"
                                  "Price: ₱${widget.item.price}${widget.item.isRental ? "/day" : ""}\n"
                                  "Description: ${widget.item.description}"
                                );
                              }

                              if (context.mounted) {
                                context.push(RouteName.customerMessages);
                              }
                            } catch (e) {
                              if (context.mounted) AppAlert.showError(context, 'Could not start chat: $e');
                            }
                          },
                          icon: const Icon(Icons.chat_bubble_outline, size: 18, color: AppColors.gold),
                          label: const Text('Message Seller', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    if (widget.item.isRental) ...[
                      _buildSectionTitle('Rental Duration'),
                      const Text('1 Day | 3 Days | 7 Days', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 15),
                    ],
                    
                    _buildSectionTitle('Product Details'),
                    _buildDetailRow('Category:', widget.item.category),
                    if (widget.item.availableSizes != null) 
                      _buildDetailRow('Available Sizes:', widget.item.availableSizes!.join(', ')),
                    
                    // Measurements from JSON
                    if (widget.item.measurements != null) ...[
                      const SizedBox(height: 10),
                      ...widget.item.measurements!.entries.map((e) => _buildDetailRow('${e.key}:', e.value.toString())),
                    ],
                    
                    const SizedBox(height: 30),
                    
                    // Reviews Section
                    _buildSectionTitle('Customer Reviews'),
                    Consumer(
                      builder: (context, ref, child) {
                        final reviewsAsync = ref.watch(itemReviewsProvider(widget.item.id));
                        return reviewsAsync.when(
                          data: (reviews) {
                            if (reviews.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 10),
                                child: Text('No reviews yet. Be the first to review!', style: TextStyle(color: Colors.grey, fontSize: 12)),
                              );
                            }
                            return Column(
                              children: reviews.map((review) => _buildReviewCard(review)).toList(),
                            );
                          },
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (e, s) => Text('Error loading reviews: $e'),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 30),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: () async {
                          await AppAlert.showSuccess(context, 'Proceeding to checkout...');
                          if (context.mounted) context.push(RouteName.customerCheckout, extra: widget.item);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                        ),
                        child: Text(
                          widget.item.isRental ? 'Rent Now' : 'Buy Now', 
                          style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 18)
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppSizes.radiusLg),
          bottomRight: Radius.circular(AppSizes.radiusLg),
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
                    context.go(RouteName.customerHome);
                  }
                },
              ),
              const Text(
                'Item Details',
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
              _headerIcon(Icons.share_outlined),
              const SizedBox(width: 10),
              _headerIcon(Icons.more_vert),
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
        color: AppColors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: AppColors.white, size: 20),
    );
  }

  Widget _buildTopSection() {
    return GestureDetector(
      onTap: () => FullImageOverlay.show(context, widget.item.imageUrl),
      child: Container(
        height: 350,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(30),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Hero(
            tag: widget.item.imageUrl,
            child: Image.network(
              widget.item.imageUrl, 
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.image_not_supported, size: 50)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value, 
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(FeedbackModel review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const CircleAvatar(radius: 12, backgroundColor: Colors.grey, child: Icon(Icons.person, size: 15, color: Colors.white)),
                  const SizedBox(width: 10),
                  Text(review.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < review.rating ? Icons.star : Icons.star_border,
                    color: AppColors.gold,
                    size: 14,
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            review.comment,
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
          const SizedBox(height: 5),
          Text(
            '${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}',
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
