import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:cropcure/config/gemini_config.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isStreaming;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isStreaming = false,
  });

  ChatMessage copyWith({
    String? text,
    bool? isUser,
    DateTime? timestamp,
    bool? isStreaming,
  }) {
    return ChatMessage(
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }
}

class ChatbotController extends GetxController {
  final RxList<ChatMessage> messages = <ChatMessage>[].obs;
  var isLoading = false.obs;
  final TextEditingController textController = TextEditingController();
  GenerativeModel? _chatModel;
  DateTime? _lastRequest;
  static const int _requestCooldown = 2; // 2 seconds cooldown

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? get currentUser => _auth.currentUser;
  var isLoadingHistory = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    final apiKey = await GeminiConfig.getApiKey();
    _chatModel = GenerativeModel(
      model: GeminiConfig.generalModel,
      apiKey: apiKey,
    );

    // Load chat history from Firestore
    await loadChatHistory();

    // Add welcome message only if no history exists
    if (messages.isEmpty) {
      final welcomeMessage = ChatMessage(
        text:
            'Hello! I\'m your CropCure AI assistant. I can help you with:\n\n• Plant disease treatment advice\n• Plant care tutorials\n• Disease prevention tips\n• General plant health questions\n\nHow can I help you today?',
        isUser: false,
        timestamp: DateTime.now(),
      );
      messages.add(welcomeMessage);
      // Don't save welcome message to history
    }
  }

  Future<void> loadChatHistory() async {
    if (currentUser == null) return;

    try {
      isLoadingHistory.value = true;
      final messagesRef = _firestore
          .collection('chatbot_history')
          .doc(currentUser!.uid)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .limit(100); // Limit to last 100 messages

      final snapshot = await messagesRef.get();

      messages.clear();
      for (var doc in snapshot.docs) {
        final data = doc.data();
        messages.add(
          ChatMessage(
            text: data['text'] ?? '',
            isUser: data['isUser'] ?? false,
            timestamp:
                (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
            isStreaming: false,
          ),
        );
      }
    } catch (e) {
      log('Error loading chat history: $e');
    } finally {
      isLoadingHistory.value = false;
    }
  }

  Future<void> _saveMessage(ChatMessage message) async {
    if (currentUser == null || message.isStreaming) return;

    try {
      await _firestore
          .collection('chatbot_history')
          .doc(currentUser!.uid)
          .collection('messages')
          .add({
            'text': message.text,
            'isUser': message.isUser,
            'timestamp': Timestamp.fromDate(message.timestamp),
          });
    } catch (e) {
      log('Error saving message: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _fetchRecentScanHistory() async {
    if (currentUser == null) return [];

    try {
      final querySnapshot =
          await _firestore
              .collection('plants')
              .where('userId', isEqualTo: currentUser!.uid)
              .orderBy('timestamp', descending: true)
              .limit(15) // Get last 15 scans
              .get();

      return querySnapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        return data;
      }).toList();
    } catch (e) {
      log('Error fetching scan history: $e');
      return [];
    }
  }

  String _formatScanHistoryForPrompt(List<Map<String, dynamic>> scans) {
    if (scans.isEmpty) {
      return 'The user has no recent plant scan history.';
    }

    final buffer = StringBuffer();
    buffer.writeln('The user has recently scanned the following plants:\n');

    for (var scan in scans) {
      final plantName = scan['name'] ?? 'Unknown plant';
      final disease = scan['disease'] ?? 'No disease detected';
      final timestamp = scan['timestamp'];

      String dateStr = 'Recent';
      if (timestamp != null) {
        try {
          DateTime date;
          if (timestamp is Timestamp) {
            date = timestamp.toDate();
          } else if (timestamp is String) {
            date = DateTime.parse(timestamp);
          } else {
            date = DateTime.now();
          }
          dateStr = '${date.day}/${date.month}/${date.year}';
        } catch (e) {
          // Keep default "Recent" if parsing fails
        }
      }

      buffer.writeln('- $plantName: $disease (scanned on $dateStr)');
    }

    buffer.writeln(
      '\nUse this information to provide personalized advice when the user asks about their plants, diseases they\'ve encountered, or requests follow-up treatment information.',
    );

    return buffer.toString();
  }

  String _removeMarkdown(String text) {
    // Remove markdown bold (**text**)
    text = text.replaceAllMapped(
      RegExp(r'\*\*([^*]+?)\*\*'),
      (match) => match.group(1) ?? '',
    );
    // Remove markdown italic (*text*)
    text = text.replaceAllMapped(
      RegExp(r'(?<!\*)\*([^*]+?)\*(?!\*)'),
      (match) => match.group(1) ?? '',
    );
    // Remove markdown italic (_text_)
    text = text.replaceAllMapped(
      RegExp(r'_([^_]+?)_'),
      (match) => match.group(1) ?? '',
    );
    // Remove any remaining single asterisks
    text = text.replaceAll('*', '');
    // Remove markdown headers (# ## ###)
    text = text.replaceAll(RegExp(r'^#{1,6}\s+', multiLine: true), '');
    // Remove markdown code blocks (```code```)
    text = text.replaceAll(RegExp(r'```[\s\S]*?```'), '');
    // Remove markdown inline code (`code`)
    text = text.replaceAllMapped(
      RegExp(r'`([^`]+)`'),
      (match) => match.group(1) ?? '',
    );
    // Remove any remaining dollar signs that might have been misinterpreted
    text = text.replaceAll(RegExp(r'\$1'), '');
    // Clean up any extra whitespace
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return text.trim();
  }

  bool _canMakeRequest() {
    if (_lastRequest == null) return true;
    final now = DateTime.now();
    final timeSinceLastRequest = now.difference(_lastRequest!).inSeconds;
    return timeSinceLastRequest >= _requestCooldown;
  }

  Future<void> sendMessage(String userMessage) async {
    if (userMessage.trim().isEmpty || isLoading.value) return;

    // Add user message
    final userMsg = ChatMessage(
      text: userMessage.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );
    messages.add(userMsg);
    // Save user message to Firestore
    await _saveMessage(userMsg);

    // Check rate limiting
    if (!_canMakeRequest()) {
      final rateLimitMsg = ChatMessage(
        text:
            'Please wait a moment before sending another message. I need a brief pause to process requests properly.',
        isUser: false,
        timestamp: DateTime.now(),
      );
      messages.add(rateLimitMsg);
      // Save rate limit message
      await _saveMessage(rateLimitMsg);
      return;
    }

    isLoading.value = true;
    textController.clear();

    try {
      _lastRequest = DateTime.now();

      // Fetch recent scan history to provide context
      final recentScans = await _fetchRecentScanHistory();
      final scanHistoryContext = _formatScanHistoryForPrompt(recentScans);

      // Enhanced prompt to make the AI act as a plant care expert
      final systemPrompt =
          '''You are an expert plant care assistant for CropCure, a plant disease detection and care application. 

Your role:
- Provide accurate, practical advice on plant care, disease treatment, and prevention
- Answer questions about plant health, watering, sunlight, soil, and maintenance
- Explain treatment methods clearly and step-by-step
- Offer preventive measures to keep plants healthy
- Be friendly, helpful, and professional
- Keep responses concise but informative (under 200 words when possible)
- If asked about something outside plant care, politely redirect to plant-related topics
- IMPORTANT: Use the user's scan history below to provide personalized, relevant advice. Reference their specific plants and diseases when appropriate.

USER'S RECENT SCAN HISTORY:
$scanHistoryContext

Current user question: $userMessage''';

      if (_chatModel == null) {
        final apiKey = await GeminiConfig.getApiKey();
        _chatModel = GenerativeModel(
          model: GeminiConfig.generalModel,
          apiKey: apiKey,
        );
      }

      // Create a placeholder message for streaming
      final streamingMessageIndex = messages.length;
      messages.add(
        ChatMessage(
          text: '',
          isUser: false,
          timestamp: DateTime.now(),
          isStreaming: true,
        ),
      );

      // Use streaming API
      final responseStream = _chatModel!.generateContentStream([
        Content.text(systemPrompt),
      ]);

      String accumulatedText = '';
      await for (final response in responseStream) {
        final chunk = response.text;
        if (chunk != null && chunk.isNotEmpty) {
          accumulatedText += chunk;
          // Remove markdown formatting from accumulated text for display
          final cleanedText = _removeMarkdown(accumulatedText);
          // Update the last message with accumulated text
          if (streamingMessageIndex < messages.length) {
            messages[streamingMessageIndex] = ChatMessage(
              text: cleanedText,
              isUser: false,
              timestamp: messages[streamingMessageIndex].timestamp,
              isStreaming: true,
            );
          }
        }
      }

      // Mark streaming as complete
      if (streamingMessageIndex < messages.length) {
        String finalText = accumulatedText.trim();
        if (finalText.isEmpty) {
          finalText =
              'I apologize, but I\'m having trouble processing your request right now. Please try again in a moment.';
        }
        // Remove markdown formatting
        finalText = _removeMarkdown(finalText);
        final aiMessage = ChatMessage(
          text: finalText,
          isUser: false,
          timestamp: messages[streamingMessageIndex].timestamp,
          isStreaming: false,
        );
        messages[streamingMessageIndex] = aiMessage;
        // Save AI response to Firestore
        await _saveMessage(aiMessage);
      }
    } catch (e) {
      log('Error generating response: $e');
      final errorMessage = ChatMessage(
        text:
            'I apologize, but I encountered an error. Please check your internet connection and try again.',
        isUser: false,
        timestamp: DateTime.now(),
      );
      messages.add(errorMessage);
      // Save error message to Firestore
      await _saveMessage(errorMessage);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> clearChat() async {
    if (currentUser == null) {
      messages.clear();
      _initializeChat();
      return;
    }

    try {
      // Delete all messages from Firestore
      final messagesRef = _firestore
          .collection('chatbot_history')
          .doc(currentUser!.uid)
          .collection('messages');

      final snapshot = await messagesRef.get();
      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Clear local messages
      messages.clear();

      // Re-initialize chat with welcome message
      final apiKey = await GeminiConfig.getApiKey();
      _chatModel = GenerativeModel(
        model: GeminiConfig.generalModel,
        apiKey: apiKey,
      );

      messages.add(
        ChatMessage(
          text:
              'Hello! I\'m your CropCure AI assistant. I can help you with:\n\n• Plant disease treatment advice\n• Plant care tutorials\n• Disease prevention tips\n• General plant health questions\n\nHow can I help you today?',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    } catch (e) {
      log('Error clearing chat: $e');
      // Still clear local messages even if Firestore delete fails
      messages.clear();
      _initializeChat();
    }
  }

  @override
  void onClose() {
    textController.dispose();
    super.onClose();
  }
}
