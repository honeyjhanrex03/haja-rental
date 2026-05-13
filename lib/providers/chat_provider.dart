import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/env.dart';
import 'database_provider.dart';
import 'auth_provider.dart';
import '../models/category_model.dart';

class ChatService {
  final Dio _dio = Dio();
  final String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';

  Future<String> getChatResponse({
    required List<Map<String, dynamic>> messages,
    required String apiKey,
    required String systemPrompt,
  }) async {
    try {
      final response = await _dio.post(
        _baseUrl,
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'model': 'llama-3.3-70b-versatile',
          'messages': [
            {
              'role': 'system',
              'content': systemPrompt,
            },
            ...messages,
          ],
        },
      );

      if (response.statusCode == 200) {
        return response.data['choices'][0]['message']['content'];
      } else {
        debugPrint('Groq API Error Status: ${response.statusCode}');
        debugPrint('Groq API Response: ${response.data}');
        return 'Sorry, I encountered an error. Please try again later.';
      }
    } on DioException catch (e) {
      debugPrint('Chat API Dio Error: ${e.type} - ${e.message}');
      if (e.response != null) {
        debugPrint('Error Response Data: ${e.response?.data}');
        final errorMsg = e.response?.data['error']?['message'] ?? 'Unknown API error';
        return 'AI Error: $errorMsg';
      }
      return 'Connection error. Please check your internet.';
    } catch (e) {
      debugPrint('Chat API General Error: $e');
      return 'An unexpected error occurred.';
    }
  }
}

final chatServiceProvider = Provider((ref) => ChatService());

class ChatMessage {
  final String text;
  final bool isUser;
  final String? imageUrl;
  ChatMessage({required this.text, required this.isUser, this.imageUrl});
}

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;

  ChatState({required this.messages, this.isLoading = false});

  ChatState copyWith({List<ChatMessage>? messages, bool? isLoading}) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ChatNotifier extends Notifier<ChatState> {
  final String apiKey;
  final String systemPrompt;

  ChatNotifier({required this.apiKey, required this.systemPrompt});

  @override
  ChatState build() => ChatState(messages: []);

  Future<void> sendMessage(String text, {String? imageUrl}) async {
    if (text.trim().isEmpty && imageUrl == null) return;

    final userMessage = ChatMessage(text: text, isUser: true, imageUrl: imageUrl);
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
    );

    // Enrich with collection knowledge, categories, trends, and user preferences
    String enrichedPrompt = systemPrompt;
    try {
      final items = await ref.read(itemsProvider((isRental: null, category: null, gender: null)).future);
      final trends = await ref.read(trendingItemsProvider.future);
      final categories = await ref.read(categoriesProvider(CategoryType.rental).future);
      final favorites = await ref.read(favoriteItemsProvider.future);
      final user = ref.read(authProvider).user;
      
      if (user != null) {
        enrichedPrompt += "\n\nUser Profile:\nName: ${user.fullName}\nLocation: ${user.address ?? 'N/A'}\n"
            "Greet the user by their first name naturally. Suggest items suitable for their location if relevant.";
      }

      if (favorites.isNotEmpty) {
        final favList = favorites.map((i) => i.name).join(", ");
        enrichedPrompt += "\n\nUser's Personal Style (Items they liked):\n$favList\n"
            "Use these favorites to understand their taste and suggest similar or complementary pieces.";
      }

      if (items.isNotEmpty) {
        final collectionList = items.take(30).map((i) => 
          "- ${i.name} (ID: ${i.id}, Category: ${i.category}): ${i.description} [Gender: ${i.gender}, Sizes: ${i.availableSizes?.join(', ') ?? 'N/A'}, Price: ₱${i.price}]"
        ).join("\n");
        
        final trendsList = trends.take(5).map((i) => "- ${i.name} (ID: ${i.id})").join("\n");
        final categoryNames = categories.map((c) => c.name).join(", ");
        
        enrichedPrompt += "\n\nOur Current Collection (USE THE IDs to recommend):\n$collectionList\n\n"
            "Recently Added & Popular Trends:\n$trendsList\n\n"
            "Shop Categories: $categoryNames\n\n"
            "MANDATORY: When you recommend an item from our collection, you MUST include its ID at the end of your sentence in this exact format: [ITEM_ID: its_id_here]. This will show a product card to the user.";
      }
    } catch (e) {
      debugPrint("AI data enrichment failed: $e");
    }

    final history = state.messages.map((m) {
      if (m.imageUrl != null) {
        return {
          'role': m.isUser ? 'user' : 'assistant',
          'content': [
            {'type': 'text', 'text': m.text},
            {'type': 'image_url', 'image_url': {'url': m.imageUrl}}
          ],
        };
      }
      return {
        'role': m.isUser ? 'user' : 'assistant',
        'content': m.text,
      };
    }).toList();

    final responseText = await ref.read(chatServiceProvider).getChatResponse(
      messages: history.cast<Map<String, dynamic>>(), // Casting to allow mixed content
      apiKey: apiKey,
      systemPrompt: enrichedPrompt,
    );
    
    final cleanText = responseText.replaceAll('**', '');
    
    final botMessage = ChatMessage(text: cleanText, isUser: false);
    state = state.copyWith(
      messages: [...state.messages, botMessage],
      isLoading: false,
    );
  }

  void clearChat() {
    state = ChatState(messages: []);
  }
}

// Customer Chat Provider - The "Smart Stylist"
final customerChatProvider = NotifierProvider<ChatNotifier, ChatState>(() {
  return ChatNotifier(
    apiKey: Env.customerGroqKey,
    systemPrompt: 'You are HAJA AI, the expert Smart Stylist for HAJA. 🌸 '
    'You have deep knowledge of everything we have in our collection and you keep a close eye on the latest local fashion trends. '
    'Suggest REAL items from our collection and explain why they are perfect for the user\'s needs. '
    'Be warm, sophisticated, and expert. Avoid technical talk about data, databases, or systems; just speak like a knowledgeable friend who knows our closet inside out. '
    'Whenever you recommend a specific item, you MUST append [ITEM_ID: <id>] to your recommendation. '
    'STRICT RULE: Never use ** for bolding. Speak naturally and like a high-end personal stylist!'
  );
});

// Seller Chat Provider
final sellerChatProvider = NotifierProvider<ChatNotifier, ChatState>(() {
  return ChatNotifier(
    apiKey: Env.sellerGroqKey,
    systemPrompt: 'You are HAJA Seller Support, the expert partner for everyone selling on HAJA. ✨ '
    'You are here to help our sellers succeed and grow their business. '
    'You can guide them through adding listings, managing their shop, and handling rentals and orders professionally. '
    'Be the ultimate supportive colleague—kind, clear, and encouraging. '
    'Avoid technical terms like "backend" or "database"; just talk about their shop and their items. '
    'STRICT RULE: Do not use markdown like **. Speak naturally and help our sellers thrive!'
  );
});
