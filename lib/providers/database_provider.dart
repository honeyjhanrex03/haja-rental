import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/item_model.dart';
import '../models/category_model.dart';
import '../models/order_model.dart';
import '../models/feedback_model.dart';
import 'auth_provider.dart';
import 'direct_chat_provider.dart';

// This provider uses the global Supabase instance
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final totalNotificationCountProvider = Provider<int>((ref) {
  final messageCount = ref.watch(unreadMessageCountProvider).maybeWhen(data: (count) => count, orElse: () => 0);
  final orders = ref.watch(userOrdersProvider).maybeWhen(
    data: (list) => list.where((o) => o.status == OrderStatus.toPay || o.status == OrderStatus.toShip).length, 
    orElse: () => 0
  );
  final sellerOrders = ref.watch(sellerOrdersProvider).maybeWhen(
    data: (list) => list.where((o) => o.status == OrderStatus.toPay || o.status == OrderStatus.toShip).length, 
    orElse: () => 0
  );
  
  return messageCount + orders + sellerOrders;
});

final itemsProvider = FutureProvider.family<List<Item>, ({bool? isRental, String? category, String? gender})>((ref, filter) async {
  // Watch auth state to re-fetch when user logs in (helps with RLS)
  ref.watch(isAuthenticatedProvider);
  final supabase = ref.watch(supabaseClientProvider);
  var query = supabase.from('items').select();
  
  if (filter.isRental != null) {
    query = query.eq('is_rental', filter.isRental!);
  }
  
  if (filter.category != null) {
    query = query.ilike('category', '%${filter.category!}%');
  }

  if (filter.gender != null) {
    query = query.eq('gender', filter.gender!);
  }
  
  final response = await query.order('created_at', ascending: false);
  
  return (response as List).map<Item>((e) => Item.fromJson(e as Map<String, dynamic>)).toList();
});

final categoriesProvider = FutureProvider.family<List<Category>, CategoryType>((ref, type) async {
  final supabase = ref.watch(supabaseClientProvider);
  final typeString = type == CategoryType.shop ? 'shop' : 'rental';
  
  try {
    final response = await supabase
        .from('categories')
        .select()
        .eq('type', typeString);
    
    final dbCategories = (response as List).map((e) => Category.fromJson(e)).toList();
    
    if (dbCategories.isNotEmpty) return dbCategories;
  } catch (e) {
    debugPrint('Database categories fetch failed, using fallbacks: $e');
  }

  // Fallback categories if DB is empty or fails
  return [
    Category(
      id: '1',
      name: 'Wedding',
      imageUrl: 'assets/category_wedding.png',
      type: CategoryType.rental,
    ),
    Category(
      id: '2',
      name: 'Formal',
      imageUrl: 'assets/category_formal.png',
      type: CategoryType.rental,
    ),
    Category(
      id: '3',
      name: 'Party',
      imageUrl: 'assets/category_party.png',
      type: CategoryType.rental,
    ),
    Category(
      id: '4',
      name: 'Casual',
      imageUrl: 'assets/category_photoshoot.png',
      type: CategoryType.rental,
    ),
  ];
});

final userOrdersProvider = StreamProvider<List<Order>>((ref) {
  final authState = ref.watch(authProvider);
  final userId = authState.user?.id;
  final supabase = ref.watch(supabaseClientProvider);
  
  if (userId == null) return Stream.value([]);

  // Smart Polling: Refresh every 3 seconds
  final timerStream = Stream.periodic(const Duration(seconds: 3));

  return timerStream.asyncMap((_) async {
    final response = await supabase
        .from('orders')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    
    return (response as List).map<Order>((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
  });
});

final sellerItemsProvider = FutureProvider<List<Item>>((ref) async {
  final authState = ref.watch(authProvider);
  final userId = authState.user?.id;
  final supabase = ref.watch(supabaseClientProvider);
  
  if (userId == null) return [];

  final response = await supabase
      .from('items')
      .select()
      .eq('seller_id', userId)
      .order('created_at', ascending: false);
  
  return (response as List).map<Item>((e) => Item.fromJson(e as Map<String, dynamic>)).toList();
});

final sellerOrdersProvider = StreamProvider<List<Order>>((ref) {
  final authState = ref.watch(authProvider);
  final userId = authState.user?.id;
  final supabase = ref.watch(supabaseClientProvider);
  
  if (userId == null) return Stream.value([]);

  // Smart Polling: Refresh every 3 seconds as a fallback for Realtime
  final timerStream = Stream.periodic(const Duration(seconds: 3));

  return timerStream.asyncMap((_) async {
    final response = await supabase
        .from('orders')
        .select()
        .eq('seller_id', userId)
        .order('created_at', ascending: false);
    
    return (response as List).map<Order>((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
  });
});

final feedbacksProvider = FutureProvider<List<FeedbackModel>>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  final response = await supabase
      .from('feedbacks')
      .select()
      .order('created_at', ascending: false)
      .limit(10);
  
  return (response as List).map((e) => FeedbackModel.fromJson(e)).toList();
});

final itemReviewsProvider = FutureProvider.family<List<FeedbackModel>, String>((ref, itemId) async {
  final supabase = ref.watch(supabaseClientProvider);
  final response = await supabase
      .from('feedbacks')
      .select()
      .eq('item_id', itemId)
      .order('created_at', ascending: false);
  
  return (response as List).map((e) => FeedbackModel.fromJson(e)).toList();
});
final userFavoritesProvider = FutureProvider<List<String>>((ref) async {
  final authState = ref.watch(authProvider);
  final userId = authState.user?.id;
  final supabase = ref.watch(supabaseClientProvider);
  if (userId == null) return [];

  final response = await supabase
      .from('favorites')
      .select('item_id')
      .eq('user_id', userId);
  
  return (response as List).map((e) => e['item_id'] as String).toList();
});

class FavoriteNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> toggleFavorite(String itemId, bool currentlyFavorite) async {
    final supabase = ref.read(supabaseClientProvider);
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    if (currentlyFavorite) {
      await supabase.from('favorites').delete().eq('user_id', userId).eq('item_id', itemId);
    } else {
      await supabase.from('favorites').insert({
        'user_id': userId,
        'item_id': itemId,
      });
    }
    ref.invalidate(userFavoritesProvider);
    ref.invalidate(favoriteItemsProvider);
  }
}

final favoriteToggleProvider = AsyncNotifierProvider<FavoriteNotifier, void>(() => FavoriteNotifier());
final favoriteItemsProvider = FutureProvider<List<Item>>((ref) async {
  final authState = ref.watch(authProvider);
  final userId = authState.user?.id;
  final supabase = ref.watch(supabaseClientProvider);
  if (userId == null) return [];

  final response = await supabase
      .from('favorites')
      .select('items(*)')
      .eq('user_id', userId);
  
  return (response as List)
      .where((e) => e['items'] != null)
      .map<Item>((e) => Item.fromJson(e['items'] as Map<String, dynamic>))
      .toList();
});

final sellerAnalyticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final authState = ref.watch(authProvider);
  final userId = authState.user?.id;
  final supabase = ref.watch(supabaseClientProvider);
  if (userId == null) return {'views': 0, 'favorites': 0, 'earnings': 0.0};

  try {
    // Total Views: Count rows in item_views for items owned by this seller
    final viewsResponse = await supabase
        .from('item_views')
        .select('id, items!inner(seller_id)')
        .eq('items.seller_id', userId);
    
    // Total Favorites: Count rows in favorites for items owned by this seller
    final favoritesResponse = await supabase
        .from('favorites')
        .select('id, items!inner(seller_id)')
        .eq('items.seller_id', userId);
        
    // Total Earnings: Sum total_price of completed orders for this seller's items
    final ordersResponse = await supabase
        .from('orders')
        .select('total_price, items!inner(seller_id)')
        .eq('status', 'completed')
        .eq('items.seller_id', userId);

    final viewsCount = (viewsResponse as List).length;
    final favoritesCount = (favoritesResponse as List).length;
    final totalEarnings = (ordersResponse as List).fold<double>(
      0, (sum, item) => sum + (double.tryParse(item['total_price'].toString()) ?? 0.0)
    );

    return {
      'views': viewsCount,
      'favorites': favoritesCount,
      'earnings': totalEarnings,
    };
  } catch (e) {
    debugPrint('Analytics error: $e');
    return {'views': 0, 'favorites': 0, 'earnings': 0.0};
  }
});
