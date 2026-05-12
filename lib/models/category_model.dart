enum CategoryType { rental, shop }

class Category {
  final String id;
  final String name;
  final String imageUrl;
  final CategoryType type;

  Category({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.type,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Category',
      imageUrl: json['image_url']?.toString() ?? '',
      type: json['type'] == 'shop' ? CategoryType.shop : CategoryType.rental,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image_url': imageUrl,
      'type': type == CategoryType.shop ? 'shop' : 'rental',
    };
  }
}
