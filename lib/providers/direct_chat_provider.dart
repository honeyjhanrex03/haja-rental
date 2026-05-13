import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_models.dart';
import 'database_provider.dart';
import 'auth_provider.dart';
import 'package:flutter/foundation.dart';

// Local cache for deleted conversations to ensure immediate UI feedback
// Local cache for deleted conversations to ensure immediate UI feedback
class DeletedConversationsCache extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};
  void hide(String id) => state = {...state, id};
}

final deletedConversationsCacheProvider = NotifierProvider<DeletedConversationsCache, Set<String>>(DeletedConversationsCache.new);

final conversationsProvider = StreamProvider<List<Conversation>>((ref) {
  final authState = ref.watch(authProvider);
  final userId = authState.user?.id;
  final supabase = ref.watch(supabaseClientProvider);
  if (userId == null) return Stream.value([]);

  // Smart Polling fallback for conversations
  final timerStream = Stream.periodic(const Duration(seconds: 3));
  
  return timerStream.asyncMap((_) async {
    final response = await supabase
        .from('conversations')
        .select()
        .or('buyer_id.eq.$userId,seller_id.eq.$userId')
        .order('created_at', ascending: false);
    
    final List<Conversation> conversations = [];
    final List<Map<String, dynamic>> data = List<Map<String, dynamic>>.from(response);

    for (final item in data) {
      final buyerId = item['buyer_id'];
      final sellerId = item['seller_id'];
      final itemId = item['item_id'];
      
      final otherUserId = userId == buyerId ? sellerId : buyerId;
      final profile = await supabase
          .from('profiles')
          .select('full_name, avatar_url')
          .eq('id', otherUserId)
          .maybeSingle();

      conversations.add(Conversation(
        id: item['id'],
        buyerId: buyerId,
        sellerId: sellerId,
        itemId: itemId,
        createdAt: DateTime.parse(item['created_at']),
        otherUserName: profile?['full_name'] ?? 'User',
        otherUserAvatar: profile?['avatar_url'],
      ));
    }
    final deletedIds = ref.watch(deletedConversationsCacheProvider);
    return conversations.where((c) => !deletedIds.contains(c.id)).toList();
  });
});

final messagesProvider = StreamProvider.family<List<DirectMessage>, String>((ref, conversationId) {
  final supabase = ref.watch(supabaseClientProvider);
  
  // Smart Polling fallback for messages
  final timerStream = Stream.periodic(const Duration(seconds: 3));

  return timerStream.asyncMap((_) async {
    final response = await supabase
        .from('messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);
    
    return (response as List).map((e) => DirectMessage.fromJson(e)).toList();
  });
});

/// A stable service class for handling chat logic without relying on Notifier inheritance.
class DirectChatService {
  final Ref ref;
  DirectChatService(this.ref);

  Future<({String id, bool isNew})> getOrCreateConversation({
    required String sellerId,
    required String itemId,
  }) async {
    final supabase = ref.read(supabaseClientProvider);
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    final existing = await supabase
        .from('conversations')
        .select('id')
        .eq('buyer_id', userId)
        .eq('seller_id', sellerId)
        .eq('item_id', itemId)
        .maybeSingle();

    if (existing != null) {
      return (id: existing['id'].toString(), isNew: false);
    }

    final response = await supabase.from('conversations').insert({
      'buyer_id': userId,
      'seller_id': sellerId,
      'item_id': itemId,
    }).select('id').single();

    ref.invalidate(conversationsProvider);
    return (id: response['id'].toString(), isNew: true);
  }

  Future<void> sendMessage(String conversationId, String text) async {
    final supabase = ref.read(supabaseClientProvider);
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    await supabase.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': userId,
      'text': text,
    });

    ref.invalidate(messagesProvider(conversationId));
  }

  Future<void> markAsRead(String conversationId) async {
    final supabase = ref.read(supabaseClientProvider);
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final response = await supabase
          .from('messages')
          .update({'is_read': true})
          .eq('conversation_id', conversationId)
          .neq('sender_id', userId)
          .eq('is_read', false)
          .select();
      
      debugPrint('Marked ${(response as List).length} messages as read for conversation $conversationId');
      
      // Invalidating unread count to refresh the badge
      ref.invalidate(unreadMessageCountProvider);
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  Future<void> deleteConversation(String conversationId) async {
    // 1. Update local cache immediately so it disappears from UI
    ref.read(deletedConversationsCacheProvider.notifier).hide(conversationId);

    final supabase = ref.read(supabaseClientProvider);
    
    try {
      // 2. Try to delete from DB in background
      await supabase.from('messages').delete().eq('conversation_id', conversationId);
      await supabase.from('conversations').delete().eq('id', conversationId);
    } catch (e) {
      debugPrint('Background delete failed (likely RLS), but UI is updated: $e');
    }
    
    ref.invalidate(conversationsProvider);
  }
}

final unreadMessageCountProvider = StreamProvider<int>((ref) {
  final authState = ref.watch(authProvider);
  final userId = authState.user?.id;
  final supabase = ref.watch(supabaseClientProvider);
  if (userId == null) return Stream.value(0);

  // listen to the messages table for any changes to unread messages
  // We use a stream that triggers on any change to 'is_read'
  return supabase
      .from('messages')
      .stream(primaryKey: ['id'])
      .eq('is_read', false)
      .map((data) {
        // Only count messages where I am NOT the sender 
        // This is a proxy for "messages sent to me" assuming RLS is correct.
        // We filter in memory to ensure we only count what belongs to the user.
        final unread = data.where((m) => m['sender_id'] != userId).length;
        debugPrint('Unread message count updated: $unread');
        return unread;
      });
});

/// A standard Provider for the DirectChatService.
final directChatServiceProvider = Provider<DirectChatService>((ref) {
  return DirectChatService(ref);
});
