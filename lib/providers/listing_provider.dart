import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/item_model.dart';
import 'database_provider.dart';
import 'direct_chat_provider.dart';

class ListingNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    return;
  }

  Future<void> addListing(Item item) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      final supabase = ref.read(supabaseClientProvider);
      await supabase.from('items').insert(item.toJson());
      ref.invalidate(sellerItemsProvider);
      ref.invalidate(itemsProvider);
    });
    state = result;
    if (result.hasError) throw result.error!;
  }

  Future<void> updateListing(Item item) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      final supabase = ref.read(supabaseClientProvider);
      await supabase.from('items').update(item.toJson()).eq('id', item.id);
      ref.invalidate(sellerItemsProvider);
      ref.invalidate(itemsProvider);
    });
    state = result;
    if (result.hasError) throw result.error!;
  }

  Future<void> deleteListing(String id) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      final supabase = ref.read(supabaseClientProvider);
      
      // DEEP CLEAN: Delete all dependencies one by one
      
      // 1. Delete Favorites
      try {
        await supabase.from('favorites').delete().eq('item_id', id);
      } catch (_) {}
      
      // 2. Delete Item Views
      try {
        await supabase.from('item_views').delete().eq('item_id', id);
      } catch (_) {}

      // 3. Delete Orders
      try {
        await supabase.from('orders').delete().eq('item_id', id);
      } catch (_) {}
      
      // 4. Delete Chat Conversations & Messages
      try {
        final convs = await supabase.from('conversations').select('id').eq('item_id', id);
        for (final conv in (convs as List)) {
          final convId = conv['id'].toString();
          await supabase.from('messages').delete().eq('conversation_id', convId);
          await supabase.from('conversations').delete().eq('id', convId);
        }
      } catch (_) {}

      // 5. Finally delete the item
      await supabase.from('items').delete().eq('id', id);

      // Invalidate everything to refresh UI
      Future.microtask(() {
        ref.invalidate(sellerItemsProvider);
        ref.invalidate(itemsProvider);
        ref.invalidate(userOrdersProvider);
        ref.invalidate(sellerOrdersProvider);
        ref.invalidate(conversationsProvider);
      });
    });
    state = result;
    if (result.hasError) throw result.error!;
  }
}

final listingProvider = AsyncNotifierProvider<ListingNotifier, void>(() {
  return ListingNotifier();
});
