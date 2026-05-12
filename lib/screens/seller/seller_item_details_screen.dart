import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../config/app_router.dart';
import '../../widgets/seller_bottom_bar.dart';
import '../../providers/database_provider.dart';

class SellerItemDetailsScreen extends ConsumerWidget {
  const SellerItemDetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.white,
      bottomNavigationBar: const SellerBottomNavBar(currentIndex: 0),
      body: Column(
        children: [
          _buildCustomHeader(context),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main Image with charts overlay
                    _buildImageAndCharts(),
                    const SizedBox(height: 20),
                    
                    // Sizes
                    const Text(
                      'Available Sizes:',
                      style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Medium | Large | XLarge | XXLarge',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 14),
                    ),
                    const SizedBox(height: 20),

                    // Best for Body Types
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Best for Body Types:',
                          style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Row(
                          children: const [
                            Icon(Icons.rectangle_outlined, size: 20),
                            SizedBox(width: 5),
                            Icon(Icons.crop_square_outlined, size: 20),
                            SizedBox(width: 5),
                            Icon(Icons.change_history_outlined, size: 20),
                            SizedBox(width: 5),
                            Icon(Icons.keyboard_arrow_down_outlined, size: 20),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Description
                    const Text(
                      'Elegant navy blazer and wide-leg trousers, perfect for formal occasions.',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      '₱ 500/day',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 20),

                    // Renters Table
                    const Divider(color: AppColors.black),
                    const Center(
                      child: Text(
                        'Renters',
                        style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Divider(color: AppColors.black),
                    _buildRentersTable(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
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
                        'Shop Name',
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
                          color: Colors.green,
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
                  return GestureDetector(
                    onTap: () => context.push(RouteName.customerNotifications),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.inputBackground.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Badge(
                        label: Text(unreadCount.toString()),
                        isLabelVisible: unreadCount > 0,
                        backgroundColor: Colors.red,
                        child: const Icon(Icons.notifications_none, color: AppColors.white, size: 20),
                      ),
                    ),
                  );
                },
              ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.inputBackground.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.menu, color: AppColors.white, size: 20),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Details',
            style: TextStyle(
              fontFamily: 'Inter',
              color: AppColors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageAndCharts() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.inputBackground.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSmallChart('Pants\nWaist', {'M': '32-34', 'L': '35-37', 'XL': '38-40', 'XXL': '41-43'}),
              const Expanded(
                child: Icon(Icons.accessibility_new, size: 200, color: AppColors.black), // Placeholder for mannequin
              ),
              Column(
                children: [
                   _buildTinyChart('Jacket\nLength', {'S': '24', 'M': '25', 'L': '26', 'XL': '27'}),
                   const SizedBox(height: 20),
                   _buildSmallChart('Pants\nLength', {'M': '41', 'L': '42', 'XL': '43', 'XXL': '44'}),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallChart(String title, Map<String, String> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        ...data.entries.map((e) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Row(
            children: [
              Text(e.key, style: const TextStyle(fontSize: 8)),
              const SizedBox(width: 10),
              Container(padding: const EdgeInsets.all(2), decoration: BoxDecoration(border: Border.all(width: 0.5)), child: Text(e.value, style: const TextStyle(fontSize: 8))),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildTinyChart(String title, Map<String, String> data) {
    return Column(
      children: [
         Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
         const SizedBox(height: 5),
         Row(
           children: [
             const Text('Size', style: TextStyle(fontSize: 6)),
             const SizedBox(width: 5),
             const Text('Value', style: TextStyle(fontSize: 6)),
           ],
         ),
         ...data.entries.map((e) => Row(
           children: [
             Text(e.key, style: const TextStyle(fontSize: 6)),
             const SizedBox(width: 10),
             Text(e.value, style: const TextStyle(fontSize: 6)),
           ],
         )),
      ],
    );
  }

  Widget _buildRentersTable() {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(3),
        3: FlexColumnWidth(1),
        4: FlexColumnWidth(2),
        5: FlexColumnWidth(2),
      },
      children: [
        TableRow(
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(width: 0.5))),
          children: ['Name', 'Phone Number', 'Address', 'Size', 'Amount', 'Status'].map((e) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(e, textAlign: TextAlign.center, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
          )).toList(),
        ),
        _buildTableRow('Altea T. Pallado', '09498124593', 'Pvk 3, Brgy. San Vicente, Panabo City', 'M', '2,100', 'Rented', Colors.black),
        _buildTableRow('Jazzine Joy V. Cabuyao', '09123456789', 'Brgy. New Camalig, Carmen', 'M', '2,100', 'Rented', Colors.black),
        _buildTableRow('Honey Jean B. Ambelic', '09354111147', 'Brgy. Ising, Carmen', 'S', '2,100', 'Cancelled', Colors.red),
        _buildTableRow('Althea Compoc', '09123456789', 'Brgy. San Pedro, Panabo City', 'S', '2,100', 'Returned', Colors.green),
      ],
    );
  }

  TableRow _buildTableRow(String name, String phone, String address, String size, String amount, String status, Color statusColor) {
    return TableRow(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(width: 0.5))),
      children: [
        _tableCell(name),
        _tableCell(phone),
        _tableCell(address),
        _tableCell(size),
        _tableCell(amount),
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(status, style: TextStyle(fontSize: 6, color: statusColor)),
              const SizedBox(width: 2),
              Container(width: 4, height: 4, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tableCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 6)),
    );
  }
}

