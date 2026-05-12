import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../config/app_router.dart';
import '../../providers/database_provider.dart';

class EditItemScreen extends ConsumerStatefulWidget {
  const EditItemScreen({super.key});

  @override
  ConsumerState<EditItemScreen> createState() =>
      _EditItemScreenState();
}

class _EditItemScreenState extends ConsumerState<EditItemScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedChoose = 'Apparel';
  String _selectedCategory = 'Tops / Men';
  String _selectedQuantity = 'Medium, 3';
  String _selectedDays = '1';
  String _selectedSize = 'Medium';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      bottomNavigationBar: _buildBottomBar(),
      body: Column(
        children: [
          _buildCustomHeader(),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Item Image with charts
                      _buildImageWithCharts(),
                      const SizedBox(height: 30),

                      // Choose Row
                      _buildFormRow('Choose:', _buildDropdown(['Rent', 'Apparel'], _selectedChoose, (val) => setState(() => _selectedChoose = val!))),
                      const SizedBox(height: 15),

                      // Category Row
                      _buildFormRow('Category:', _buildDropdown(['Tops / Men', 'Pants / Men', 'Accessories'], _selectedCategory, (val) => setState(() => _selectedCategory = val!))),
                      const SizedBox(height: 15),

                      // Description Row
                      _buildFormRow('Description:', _buildTextArea(initialValue: 'Green Stüssy graphic t-shirt with a relaxed fit, perfect for casual everyday wear.', height: 100)),
                      const SizedBox(height: 15),

                      // Price Row
                      _buildFormRow('Price:', _buildTextField(initialValue: '₱ 250')),
                      const SizedBox(height: 15),

                      // Available Sizes Row
                      _buildFormRow(
                        'Available Sizes:',
                        Row(
                          children: [
                            _buildRadio('Small', 'Small'),
                            _buildRadio('Medium', 'Medium'),
                            _buildRadio('Large', 'Large'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Available Quantity Row
                      _buildFormRow('Available Quantity:', _buildDropdown(['Medium, 3', 'Small, 1', 'Large, 5'], _selectedQuantity, (val) => setState(() => _selectedQuantity = val!))),
                      const SizedBox(height: 15),

                      // Allowed Rental Days Row
                      _buildFormRow('Allowed Rental Days:', _buildDropdown(['1', '2', '3', '5', '7'], _selectedDays, (val) => setState(() => _selectedDays = val!))),
                      const SizedBox(height: 15),

                      // Product Details Row
                      _buildFormRow('Product Details:', _buildTextArea(initialValue: '• Brand: Stüssy\n• Type: Graphic T-Shirt\n• Color: Green\n• Material: Cotton\n• Fit: Regular Fit', height: 120)),
                      const SizedBox(height: 30),

                      // Update Item Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () => _showUpdateDialog(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(32),
                            ),
                          ),
                          child: const Text(
                            'Update Item',
                            style: TextStyle(
                              color: AppColors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomHeader() {
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
                  const Text(
                    'Shop Name',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: AppColors.white,
                      fontSize: 14,
                    ),
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
          const SizedBox(height: 5),
          Row(
            children: const [
              SizedBox(width: 48),
              Icon(Icons.location_on, color: AppColors.white, size: 20),
              SizedBox(width: 5),
              Text(
                'Location',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Edit Item',
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

  Widget _buildImageWithCharts() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.inputBackground.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
           Center(child: Icon(Icons.image, size: 100, color: AppColors.textPlaceholder)),
           // Overlay placeholders for charts in the screenshot
           Positioned(left: 10, top: 10, child: _smallGrid()),
           Positioned(right: 10, top: 10, child: _smallGrid()),
           Positioned(
             bottom: 10,
             left: 0,
             right: 0,
             child: Row(
               mainAxisAlignment: MainAxisAlignment.center,
               children: const [
                  Text('Available Sizes: Medium | Large...', style: TextStyle(fontSize: 8)),
               ],
             ),
           ),
        ],
      ),
    );
  }

  Widget _smallGrid() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(border: Border.all(width: 0.5)),
      child: const Center(child: Text('Chart', style: TextStyle(fontSize: 6))),
    );
  }

  Widget _buildFormRow(String label, Widget field) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ),
            ),
          ),
        ),
        Expanded(child: field),
      ],
    );
  }

  Widget _buildDropdown(List<String> items, String value, Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: AppColors.inputBackground.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(15),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: AppColors.black),
          onChanged: onChanged,
          items: items.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value, style: const TextStyle(fontFamily: 'Inter')),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTextField({String? initialValue}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.inputBackground.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextFormField(
        initialValue: initialValue,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        ),
      ),
    );
  }

  Widget _buildTextArea({String? initialValue, double height = 80}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.inputBackground.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextFormField(
        initialValue: initialValue,
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(15),
        ),
      ),
    );
  }

  Widget _buildRadio(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Radio<String>(
          value: value,
          // ignore: deprecated_member_use
          groupValue: _selectedSize,
          // ignore: deprecated_member_use
          onChanged: (val) => setState(() => _selectedSize = val!),
          activeColor: AppColors.black,
        ),
        Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 12)),
      ],
    );
  }

  void _showUpdateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Are you sure you want to update this item?',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.white, fontFamily: 'Inter'),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text('No'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.white,
                    foregroundColor: AppColors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text('Yes'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.home_outlined, size: 30),
                  Text('Home', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(width: 40),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.person_outline, size: 30),
                  Text('Profile', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          Positioned(
            top: -30,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 70,
                height: 70,
                decoration: const BoxDecoration(
                  color: AppColors.black,
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image.asset('assets/logo.png'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

