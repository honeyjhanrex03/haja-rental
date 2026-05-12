class Item {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final List<String> images;
  final String category;
  final String sellerId;
  final bool isRental;
  final String gender; // 'Women' or 'Men'
  final List<String>? availableSizes;
  final Map<String, dynamic>? measurements;

  Item({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    this.images = const [],
    required this.category,
    required this.sellerId,
    required this.isRental,
    required this.gender,
    this.availableSizes,
    this.measurements,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    List<String> imgs = [];
    if (json['images'] != null) {
      imgs = List<String>.from(json['images']);
    } else if (json['image_url'] != null) {
      imgs = [json['image_url'].toString()];
    }

    return Item(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unnamed Item',
      description: json['description']?.toString() ?? 'No description',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      imageUrl: imgs.isNotEmpty ? imgs.first : (json['image_url']?.toString() ?? ''),
      images: imgs,
      category: json['category']?.toString() ?? 'General',
      sellerId: json['seller_id']?.toString() ?? '',
      isRental: json['is_rental'] ?? true,
      gender: json['gender']?.toString() ?? 'Women',
      availableSizes: json['available_sizes'] != null ? List<String>.from(json['available_sizes']) : null,
      measurements: json['measurements'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'image_url': imageUrl,
      'images': images,
      'category': category,
      'seller_id': sellerId,
      'is_rental': isRental,
      'gender': gender,
      'available_sizes': availableSizes,
      'measurements': measurements,
    };
  }
}
