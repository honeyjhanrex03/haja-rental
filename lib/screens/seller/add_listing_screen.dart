import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_colors.dart';
import '../../providers/cloudinary_provider.dart';
import '../../providers/listing_provider.dart';
import '../../models/item_model.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/seller_bottom_bar.dart';
import '../../config/app_router.dart';
import '../../providers/database_provider.dart';
import '../../models/category_model.dart';

class AddListingScreen extends ConsumerStatefulWidget {
  final Item? itemToEdit;
  const AddListingScreen({super.key, this.itemToEdit});

  @override
  ConsumerState<AddListingScreen> createState() => _AddListingScreenState();
}

class _AddListingScreenState extends ConsumerState<AddListingScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;
  late TextEditingController _detailsController;
  
  String _selectedChoose = 'Rent';
  String _selectedCategory = 'Formal Wear';
  String _selectedSize = 'Medium';
  String _selectedGender = 'Women';
  XFile? _selectedImage;
  String? _existingImageUrl;
  bool _isUploading = false;
  String? _newId; // Store the ID for the current upload attempt

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.itemToEdit?.name ?? '');
    _priceController = TextEditingController(text: widget.itemToEdit?.price.toString() ?? '');
    _descriptionController = TextEditingController(text: widget.itemToEdit?.description ?? '');
    _detailsController = TextEditingController(text: widget.itemToEdit?.measurements?['details'] ?? '');
    
    if (widget.itemToEdit != null) {
      _selectedChoose = widget.itemToEdit!.isRental ? 'Rent' : 'Sale';
      _selectedCategory = widget.itemToEdit!.category;
      _existingImageUrl = widget.itemToEdit!.imageUrl;
      _selectedGender = widget.itemToEdit!.gender;
      if (widget.itemToEdit!.availableSizes != null && widget.itemToEdit!.availableSizes!.isNotEmpty) {
        _selectedSize = widget.itemToEdit!.availableSizes!.first;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = pickedFile;
        _existingImageUrl = null;
      });
    }
  }

  Future<void> _handleUpload() async {
    await _uploadItem();
  }

  Future<void> _uploadItem() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImage == null && _existingImageUrl == null) {
      AppAlert.showError(context, 'Please select an image');
      return;
    }

    setState(() => _isUploading = true);

    try {
      String? imageUrl = _existingImageUrl;
      
      if (_selectedImage != null) {
        final cloudinary = ref.read(cloudinaryServiceProvider);
        final bytes = await _selectedImage!.readAsBytes();
        imageUrl = await cloudinary.uploadImage(bytes, _selectedImage!.name);
      }

      if (imageUrl == null) {
        throw Exception('Image upload failed');
      }

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      _newId ??= DateTime.now().millisecondsSinceEpoch.toString();
      
      final item = Item(
        id: widget.itemToEdit?.id ?? _newId!,
        name: _nameController.text,
        description: _descriptionController.text,
        price: double.parse(_priceController.text),
        imageUrl: imageUrl,
        category: _selectedCategory,
        sellerId: user.id,
        isRental: _selectedChoose == 'Rent',
        gender: _selectedGender,
        availableSizes: [_selectedSize],
        measurements: {'details': _detailsController.text},
      );

      if (widget.itemToEdit != null) {
        await ref.read(listingProvider.notifier).updateListing(item);
        if (mounted) await AppAlert.showSuccess(context, 'Item updated successfully!');
      } else {
        await ref.read(listingProvider.notifier).addListing(item);
        if (mounted) await AppAlert.showSuccess(context, 'Item uploaded successfully!');
      }

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        AppAlert.showError(context, 'Failed to save item: $e');
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
      _newId = null; // Clear after attempt
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.itemToEdit != null;

    return Scaffold(
      backgroundColor: AppColors.white,
      bottomNavigationBar: SellerBottomNavBar(currentIndex: 2),
      body: Column(
        children: [
          _buildCustomHeader(isEditing),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.grey[300]!, width: 1),
                            image: _selectedImage != null 
                              ? (kIsWeb 
                                  ? DecorationImage(image: NetworkImage(_selectedImage!.path), fit: BoxFit.cover)
                                  : DecorationImage(image: FileImage(File(_selectedImage!.path)), fit: BoxFit.cover))
                              : (_existingImageUrl != null 
                                  ? DecorationImage(image: NetworkImage(_existingImageUrl!), fit: BoxFit.cover)
                                  : null),
                          ),
                          child: (_selectedImage == null && _existingImageUrl == null) ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.cloud_upload_outlined, size: 40, color: Colors.grey),
                              SizedBox(height: 10),
                              Text('Upload Photo here', style: TextStyle(fontSize: 18, color: Colors.grey)),
                            ],
                          ) : null,
                        ),
                      ),
                      const SizedBox(height: 30),

                      _buildFormRow('Name:', _buildTextField(_nameController, 'Enter item name')),
                      const SizedBox(height: 15),

                      _buildFormRow('Type:', _buildDropdown(['Rent', 'Sale'], _selectedChoose, (val) => setState(() => _selectedChoose = val!))),
                      const SizedBox(height: 15),

                      _buildFormRow('Category:', Consumer(
                        builder: (context, ref, child) {
                          final categoriesAsync = ref.watch(categoriesProvider(_selectedChoose == 'Rent' ? CategoryType.rental : CategoryType.shop));
                          return categoriesAsync.when(
                            data: (categories) {
                              final catNames = categories.map((c) => c.name).toList();
                              if (!catNames.contains(_selectedCategory)) {
                                catNames.add(_selectedCategory);
                              }
                              return _buildDropdown(catNames, _selectedCategory, (val) => setState(() => _selectedCategory = val!));
                            },
                            loading: () => const CircularProgressIndicator(),
                            error: (e, s) => _buildDropdown([_selectedCategory], _selectedCategory, (val) {}),
                          );
                        },
                      )),
                      const SizedBox(height: 15),

                      _buildFormRow(
                        'Gender:',
                        Row(
                          children: [
                            _buildGenderRadio('Women', _selectedGender, (val) => setState(() => _selectedGender = val!)),
                            _buildGenderRadio('Men', _selectedGender, (val) => setState(() => _selectedGender = val!)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),

                      _buildFormRow('Description:', _buildTextArea(_descriptionController, height: 100)),
                      const SizedBox(height: 15),

                      _buildFormRow('Price:', _buildTextField(_priceController, '0.00', keyboardType: TextInputType.number)),
                      const SizedBox(height: 15),

                      _buildFormRow(
                        'Size:',
                        Row(
                          children: [
                            _buildRadio('Small', 'Small', _selectedSize, (val) => setState(() => _selectedSize = val!)),
                            _buildRadio('Medium', 'Medium', _selectedSize, (val) => setState(() => _selectedSize = val!)),
                            _buildRadio('Large', 'Large', _selectedSize, (val) => setState(() => _selectedSize = val!)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),

                      _buildFormRow('Details:', _buildTextArea(_detailsController, height: 100)),
                      const SizedBox(height: 30),

                      PrimaryButton(
                        text: isEditing ? 'Update Listing' : 'Upload Item',
                        onPressed: _handleUpload,
                        isLoading: _isUploading,
                        backgroundColor: AppColors.primary,
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

  Widget _buildCustomHeader(bool isEditing) {
    return Container(
      padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: Row(
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
          const SizedBox(width: 10),
          Text(
            isEditing ? 'Edit Listing' : 'Add Listing',
            style: const TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildFormRow(String label, Widget field) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 100, child: Padding(padding: const EdgeInsets.only(top: 12.0), child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)))),
        Expanded(child: field),
      ],
    );
  }

  Widget _buildDropdown(List<String> items, String value, Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(15)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          onChanged: onChanged,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppColors.cardBackground,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildTextArea(TextEditingController controller, {double height = 80}) {
    return Container(
      height: height,
      decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(15)),
      child: TextField(
        controller: controller,
        maxLines: null,
        expands: true,
        decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.all(12)),
      ),
    );
  }

  Widget _buildGenderRadio(String value, String groupValue, ValueChanged<String?> onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Radio<String>(
          value: value,
          // ignore: deprecated_member_use
          groupValue: groupValue,
          // ignore: deprecated_member_use
          onChanged: onChanged,
          activeColor: AppColors.gold,
        ),
        Text(value, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildRadio(String label, String value, String groupValue, ValueChanged<String?> onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Radio<String>(
          value: value,
          // ignore: deprecated_member_use
          groupValue: groupValue,
          // ignore: deprecated_member_use
          onChanged: onChanged,
          activeColor: AppColors.gold,
        ),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
