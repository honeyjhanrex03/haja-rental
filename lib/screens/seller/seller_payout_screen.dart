import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_widgets.dart';

class SellerPayoutScreen extends ConsumerStatefulWidget {
  const SellerPayoutScreen({super.key});

  @override
  ConsumerState<SellerPayoutScreen> createState() => _SellerPayoutScreenState();
}

class _SellerPayoutScreenState extends ConsumerState<SellerPayoutScreen> {
  late TextEditingController _cardNameController;
  late TextEditingController _cardNumberController;
  late TextEditingController _expiryController;
  late TextEditingController _cvvController;
  late TextEditingController _bankNameController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    final payout = user?.payoutInfo ?? {};
    
    _cardNameController = TextEditingController(text: payout['card_name'] ?? '');
    _cardNumberController = TextEditingController(text: payout['card_number'] ?? '');
    _expiryController = TextEditingController(text: payout['expiry'] ?? '');
    _cvvController = TextEditingController(text: payout['cvv'] ?? '');
    _bankNameController = TextEditingController(text: payout['bank_name'] ?? '');
  }

  @override
  void dispose() {
    _cardNameController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _bankNameController.dispose();
    super.dispose();
  }

  Future<void> _savePayoutInfo() async {
    if (_cardNameController.text.isEmpty || _cardNumberController.text.isEmpty || _expiryController.text.isEmpty) {
      AppAlert.showError(context, 'Please fill in the required credit card details.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref.read(authProvider.notifier).updateProfile(
        payoutInfo: {
          'card_name': _cardNameController.text.trim(),
          'card_number': _cardNumberController.text.trim(),
          'expiry': _expiryController.text.trim(),
          'cvv': _cvvController.text.trim(),
          'bank_name': _bankNameController.text.trim(),
          'updated_at': DateTime.now().toIso8601String(),
        },
      );
      if (mounted) {
        AppAlert.showSuccess(context, 'Payout information updated successfully!');
        context.pop();
      }
    } catch (e) {
      if (mounted) AppAlert.showError(context, 'Failed to update payout info: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        title: const Text('Payout Methods', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Payment Settings',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                    const Text(
                      'Configure how you want to receive your earnings.',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 30),
                    
                    // Card Visual Mockup
                    _buildCardPreview(),
                    const SizedBox(height: 40),

                    const Text('Credit Card Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 20),
                    
                    _buildField('Bank Name (Optional)', _bankNameController, Icons.account_balance_outlined, hint: 'e.g. BDO, BPI, GCash'),
                    const SizedBox(height: 15),
                    _buildField('Cardholder Name', _cardNameController, Icons.person_outline, hint: 'Name as it appears on card'),
                    const SizedBox(height: 15),
                    _buildField('Card Number', _cardNumberController, Icons.credit_card, hint: '0000 0000 0000 0000', isNumber: true),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(child: _buildField('Expiry', _expiryController, Icons.calendar_today, hint: 'MM/YY')),
                        const SizedBox(width: 15),
                        Expanded(child: _buildField('CVV', _cvvController, Icons.lock_outline, hint: '123', isPassword: true)),
                      ],
                    ),
                    
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _savePayoutInfo,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        child: _isSaving 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Save Payout Method', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Center(
                      child: Text(
                        'Your payment information is encrypted and stored securely.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
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

  Widget _buildCardPreview() {
    return ListenableBuilder(
      listenable: Listenable.merge([_cardNumberController, _cardNameController, _expiryController]),
      builder: (context, _) {
        String displayNum = _cardNumberController.text.isEmpty ? '**** **** **** ****' : _cardNumberController.text;
        if (displayNum.length > 4 && !displayNum.contains('*')) {
          // Mask most of it for the preview
          displayNum = '**** **** **** ${displayNum.substring(displayNum.length - 4)}';
        }

        return Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2d2d2d), Color(0xFF1a1a1a)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.all(25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.credit_card_outlined, color: AppColors.gold, size: 40),
                  Text(
                    _bankNameController.text.isEmpty ? 'HAJA SELLER' : _bankNameController.text.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
              Text(
                displayNum,
                style: const TextStyle(color: Colors.white, fontSize: 22, letterSpacing: 2, fontWeight: FontWeight.w500),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('CARD HOLDER', style: TextStyle(color: Colors.white54, fontSize: 10)),
                      Text(
                        _cardNameController.text.isEmpty ? 'YOUR NAME' : _cardNameController.text.toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('EXPIRES', style: TextStyle(color: Colors.white54, fontSize: 10)),
                      Text(
                        _expiryController.text.isEmpty ? 'MM/YY' : _expiryController.text,
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon, {String? hint, bool isNumber = false, bool isPassword = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          obscureText: isPassword,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.gold, size: 20),
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          ),
        ),
      ],
    );
  }
}
