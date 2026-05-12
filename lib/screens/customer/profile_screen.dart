import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../config/app_router.dart';
import '../../providers/cloudinary_provider.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/seller_bottom_bar.dart';

class CustomerProfileScreen extends ConsumerStatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  ConsumerState<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends ConsumerState<CustomerProfileScreen> {
  bool _isUploading = false;

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (pickedFile != null) {
      setState(() => _isUploading = true);
      try {
        final bytes = await pickedFile.readAsBytes();
        final cloudinary = ref.read(cloudinaryServiceProvider);
        final imageUrl = await cloudinary.uploadImage(bytes, pickedFile.name);

        if (imageUrl != null) {
          await ref.read(authProvider.notifier).updateAvatar(imageUrl);
          if (mounted) {
            AppAlert.showSuccess(context, 'Profile picture updated!');
          }
        } else {
          if (mounted) {
            AppAlert.showError(context, 'Cloudinary upload failed. Please check your connection.');
          }
        }
      } catch (e) {
        if (mounted) {
          AppAlert.showError(context, 'Failed to update profile: $e');
        }
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: AppColors.white,
      bottomNavigationBar: user?.role.name.toUpperCase() == 'SELLER'
          ? const SellerBottomNavBar(currentIndex: 3)
          : const CustomBottomNavBar(currentIndex: 3),
      body: Column(
        children: [
          _buildCustomHeader(context, user),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: _isUploading ? null : _pickAndUploadImage,
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.gold, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.grey[200],
                              backgroundImage: user?.avatarUrl != null 
                                  ? NetworkImage(user!.avatarUrl!) 
                                  : const AssetImage('assets/logo.png') as ImageProvider,
                              child: _isUploading 
                                ? const CircularProgressIndicator(color: AppColors.gold) 
                                : null,
                            ),
                          ),
                          Positioned(
                            bottom: 5,
                            right: 5,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: AppColors.gold, 
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                              ),
                              child: const Icon(Icons.edit, color: Colors.white, size: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Change Profile Photo',
                      style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 40),
                    _buildProfileField(
                      'Full Name', 
                      user?.fullName ?? 'N/A', 
                      showEditIcon: true,
                      onTap: () => _showEditNameDialog(user?.fullName ?? ''),
                    ),
                    const SizedBox(height: 20),
                    _buildProfileField('Role', user?.role.name.toUpperCase() ?? 'CUSTOMER'),
                    const SizedBox(height: 20),
                    _buildProfileField(
                      'Email Address', 
                      user?.email ?? 'N/A',
                    ),
                    const SizedBox(height: 20),
                    _buildProfileField(
                      'Contact Number', 
                      user?.contactNumber ?? 'Not set', 
                      showEditIcon: true,
                      onTap: () => _showEditContactDialog(user?.contactNumber ?? ''),
                    ),
                    const SizedBox(height: 20),
                    _buildProfileField(
                      'Address', 
                      user?.address ?? 'Not set', 
                      showEditIcon: true,
                      onTap: () => _showEditAddressDialog(user?.address ?? ''),
                    ),
                    const SizedBox(height: 40),
                    

                    
                    PrimaryButton(
                      text: 'Logout',
                      isLoading: authState.isLoading && !_isUploading,
                      onPressed: () {
                        ref.read(authProvider.notifier).logout();
                        context.go(RouteName.landing);
                      },
                    ),
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

  Widget _buildCustomHeader(BuildContext context, dynamic user) {
    return Container(
      padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
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
                  if (user?.role == UserRole.seller) {
                    context.go(RouteName.sellerHome);
                  } else {
                    context.go(RouteName.customerHome);
                  }
                },
              ),
              const Text(
                'My Profile',
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
              IconButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                    ),
                    builder: (context) => Container(
                      padding: const EdgeInsets.all(30),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Settings',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                          const SizedBox(height: 20),
                          ListTile(
                            leading: const Icon(Icons.lock_outline, color: AppColors.gold),
                            title: const Text('Account Security'),
                            onTap: () {
                              Navigator.pop(context);
                              AppAlert.showInfo(context, 'Account Security features are coming soon!');
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.gold),
                            title: const Text('Privacy Policy'),
                            onTap: () {
                              Navigator.pop(context);
                              AppAlert.showInfo(context, 'Privacy Policy will be updated soon.');
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.info_outline, color: AppColors.gold),
                            title: const Text('About HAJA'),
                            onTap: () {
                              Navigator.pop(context);
                              _showAboutDialog();
                            },
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.settings_outlined, color: AppColors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.primary),
            SizedBox(width: 10),
            Text('About HAJA', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'HAJA Rental is a premium outfit rental platform dedicated to making high-end fashion accessible to everyone.',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 15),
            Text(
              'Version 1.0.0\nDeveloped with ❤️ by HAJA Team',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showEditNameDialog(String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Full Name', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter your full name',
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.gold)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                Navigator.pop(dialogContext);
                setState(() => _isUploading = true);
                try {
                  await ref.read(authProvider.notifier).updateProfile(fullName: newName);
                  if (mounted) {
                    AppAlert.showSuccess(context, 'Name updated successfully!');
                  }
                } catch (e) {
                  if (mounted) {
                    AppAlert.showError(context, 'Failed to update name');
                  }
                } finally {
                  if (mounted) setState(() => _isUploading = false);
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditContactDialog(String currentContact) {
    final controller = TextEditingController(text: currentContact);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Contact Number', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            hintText: 'Enter your contact number',
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.gold)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final newContact = controller.text.trim();
              if (newContact.isNotEmpty) {
                Navigator.pop(dialogContext);
                setState(() => _isUploading = true);
                try {
                  await ref.read(authProvider.notifier).updateProfile(contactNumber: newContact);
                  if (mounted) {
                    AppAlert.showSuccess(context, 'Contact updated successfully!');
                  }
                } catch (e) {
                  if (mounted) {
                    AppAlert.showError(context, 'Failed to update contact');
                  }
                } finally {
                  if (mounted) setState(() => _isUploading = false);
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditAddressDialog(String currentAddress) {
    final controller = TextEditingController(text: currentAddress);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Address', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Enter your address',
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.gold)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final newAddress = controller.text.trim();
              if (newAddress.isNotEmpty) {
                Navigator.pop(dialogContext);
                setState(() => _isUploading = true);
                try {
                  await ref.read(authProvider.notifier).updateProfile(address: newAddress);
                  if (mounted) {
                    AppAlert.showSuccess(context, 'Address updated successfully!');
                  }
                } catch (e) {
                  if (mounted) {
                    AppAlert.showError(context, 'Failed to update address');
                  }
                } finally {
                  if (mounted) setState(() => _isUploading = false);
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileField(String label, String value, {bool showEditIcon = false, VoidCallback? onTap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.black),
        ),
        const SizedBox(height: 5),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(10),
              ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(value, style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.black)),
                if (showEditIcon) const Icon(Icons.edit_outlined, size: 18, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
