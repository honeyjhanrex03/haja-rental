import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../config/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/database_provider.dart';
import '../../widgets/app_widgets.dart';

class AddAddressScreen extends ConsumerStatefulWidget {
  const AddAddressScreen({super.key});

  @override
  ConsumerState<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends ConsumerState<AddAddressScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _postalController = TextEditingController();
  final _streetController = TextEditingController();
  bool _isHome = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _postalController.dispose();
    _streetController.dispose();
    super.dispose();
  }

  Future<void> _submitAddress() async {
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty || _cityController.text.isEmpty) {
      AppAlert.showError(context, 'Please fill in all required fields');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final supabase = ref.read(supabaseClientProvider);
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) return;

      final fullAddress = '${_streetController.text}, ${_cityController.text}, ${_postalController.text} (${_isHome ? "Home" : "Work"})';

      await supabase.from('profiles').update({
        'full_name': _nameController.text,
        'contact_number': _phoneController.text,
        'address': fullAddress,
      }).eq('id', userId);

      // Refresh auth state to reflect changes in profile
      await ref.read(authProvider.notifier).checkAuthStatus();

      if (mounted) {
        AppAlert.showSuccess(context, 'Address updated successfully!');
        context.pop();
      }
    } catch (e) {
      if (mounted) AppAlert.showError(context, 'Failed to update address: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
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
                    const Text(
                      'Delivery Details',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    _buildInputField('Full Name', _nameController),
                    const SizedBox(height: 15),
                    _buildInputField('Contact Number', _phoneController),
                    const SizedBox(height: 15),
                    _buildInputField('Region, Province, City, Brgy', _cityController),
                    const SizedBox(height: 15),
                    _buildInputField('Postal Code', _postalController),
                    const SizedBox(height: 15),
                    _buildInputField('Street Name, Building, House No.', _streetController),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Text('Label As:', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 10),
                        _buildLabelOption('Home', _isHome, () => setState(() => _isHome = true)),
                        const SizedBox(width: 10),
                        _buildLabelOption('Work', !_isHome, () => setState(() => _isHome = false)),
                      ],
                    ),
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => context.pop(),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.grey),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 15),
                            ),
                            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitAddress,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 15),
                            ),
                            child: _isSubmitting 
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Submit', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
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
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
      ),
      child: Row(
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
          const SizedBox(width: 10),
          const Text('Shipping Address', style: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildLabelOption(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_off, size: 20, color: isSelected ? AppColors.primary : Colors.grey),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
