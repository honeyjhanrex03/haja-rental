import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../config/app_colors.dart';
import '../../providers/admin_provider.dart';
import '../../models/coupon_model.dart';
import '../../services/email_service.dart';
import '../../widgets/app_widgets.dart';

class AdminCouponManagementScreen extends ConsumerStatefulWidget {
  const AdminCouponManagementScreen({super.key});

  @override
  ConsumerState<AdminCouponManagementScreen> createState() => _AdminCouponManagementScreenState();
}

class _AdminCouponManagementScreenState extends ConsumerState<AdminCouponManagementScreen> {
  List<Coupon> _coupons = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCoupons();
  }

  Future<void> _loadCoupons() async {
    setState(() => _isLoading = true);
    try {
      final coupons = await ref.read(adminProvider.notifier).fetchCoupons();
      setState(() {
        _coupons = coupons;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) AppAlert.showError(context, 'Failed to load coupons: $e');
    }
  }

  void _showCouponDialog({Coupon? coupon}) {
    final isEditing = coupon != null;
    final codeController = TextEditingController(text: coupon?.code);
    final valueController = TextEditingController(text: coupon?.discountValue.toString());
    DateTime? selectedDate = coupon?.expirationDate;
    DiscountType selectedType = coupon?.type ?? DiscountType.percentage;
    bool isActive = coupon?.isActive ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    isEditing ? 'Edit Coupon' : 'Create New Coupon',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 25),
                  TextField(
                    controller: codeController,
                    decoration: InputDecoration(
                      labelText: 'Coupon Code',
                      hintText: 'e.g. SAVE20',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.confirmation_number_outlined),
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<DiscountType>(
                    initialValue: selectedType,
                    decoration: InputDecoration(
                      labelText: 'Discount Type',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.category_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(value: DiscountType.percentage, child: Text('Percentage (%)')),
                      DropdownMenuItem(value: DiscountType.fixed, child: Text('Fixed Amount (₱)')),
                    ],
                    onChanged: (val) => setDialogState(() => selectedType = val!),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: valueController,
                    decoration: InputDecoration(
                      labelText: selectedType == DiscountType.percentage ? 'Discount Percent' : 'Discount Amount',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: Icon(selectedType == DiscountType.percentage ? Icons.percent : Icons.payments_outlined),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),
                  const Text('Expiration', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate ?? DateTime.now().add(const Duration(days: 7)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                      );
                      if (date != null) setDialogState(() => selectedDate = date);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[400]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 20, color: AppColors.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              selectedDate == null ? 'No Expiration' : DateFormat('MMMM dd, yyyy').format(selectedDate!),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          if (selectedDate != null)
                            IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => setDialogState(() => selectedDate = null),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Is Active', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Allow customers to use this coupon'),
                    value: isActive,
                    activeThumbColor: AppColors.gold,
                    activeTrackColor: AppColors.gold.withValues(alpha: 0.5),
                    onChanged: (val) => setDialogState(() => isActive = val),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (codeController.text.isEmpty || valueController.text.isEmpty) {
                              AppAlert.showError(context, 'Please fill all fields');
                              return;
                            }
                            
                            final val = double.tryParse(valueController.text) ?? 0;
                            final newCoupon = Coupon(
                              id: coupon?.id ?? '',
                              code: codeController.text.toUpperCase(),
                              discountValue: val,
                              type: selectedType,
                              expirationDate: selectedDate,
                              isActive: isActive,
                              createdAt: DateTime.now(),
                            );

                            try {
                              if (isEditing) {
                                await ref.read(adminProvider.notifier).updateCoupon(coupon.id, newCoupon.toJson());
                              } else {
                                await ref.read(adminProvider.notifier).addCoupon(newCoupon);
                              }
                              
                              if (context.mounted) {
                                Navigator.pop(context);
                                _loadCoupons();
                                AppAlert.showSuccess(context, isEditing ? 'Coupon updated' : 'Coupon created');
                              }
                            } catch (e) {
                              if (context.mounted) {
                                AppAlert.showError(context, 'Database error: $e');
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Save'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Coupon Management', style: TextStyle(color: AppColors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.gold,
        onPressed: () => _showCouponDialog(),
        child: const Icon(Icons.add, color: AppColors.white),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
        : RefreshIndicator(
            onRefresh: _loadCoupons,
            child: ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: _coupons.length,
              itemBuilder: (context, index) {
                final coupon = _coupons[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(15),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: coupon.isValid ? Colors.green[50] : Colors.red[50],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.confirmation_number_outlined, 
                        color: coupon.isValid ? Colors.green : Colors.red
                      ),
                    ),
                    title: Text(coupon.code, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.5)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          coupon.type == DiscountType.percentage 
                            ? '${coupon.discountValue.toStringAsFixed(0)}% OFF' 
                            : '₱${coupon.discountValue.toStringAsFixed(0)} OFF',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                        Text(
                          coupon.expirationDate == null 
                            ? 'No expiration' 
                            : 'Expires: ${DateFormat('MMM dd, yyyy').format(coupon.expirationDate!)}',
                          style: TextStyle(fontSize: 12, color: coupon.isExpired ? Colors.red : Colors.grey),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.campaign, color: Colors.orange), 
                          tooltip: 'Send Promotion Email',
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Send Promotion?'),
                                content: Text('This will send an email blast for "${coupon.code}" to all registered users. Continue?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                  ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Send Blast')),
                                ],
                              ),
                            );

                            if (confirm == true && context.mounted) {
                              AppAlert.showSuccess(context, 'Sending email blast...');
                              try {
                                final users = await ref.read(adminProvider.notifier).fetchAllUsers();
                                final emailService = EmailService();
                                
                                for (var user in users) {
                                  final name = user['full_name'] ?? 'Fashionista';
                                  final email = user['username']; // In profiles, username is the email
                                  if (email != null) {
                                    emailService.sendEmail(
                                      toEmail: email,
                                      toName: name,
                                      subject: 'Exclusive Offer from HAJA Rental!',
                                      htmlContent: emailService.getPromotionTemplate(
                                        name, 
                                        coupon.code, 
                                        coupon.type == DiscountType.percentage 
                                          ? '${coupon.discountValue.toStringAsFixed(0)}%' 
                                          : '₱${coupon.discountValue.toStringAsFixed(0)}'
                                      ),
                                    );
                                  }
                                }
                                if (context.mounted) AppAlert.showSuccess(context, 'Promotion blast complete!');
                              } catch (e) {
                                if (context.mounted) AppAlert.showError(context, 'Failed to send blast: $e');
                              }
                            }
                          },
                        ),
                        IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.blue), onPressed: () => _showCouponDialog(coupon: coupon)),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red), 
                          onPressed: () async {
                            await ref.read(adminProvider.notifier).deleteCoupon(coupon.id);
                            _loadCoupons();
                          }
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
    );
  }
}
