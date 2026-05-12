enum OrderStatus { toPay, toShip, toReceive, completed, cancelled }

class Order {
  final String id;
  final String customerId;
  final String userId;
  final String itemId;
  final String itemName;
  final String itemImageUrl;
  final String itemDescription;
  final double totalPrice;
  final int quantity;
  final DateTime? pickupDate;
  final DateTime? returnDate;
  final String? size;
  final OrderStatus status;
  final DateTime createdAt;
  final bool isRental;
  final String sellerId;
  final String? deliveryAddress;
  final String? couponCode;
  final double? discountAmount;

  Order({
    required this.id,
    required this.customerId,
    required this.userId,
    required this.itemId,
    required this.itemName,
    required this.itemImageUrl,
    required this.itemDescription,
    required this.totalPrice,
    required this.quantity,
    this.pickupDate,
    this.returnDate,
    this.size,
    required this.status,
    required this.createdAt,
    required this.isRental,
    required this.sellerId,
    this.deliveryAddress,
    this.couponCode,
    this.discountAmount,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id']?.toString() ?? '',
      customerId: json['customer_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      itemId: json['item_id']?.toString() ?? '',
      itemName: json['item_name']?.toString() ?? 'Item',
      itemImageUrl: json['item_image_url']?.toString() ?? '',
      itemDescription: json['item_description']?.toString() ?? '',
      totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0.0,
      quantity: json['quantity'] ?? 1,
      pickupDate: json['pickup_date'] != null ? DateTime.tryParse(json['pickup_date']) : null,
      returnDate: json['return_date'] != null ? DateTime.tryParse(json['return_date']) : null,
      size: json['size']?.toString(),
      status: _parseStatus(json['status']?.toString()),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      isRental: json['is_rental'] ?? true,
      sellerId: json['seller_id']?.toString() ?? 
                json['items']?['seller_id']?.toString() ?? '',
      deliveryAddress: json['delivery_address']?.toString(),
      couponCode: json['coupon_code']?.toString(),
      discountAmount: (json['discount_amount'] as num?)?.toDouble(),
    );
  }

  static OrderStatus _parseStatus(String? status) {
    switch (status) {
      case 'to_pay': return OrderStatus.toPay;
      case 'to_ship': return OrderStatus.toShip;
      case 'to_receive': return OrderStatus.toReceive;
      case 'completed': return OrderStatus.completed;
      default: return OrderStatus.cancelled;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'customer_id': customerId,
      'user_id': userId,
      'item_id': itemId,
      'item_name': itemName,
      'item_image_url': itemImageUrl,
      'item_description': itemDescription,
      'total_price': totalPrice,
      'quantity': quantity,
      'pickup_date': pickupDate?.toIso8601String(),
      'return_date': returnDate?.toIso8601String(),
      'size': size,
      'status': _statusToString(status),
      'is_rental': isRental,
      'seller_id': sellerId,
      'delivery_address': deliveryAddress,
      'coupon_code': couponCode,
      'discount_amount': discountAmount,
    };
  }

  static String _statusToString(OrderStatus status) {
    switch (status) {
      case OrderStatus.toPay: return 'to_pay';
      case OrderStatus.toShip: return 'to_ship';
      case OrderStatus.toReceive: return 'to_receive';
      case OrderStatus.completed: return 'completed';
      default: return 'cancelled';
    }
  }
}

extension OrderStatusExtension on OrderStatus {
  String get displayName {
    switch (this) {
      case OrderStatus.toPay: return 'To Pay';
      case OrderStatus.toShip: return 'To Ship';
      case OrderStatus.toReceive: return 'To Receive';
      case OrderStatus.completed: return 'Completed';
      case OrderStatus.cancelled: return 'Cancelled';
    }
  }
}
