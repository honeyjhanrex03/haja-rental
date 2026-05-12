import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_colors.dart';
import '../../widgets/app_widgets.dart';

class HelpCenterScreen extends ConsumerWidget {
  const HelpCenterScreen({super.key});

  Future<void> _contactSupport(BuildContext context) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@hajarental.com',
      query: 'subject=Support Request - HAJA Rental',
    );

    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
      } else {
        if (context.mounted) {
          AppAlert.showInfo(context, 'Could not launch email client. Please contact us at support@hajarental.com');
        }
      }
    } catch (e) {
      if (context.mounted) {
        AppAlert.showError(context, 'Failed to open email client.');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        title: const Text('Help Center', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
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
                      'How can we help?',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Search our help articles or contact our team.',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 30),
                    
                    _buildFAQSection(),
                    
                    const SizedBox(height: 40),
                    const Text(
                      'Still need help?',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 15),
                    _buildContactCard(context),
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

  Widget _buildFAQSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Frequently Asked Questions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 15),
        _buildFAQItem(
          'How does renting work?', 
          'Choose an outfit, select your dates, and confirm your order. The seller will ship the item to you, and you return it after your rental period ends.',
        ),
        _buildFAQItem(
          'What happens if I damage an item?', 
          'Small stains or minor repairs are often covered by our basic insurance. Major damages or loss may incur additional charges based on the seller\'s policy.',
        ),
        _buildFAQItem(
          'How do I receive payments as a seller?', 
          'Once a rental is completed and the customer confirms receipt, your earnings will be credited to your balance and can be withdrawn to your saved payout method.',
        ),
        _buildFAQItem(
          'Can I cancel my rental?', 
          'Cancellations are allowed up to 48 hours before the pickup date for a full refund. Late cancellations may incur a small fee.',
        ),
        _buildFAQItem(
          'How do I ship items?', 
          'Sellers are responsible for shipping using our partner couriers. You can print the shipping label directly from your shop management dashboard.',
        ),
      ],
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Theme(
      data: ThemeData().copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Text(question, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(answer, style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.support_agent, color: AppColors.gold, size: 30),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Contact Support', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Text('Response time: < 24h', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => _contactSupport(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                  ),
                  child: const Text('Send Email', style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
