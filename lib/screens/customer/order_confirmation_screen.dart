import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../config/app_colors.dart';
import '../../config/app_router.dart';
import '../../models/item_model.dart';
import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/database_provider.dart';
import '../../providers/admin_provider.dart';
import '../../models/coupon_model.dart';
import '../../services/email_service.dart';
import '../../widgets/app_widgets.dart';

class CustomerOrderConfirmationScreen extends ConsumerStatefulWidget {
  final Item item;
  const CustomerOrderConfirmationScreen({super.key, required this.item});

  @override
  ConsumerState<CustomerOrderConfirmationScreen> createState() => _CustomerOrderConfirmationScreenState();
}

class _CustomerOrderConfirmationScreenState extends ConsumerState<CustomerOrderConfirmationScreen> {
  late TextEditingController _couponController;
  late TextEditingController _cardNumberController;
  late TextEditingController _expiryController;
  late TextEditingController _cvvController;
  late TextEditingController _cardNameController;

  String _paymentMethod = 'Cash on Delivery';
  String _selectedSize = 'Medium';
  DateTime _pickupDate = DateTime.now();
  DateTime _returnDate = DateTime.now().add(const Duration(days: 3));
  bool _isOrdering = false;
  bool _isValidatingCoupon = false;
  Coupon? _appliedCoupon;

  @override
  void initState() {
    super.initState();
    _couponController = TextEditingController();
    _cardNumberController = TextEditingController();
    _expiryController = TextEditingController();
    _cvvController = TextEditingController();
    _cardNameController = TextEditingController();
  }

  @override
  void dispose() {
    _couponController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardNameController.dispose();
    super.dispose();
  }

  Future<void> _validateCoupon() async {
    final code = _couponController.text.trim();
    if (code.isEmpty) return;

    setState(() => _isValidatingCoupon = true);
    try {
      final coupon = await ref.read(adminProvider.notifier).validateCoupon(code);
      setState(() {
        _appliedCoupon = coupon;
        _isValidatingCoupon = false;
      });
      if (coupon == null && mounted) {
        AppAlert.showError(context, 'Invalid or expired discount code.');
      } else if (mounted) {
        AppAlert.showSuccess(context, 'Discount applied!');
      }
    } catch (e) {
      setState(() => _isValidatingCoupon = false);
      if (mounted) AppAlert.showError(context, 'Failed to validate coupon: $e');
    }
  }

  double _calculateDiscount(double subtotal) {
    if (_appliedCoupon == null) return 0.0;
    if (_appliedCoupon!.type == DiscountType.percentage) {
      return subtotal * (_appliedCoupon!.discountValue / 100);
    } else {
      return _appliedCoupon!.discountValue;
    }
  }

  Future<void> _selectDate(BuildContext context, bool isPickup) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isPickup ? _pickupDate : _returnDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isPickup) {
          _pickupDate = picked;
          if (_returnDate.isBefore(_pickupDate)) {
            _returnDate = _pickupDate.add(const Duration(days: 3));
          }
        } else {
          _returnDate = picked;
        }
      });
    }
  }

  Future<void> _confirmOrder() async {
    final user = ref.read(authProvider).user;
    if (user == null) {
      AppAlert.showError(context, 'You must be logged in to order.');
      return;
    }

    if (_paymentMethod == 'Credit Card') {
      if (_cardNumberController.text.isEmpty || _expiryController.text.isEmpty || _cvvController.text.isEmpty || _cardNameController.text.isEmpty) {
        AppAlert.showError(context, 'Please fill in all credit card details.');
        return;
      }
    }

    setState(() => _isOrdering = true);

    try {
      final isRental = widget.item.isRental;
      final rentalDays = _returnDate.difference(_pickupDate).inDays;
      final subtotal = isRental 
          ? (widget.item.price * (rentalDays > 0 ? rentalDays : 1))
          : widget.item.price;
      
      final discount = _calculateDiscount(subtotal);
      final totalPayment = (subtotal - discount) + 250.0;
      
      final supabase = ref.read(supabaseClientProvider);
      
      // FORCE-FETCH the sellerId from the item directly in DB to ensure it's not empty
      final itemData = await supabase
          .from('items')
          .select('seller_id')
          .eq('id', widget.item.id)
          .single();
      
      final actualSellerId = itemData['seller_id'];

      final order = Order(
        id: '', 
        customerId: user.id,
        userId: user.id,
        itemId: widget.item.id,
        itemName: widget.item.name,
        itemImageUrl: widget.item.imageUrl,
        itemDescription: widget.item.description,
        totalPrice: totalPayment,
        quantity: 1,
        status: OrderStatus.toPay,
        createdAt: DateTime.now(),
        isRental: widget.item.isRental,
        pickupDate: _pickupDate,
        returnDate: _returnDate,
        size: _selectedSize,
        sellerId: actualSellerId ?? widget.item.sellerId,
      );

      await supabase.from('orders').insert(order.toJson());

      // Refresh the orders providers so the new order shows up immediately for both buyer and seller
      ref.invalidate(userOrdersProvider);
      ref.invalidate(sellerOrdersProvider);

      // Send Order Confirmation Email
      final profile = ref.read(authProvider).user;
      if (profile != null) {
        final emailSent = await EmailService().sendEmail(
          toEmail: profile.email,
          toName: profile.fullName,
          subject: 'Order Confirmed: ${widget.item.name}',
          htmlContent: EmailService().getOrderConfirmationTemplate(
            profile.fullName,
            widget.item.name,
            '₱${totalPayment.toStringAsFixed(2)}',
            DateFormat('MMM dd, yyyy').format(DateTime.now()),
          ),
        );
        
        if (!emailSent && mounted) {
          debugPrint('Email sending failed but order was placed.');
          // We don't block the user, but we log it
        }
      }

        // 3. Notify Seller about New Order (Non-blocking)
        () async {
          try {
            final sellerData = await supabase
                .from('profiles')
                .select('full_name, email')
                .eq('id', widget.item.sellerId)
                .maybeSingle();

            if (sellerData != null && sellerData['email'] != null) {
              await EmailService().sendEmail(
                toEmail: sellerData['email'],
                toName: sellerData['full_name'] ?? 'Seller',
                subject: 'New Order Received: ${widget.item.name}',
                htmlContent: EmailService().getStatusUpdateTemplate(
                  sellerData['full_name'] ?? 'Seller',
                  widget.item.name,
                  'NEW ORDER',
                  'You have received a new order! Please head to your shop to accept it.',
                ),
              );
            }
          } catch (e) {
            debugPrint('Seller notification error: $e');
          }
        }();

      if (mounted) {
        _showSuccessDialog(context);
      }
    } catch (e) {
      if (mounted) AppAlert.showError(context, 'Failed to place order: $e');
    } finally {
      if (mounted) setState(() => _isOrdering = false);
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    try {
      final isRental = widget.item.isRental;
      final rentalDays = _returnDate.difference(_pickupDate).inDays;
      final displayDays = rentalDays > 0 ? rentalDays : 1;
      
      // Calculate subtotal: if rental, price * days. If sale, just price.
      final subtotal = isRental ? (widget.item.price * displayDays) : widget.item.price;
      
      final discount = _calculateDiscount(subtotal);
      const deliveryFee = 250.0;
      final totalPayment = (subtotal - discount) + deliveryFee;
      final dateFormat = DateFormat('dd/MM/yyyy');

      return Scaffold(
        backgroundColor: const Color(0xFFFDF5E6), // Figma beige
        body: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildHeader(context),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  // Title Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F1E7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        isRental ? 'Rental Confirmation' : 'Order Confirmation',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Item details
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.item.description.isNotEmpty ? widget.item.description : 'No description',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 15),
                            Text(
                              '₱ ${widget.item.price.toInt()}${isRental ? "/day" : ""}',
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(25),
                          image: DecorationImage(
                            image: NetworkImage(widget.item.imageUrl.isNotEmpty ? widget.item.imageUrl : 'https://via.placeholder.com/150'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Select size
                  const Text('Select your size:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedSize,
                        isExpanded: true,
                        items: ['Small', 'Medium', 'Large'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (val) => setState(() => _selectedSize = val ?? 'Small'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Dates (Only show for rentals)
                  if (isRental) ...[
                    Row(
                      children: [
                        Expanded(
                          child: _buildDateInput('Pickup Date:', dateFormat.format(_pickupDate), () => _selectDate(context, true)),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: _buildDateInput('Return Date:', dateFormat.format(_returnDate), () => _selectDate(context, false)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                  ],

                  const Divider(color: Colors.grey, thickness: 1),
                  const SizedBox(height: 15),

                  // Store Location
                  const Text('Store Location:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 30),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('Gardini Fashion Center', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            Text('Panabo City, Davao Del Norte', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Summary
                  Text(isRental ? 'Rental Summary:' : 'Order Summary:', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.format_quote_outlined),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isRental 
                            ? '₱${widget.item.price.toInt()}/day × $displayDays-day rental' 
                            : '₱${widget.item.price.toInt()} - One-time purchase',
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: Colors.grey, thickness: 1),
                  const SizedBox(height: 20),

                  // Payment Methods
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Payment Methods', style: TextStyle(fontWeight: FontWeight.bold)),
                      TextButton(onPressed: () {}, child: const Text('View All', style: TextStyle(color: Colors.grey, fontSize: 12))),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2F2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        _buildPaymentOption('Cash on Delivery', Icons.money, _paymentMethod, (val) => setState(() => _paymentMethod = val ?? 'Cash on Delivery')),
                        const Divider(),
                        _buildPaymentOption('Credit Card', Icons.credit_card, _paymentMethod, (val) => setState(() => _paymentMethod = val ?? 'Cash on Delivery')),
                      ],
                    ),
                  ),
                  
                  if (_paymentMethod == 'Credit Card') ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Card Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 15),
                          _buildCardField('Card Number', _cardNumberController, Icons.credit_card, hint: '0000 0000 0000 0000'),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(child: _buildCardField('Expiry', _expiryController, Icons.calendar_today, hint: 'MM/YY')),
                              const SizedBox(width: 10),
                              Expanded(child: _buildCardField('CVV', _cvvController, Icons.lock_outline, hint: '123')),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _buildCardField('Cardholder Name', _cardNameController, Icons.person_outline, hint: 'Full Name'),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 30),

                  // Discount Code Input
                  const Text('Discount Code:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _couponController,
                          style: const TextStyle(fontSize: 13),
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            hintText: 'Enter code',
                            hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                            filled: true,
                            fillColor: Colors.grey[100],
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: BorderSide(color: _appliedCoupon != null ? Colors.green : Colors.transparent),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: BorderSide(color: _appliedCoupon != null ? Colors.green : Colors.transparent),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: const BorderSide(color: Colors.black, width: 1),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 45,
                        width: 90,
                        child: ElevatedButton(
                          onPressed: _isValidatingCoupon ? null : _validateCoupon,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                            elevation: 0,
                          ),
                          child: _isValidatingCoupon 
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Apply', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                  if (_appliedCoupon != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 16),
                          const SizedBox(width: 5),
                          Text(
                            'Code applied: ${(_appliedCoupon!.type == DiscountType.percentage) ? '${_appliedCoupon!.discountValue.toStringAsFixed(0)}%' : '₱${_appliedCoupon!.discountValue.toStringAsFixed(0)}'} discount',
                            style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 30),

                  // Payment Details
                  const Text('Payment Details', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2F2),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Column(
                      children: [
                        _detailRow(isRental ? 'Rental Fee' : 'Item Price', '₱${subtotal.toStringAsFixed(2)}'),
                        if (discount > 0) ...[
                          const SizedBox(height: 10),
                          _detailRow('Discount', '-₱${discount.toStringAsFixed(2)}', valueColor: Colors.green),
                        ],
                        const SizedBox(height: 10),
                        _detailRow('Delivery Fee', '₱${deliveryFee.toStringAsFixed(2)}'),
                        const SizedBox(height: 10),
                        _detailRow('Total Payment', '₱${totalPayment.toStringAsFixed(2)}', isTotal: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Final Action
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                            Text('₱${totalPayment.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 180,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isOrdering ? null : _confirmOrder,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                          ),
                          child: _isOrdering 
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(widget.item.isRental ? 'Confirm Rent' : 'Confirm Purchase', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 60),
                const SizedBox(height: 20),
                Text('Render Error: $e', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 20),
                ElevatedButton(onPressed: () => context.pop(), child: const Text('Go Back')),
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
      child: Row(
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
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.item.category.isNotEmpty ? widget.item.category : 'Item',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
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
    );
  }

  Widget _buildDateInput(String label, String value, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: Text(value, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                const Icon(Icons.calendar_month, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentOption(String title, IconData icon, String groupValue, ValueChanged<String?> onChanged) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Colors.black),
      title: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      trailing: Radio<String>(
        value: title,
        // ignore: deprecated_member_use
        groupValue: groupValue,
        // ignore: deprecated_member_use
        onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool isTotal = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label, 
            style: TextStyle(fontSize: 11, color: isTotal ? Colors.black : Colors.grey, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(value, style: TextStyle(fontSize: 11, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, color: valueColor)),
      ],
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 20),
            const Text('Order Successful!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
            const SizedBox(height: 10),
            const Text('Your order has been placed and is being processed.', textAlign: TextAlign.center),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  context.go(RouteName.customerTrackOrders);
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: const Text('Track My Order', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardField(String label, TextEditingController controller, IconData icon, {String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 18),
            isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          ),
        ),
      ],
    );
  }
}

