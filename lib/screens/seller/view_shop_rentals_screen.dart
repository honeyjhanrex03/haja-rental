import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../config/app_router.dart';
import '../../providers/database_provider.dart';
import '../../models/item_model.dart';
import '../../widgets/app_widgets.dart';
import '../../providers/listing_provider.dart';
import '../../widgets/seller_bottom_bar.dart';
import '../../models/order_model.dart';
import '../../services/email_service.dart';

class ViewShopRentalsScreen extends ConsumerStatefulWidget {
  final int initialTabIndex;
  const ViewShopRentalsScreen({super.key, this.initialTabIndex = 0});

  @override
  ConsumerState<ViewShopRentalsScreen> createState() => _ViewShopRentalsScreenState();
}

class _ViewShopRentalsScreenState extends ConsumerState<ViewShopRentalsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isAccepting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTabIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      bottomNavigationBar: SellerBottomNavBar(currentIndex: 2),
      body: Column(
        children: [
          _buildCustomHeader(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildItemsList(true),
                _buildItemsList(false),
                _buildOrdersList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 0),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Row(
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
                        context.go(RouteName.sellerHome);
                      }
                    },
                  ),
                  const CircleAvatar(
                    radius: 20,
                    backgroundImage: AssetImage('assets/logo.png'),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Your Shop',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: AppColors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Active',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: Colors.lightGreenAccent,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  Consumer(
                    builder: (context, ref, child) {
                      final unreadCount = ref.watch(totalNotificationCountProvider);
                      return IconButton(
                        onPressed: () => context.push(RouteName.customerNotifications),
                        icon: Badge(
                          label: Text(unreadCount.toString()),
                          isLabelVisible: unreadCount > 0,
                          backgroundColor: Colors.red,
                          child: const Icon(Icons.notifications_none, color: AppColors.white),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  Builder(
                    builder: (context) => IconButton(
                      onPressed: () => Scaffold.of(context).openDrawer(),
                      icon: const Icon(Icons.menu, color: AppColors.white)
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          TabBar(
            controller: _tabController,
            indicatorColor: AppColors.gold,
            indicatorWeight: 3,
            labelColor: AppColors.white,
            unselectedLabelColor: AppColors.white.withValues(alpha: 0.6),
            indicatorPadding: EdgeInsets.zero,
            labelStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold),
            unselectedLabelStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.normal),
            tabs: const [
              Tab(text: 'Rental'),
              Tab(text: 'Shop'),
              Tab(text: 'Orders'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList(bool isRental) {
    final itemsAsync = ref.watch(sellerItemsProvider);

    return itemsAsync.when(
      data: (items) {
        final filteredItems = items.where((i) => i.isRental == isRental).toList();
        
        if (filteredItems.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(sellerItemsProvider),
            child: ListView(
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey),
                      const SizedBox(height: 10),
                      Text('No ${isRental ? "rentals" : "items"} found.'),
                      TextButton(
                        onPressed: () => context.push(RouteName.sellerAddListing),
                        child: const Text('Add your first listing'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
 
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(sellerItemsProvider),
          child: GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.55,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
            ),
            itemCount: filteredItems.length,
            itemBuilder: (context, index) {
              final item = filteredItems[index];
              return _buildItemCard(item);
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildItemCard(Item item) {
    return Column(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => FullImageOverlay.show(context, item.images.isNotEmpty ? item.images : [item.imageUrl]),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(15),
                image: DecorationImage(
                  image: NetworkImage(item.imageUrl),
                  fit: BoxFit.cover,
                  onError: (exception, stackTrace) {},
                ),
              ),
              child: item.imageUrl.isEmpty 
                ? const Center(child: Icon(Icons.image_outlined)) 
                : Hero(tag: item.imageUrl, child: const SizedBox.expand()),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          item.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        ),
        Text(
          '₱ ${item.price}',
          style: const TextStyle(fontSize: 9, color: AppColors.primary),
        ),
        const SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.blue),
              onPressed: () => context.push(RouteName.sellerAddListing, extra: item),
            ),
            const SizedBox(width: 5),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
              onPressed: () => _showDeleteDialog(context, item),
            ),
          ],
        ),
      ],
    );
  }

  void _showDeleteDialog(BuildContext context, Item item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to remove "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref.read(listingProvider.notifier).deleteListing(item.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  AppAlert.showSuccess(context, 'Item deleted successfully');
                }
              } catch (e) {
                if (context.mounted) {
                  AppAlert.showError(context, 'Failed to delete item. Please check your connection and try again.');
                }
                debugPrint('Delete error: $e');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList() {
    final ordersAsync = ref.watch(sellerOrdersProvider);

    return ordersAsync.when(
      data: (orders) {
        if (orders.isEmpty) {
          return ListView(
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.3),
              const Center(
                child: Column(
                  children: [
                    Icon(Icons.shopping_bag_outlined, size: 60, color: Colors.grey),
                    SizedBox(height: 10),
                    Text('No orders received yet.'),
                  ],
                ),
              ),
            ],
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return _buildOrderCard(order);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildOrderCard(Order order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
        collapsedShape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            order.itemImageUrl,
            height: 60,
            width: 50,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[200], child: const Icon(Icons.image)),
          ),
        ),
        title: Text(order.itemName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(
          'Status: ${order.status.displayName.toUpperCase()}', 
          style: TextStyle(
            fontSize: 10, 
            fontWeight: FontWeight.bold,
            color: order.status == OrderStatus.toPay ? Colors.orange : Colors.blue
          )
        ),
        trailing: Text('₱${order.totalPrice}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
        children: [
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const SizedBox(height: 10),
                
                // ORDER DETAILS SECTION
                const Text('ORDER DETAILS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 10),
                _buildOrderDetailRow(Icons.straighten, 'Size', order.size ?? 'Standard'),
                _buildOrderDetailRow(Icons.payments_outlined, 'Payment', order.paymentMethod ?? 'Not Specified'),
                
                if (order.isRental) ...[
                   _buildOrderDetailRow(Icons.calendar_today, 'Pickup', order.pickupDate != null ? "${order.pickupDate!.day}/${order.pickupDate!.month}/${order.pickupDate!.year}" : 'N/A'),
                   _buildOrderDetailRow(Icons.keyboard_return, 'Return', order.returnDate != null ? "${order.returnDate!.day}/${order.returnDate!.month}/${order.returnDate!.year}" : 'N/A'),
                ],
                
                const SizedBox(height: 15),
                
                // DELIVERY ADDRESS SECTION
                const Text('DELIVERY ADDRESS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, color: AppColors.gold, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          order.deliveryAddress ?? 'No address provided',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // ACTIONS
                if (order.status == OrderStatus.toPay)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isAccepting ? null : () => _updateOrderStatus(order, 'to_ship', 'Order accepted! Moving to shipping.'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _isAccepting 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Accept Order', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                if (order.status == OrderStatus.toShip)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isAccepting ? null : () => _updateOrderStatus(order, 'to_receive', 'Order marked as shipped!'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _isAccepting 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Mark as Shipped', style: TextStyle(color: Colors.white)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 10),
          Text('$label: ', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<void> _updateOrderStatus(Order order, String newStatus, String successMessage) async {
    setState(() => _isAccepting = true);
    try {
      final supabase = ref.read(supabaseClientProvider);
      
      // 1. Update status in DB and check if it actually worked
      final updateResponse = await supabase
          .from('orders')
          .update({'status': newStatus})
          .eq('id', order.id)
          .select();
      
      if ((updateResponse as List).isEmpty) {
        throw 'Database update failed. Please check your SQL policies (RLS).';
      }
      
      // 2. Fetch customer email to notify them
      final customerData = await supabase
          .from('profiles')
          .select('full_name, email')
          .eq('id', order.customerId)
          .maybeSingle();

      final customerEmail = customerData?['email']?.toString();
      final customerName = customerData?['full_name']?.toString() ?? 'Customer';

      if (customerEmail != null) {
        debugPrint('📧 TRIGGERING EMAIL: Notify Customer about $newStatus');
        EmailService().sendEmail(
          toEmail: customerEmail,
          toName: customerName,
          subject: 'Order Update: ${order.itemName}',
          htmlContent: EmailService().getStatusUpdateTemplate(
            customerName,
            order.itemName,
            newStatus.replaceAll('_', ' ').toUpperCase(),
            successMessage,
          ),
        ).catchError((e) {
          debugPrint('⚠️ EMAIL BACKGROUND ERROR: $e');
          return false;
        });
      }
      
      // 3. Force a small delay to let DB finish, then refresh UI
      await Future.delayed(const Duration(milliseconds: 500));
      ref.invalidate(sellerOrdersProvider);
      
      if (mounted) AppAlert.showSuccess(context, successMessage);
    } catch (e) {
      if (mounted) AppAlert.showError(context, 'Failed to update order: $e');
    } finally {
      if (mounted) setState(() => _isAccepting = false);
    }
  }
}
