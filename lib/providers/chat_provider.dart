import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/env.dart';
import 'database_provider.dart';

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

    // Fetch real inventory data from Supabase to make the AI "Smart"
    String enrichedPrompt = systemPrompt;
    try {
      final items = await ref.read(itemsProvider((isRental: null, category: null, gender: null)).future);
      if (items.isNotEmpty) {
        final inventoryList = items.take(15).map((i) => 
          "- ${i.name} (${i.category}): ${i.description} [Gender: ${i.gender}, Sizes: ${i.availableSizes?.join(', ') ?? 'N/A'}, Price: ₱${i.price}]"
        ).join("\n");
        
        enrichedPrompt += "\n\nACTUAL INVENTORY IN THE SHOP (Real items from database):\n$inventoryList\n\n"
            "Use the items above to provide REAL suggestions. Mention the gender suitability and sizes if relevant to the user's question.";
      }
    } catch (e) {
      debugPrint("AI Inventory fetch failed: $e");
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
    systemPrompt: 'You are HAJA AI, the Smart Stylist for the HAJA Rental app. 🌸 '
    'You are connected to our real-time database! You don\'t just give general advice; you suggest REAL items from our inventory. '
    'When a user asks for an outfit, event advice, or mix-and-match suggestions, look at the ACTUAL INVENTORY list provided and recommend items by name. '
    'Explain WHY those items work for their event. Be extremely helpful, warm, and expert in fashion. '
    'STRICT RULE: Never use ** for bolding. Speak naturally and like a high-end personal stylist!'
  );
});

// Seller Chat Provider
final sellerChatProvider = NotifierProvider<ChatNotifier, ChatState>(() {
  return ChatNotifier(
    apiKey: Env.sellerGroqKey,
    systemPrompt: 'You are HAJA Seller Support, the expert partner for everyone selling on HAJA. ✨ '
    'You have full knowledge of the seller dashboard. You can help sellers add listings, select the correct gender and sizes for their items, and manage their shop. '
    'You know how the rental system works for them, including tracking payouts and managing order statuses like To Ship. '
    'Be the ultimate supportive colleague. Be very kind, professional, and clear. '
    'STRICT RULE: Do not use markdown like **. Speak naturally and help our sellers succeed!'
  );
});
