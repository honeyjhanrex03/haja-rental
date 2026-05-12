import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../providers/database_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/order_model.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/app_widgets.dart';
import '../../services/email_service.dart';
import '../../config/app_router.dart';

class TrackOrdersScreen extends ConsumerStatefulWidget {
  const TrackOrdersScreen({super.key});

  @override
  ConsumerState<TrackOrdersScreen> createState() => _TrackOrdersScreenState();
}

class _TrackOrdersScreenState extends ConsumerState<TrackOrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF5E6), // Figma beige
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 2),
      body: Column(
        children: [
          _buildHeader(context),
          _buildTabs(),
          const SizedBox(height: 10),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOrderList(ref),
                _buildOrderList(ref, filter: OrderStatus.toPay),
                _buildOrderList(ref, filter: OrderStatus.toShip),
                _buildOrderList(ref, filter: OrderStatus.toReceive),
                _buildOrderList(ref, filter: OrderStatus.completed),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.black),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(RouteName.customerHome);
                  }
                },
              ),
              const Text(
                'Track Orders',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.notifications_none, size: 24),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.menu, size: 24),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F1E7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: Text(
                'Orders',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return TabBar(
      controller: _tabController,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      labelColor: AppColors.black,
      unselectedLabelColor: Colors.grey,
      indicatorColor: AppColors.black,
      indicatorWeight: 3,
      indicatorPadding: EdgeInsets.zero,
      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
      tabs: const [
        Tab(text: 'All'),
        Tab(text: 'To Pay'),
        Tab(text: 'To Ship'),
        Tab(text: 'To Receive'),
        Tab(text: 'Completed'),
      ],
    );
  }

  Widget _buildOrderList(WidgetRef ref, {OrderStatus? filter}) {
    final ordersAsync = ref.watch(userOrdersProvider);

    return ordersAsync.when(
      data: (allOrders) {
        final orders = filter == null 
            ? allOrders 
            : allOrders.where((o) => o.status == filter).toList();

        if (orders.isEmpty) {
          return const Center(child: Text('No orders found'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            try {
              final order = orders[index];
              final rentalDays = order.returnDate != null && order.pickupDate != null 
                  ? order.returnDate!.difference(order.pickupDate!).inDays 
                  : 1;
              final displayDays = rentalDays > 0 ? rentalDays : 1;

              return GestureDetector(
                onTap: () {
                  if (order.status == OrderStatus.toPay) {
                    _showOrderOptions(context, order);
                  } else {
                    _showOrderDetails(context, order);
                  }
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 70,
                        height: 90,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          image: DecorationImage(
                            image: NetworkImage(order.itemImageUrl.isNotEmpty ? order.itemImageUrl : 'https://via.placeholder.com/150'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.itemDescription.isNotEmpty ? order.itemDescription : 'No description provided',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              order.isRental 
                                ? '₱${((order.totalPrice - 250) / displayDays).toStringAsFixed(2)}/day  ×  $displayDays-day rental'
                                : '₱${(order.totalPrice - 250).toStringAsFixed(2)} - One-time purchase', 
                              style: const TextStyle(fontSize: 10, color: Colors.grey)
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey[300]!),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    order.isRental ? 'Rent' : 'Buy', 
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)
                                  ),
                                ),
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text('Total:', style: TextStyle(fontSize: 9, color: Colors.grey)),
                                      Text(
                                        '₱${order.totalPrice.toStringAsFixed(2)}', 
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (order.status == OrderStatus.toReceive) ...[
                              const SizedBox(height: 15),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () => _showReviewDialog(context, order),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: const Text('Order Received', style: TextStyle(color: Colors.white, fontSize: 11)),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            } catch (e) {
              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(15)),
                child: const Text('Error loading order data', style: TextStyle(color: Colors.red, fontSize: 10)),
              );
            }
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  void _showOrderOptions(BuildContext context, Order order) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Manage Order', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.info_outline, color: AppColors.primary),
              title: const Text('View Details'),
              onTap: () {
                Navigator.pop(context);
                _showOrderDetails(context, order);
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel_outlined, color: Colors.red),
              title: const Text('Cancel Order', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmCancel(context, order);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showOrderDetails(BuildContext context, Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(25),
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: Text('Order Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
            const SizedBox(height: 30),
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.network(order.itemImageUrl, height: 150, width: 120, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 20),
            _detailRow('Item:', order.itemName),
            _detailRow('Status:', order.status.displayName.toUpperCase()),
            _detailRow('Total Price:', '₱${order.totalPrice.toStringAsFixed(2)}'),
            if (order.size != null) _detailRow('Size:', order.size!),
            if (order.isRental) ...[
              _detailRow('Pickup Date:', order.pickupDate?.toString().split(' ').first ?? 'N/A'),
              _detailRow('Return Date:', order.returnDate?.toString().split(' ').first ?? 'N/A'),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))),
                child: const Text('Close', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmCancel(BuildContext context, Order order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order?'),
        content: const Text('Are you sure you want to cancel this order? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('No')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _cancelOrder(order);
            },
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelOrder(Order order) async {
    try {
      final supabase = ref.read(supabaseClientProvider);
      await supabase.from('orders').delete().eq('id', order.id);
      
      // Invalidate both to ensure sync
      ref.invalidate(userOrdersProvider);
      ref.invalidate(sellerOrdersProvider);
      
      if (mounted) AppAlert.showSuccess(context, 'Order cancelled successfully');
    } catch (e) {
      if (mounted) AppAlert.showError(context, 'Failed to cancel order: $e');
    }
  }

  void _showReviewDialog(BuildContext context, Order order) {
    int rating = 5;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Rate your experience'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('How was the item?'),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: AppColors.gold,
                      size: 30,
                    ),
                    onPressed: () => setDialogState(() => rating = index + 1),
                  );
                }),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: commentController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Leave a comment...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Later')),
            ElevatedButton(
              onPressed: () async {
                final comment = commentController.text.trim();
                if (comment.isEmpty) {
                  AppAlert.showError(context, 'Please leave a comment');
                  return;
                }
                Navigator.pop(context);
                await _submitReview(order, rating, comment);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Submit', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitReview(Order order, int rating, String comment) async {
    try {
      final supabase = ref.read(supabaseClientProvider);
      final user = ref.read(authProvider).user;
      
      // 1. Update Order Status and verify it worked
      final updateResponse = await supabase
          .from('orders')
          .update({'status': 'completed'})
          .eq('id', order.id)
          .select();
          
      if ((updateResponse as List).isEmpty) {
        throw 'Database update failed. Please check your SQL policies (RLS).';
      }
      
      // 2. Save Feedback
      await supabase.from('feedbacks').insert({
        'user_id': user?.id,
        'user_name': user?.fullName ?? 'User',
        'comment': comment,
        'rating': rating,
        'item_id': order.itemId,
      });

      // 3. Notify Seller that order is completed
      // 3. Notify Seller that order is completed (Non-blocking)
      () async {
        try {
          final sellerData = await supabase
              .from('profiles')
              .select('full_name, email')
              .eq('id', order.sellerId)
              .maybeSingle();

          final sellerEmail = sellerData?['email']?.toString();
          final sellerName = sellerData?['full_name']?.toString() ?? 'Seller';

          if (sellerEmail != null) {
            await EmailService().sendEmail(
              toEmail: sellerEmail,
              toName: sellerName,
              subject: 'Order Completed: ${order.itemName}',
              htmlContent: EmailService().getStatusUpdateTemplate(
                sellerName,
                order.itemName,
                'COMPLETED',
                'The customer has received the item and left a $rating-star review!',
              ),
            );
          }
        } catch (emailErr) {
          debugPrint('Non-critical background error: $emailErr');
        }
      }();

      ref.invalidate(userOrdersProvider);
      if (mounted) AppAlert.showSuccess(context, 'Thank you for your feedback!');
    } catch (e) {
      if (mounted) AppAlert.showError(context, 'Failed to submit review: $e');
    }
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
