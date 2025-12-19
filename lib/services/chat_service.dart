import 'dart:convert';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import '../models/chat_message.dart';

class ChatService {
  // static const String baseUrl = 'http://127.0.0.1:8000';
  static const String baseUrl = 'https://erico-putra-temucoach.pbp.cs.ui.ac.id';

  final CookieRequest request;

  ChatService(this.request);

  /// Get all conversations for current user
  Future<List<Conversation>> getConversations() async {
    try {
      final response = await request.get('$baseUrl/chat/api/conversations/');
      
      if (response['conversations'] != null) {
        final List<dynamic> conversationsJson = response['conversations'];
        return conversationsJson
            .map((json) => Conversation.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error fetching conversations: $e');
      return [];
    }
  }

  /// Get list of contacts that can be messaged
  Future<List<ChatContact>> getContacts() async {
    try {
      final response = await request.get('$baseUrl/chat/api/contacts/');
      
      if (response['contacts'] != null) {
        final List<dynamic> contactsJson = response['contacts'];
        return contactsJson
            .map((json) => ChatContact.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error fetching contacts: $e');
      return [];
    }
  }

  /// Get messages with a specific user
  Future<Map<String, dynamic>> getMessages(int receiverId) async {
    try {
      final response = await request.get('$baseUrl/chat/api/$receiverId/');
      
      List<ChatMessage> messages = [];
      if (response['messages'] != null) {
        final List<dynamic> messagesJson = response['messages'];
        messages = messagesJson
            .map((json) => ChatMessage.fromJson(json))
            .toList();
      }
      
      return {
        'messages': messages,
        'receiver_id': response['receiver_id'],
        'receiver_name': response['receiver_name'],
        'receiver_username': response['receiver_username'],
      };
    } catch (e) {
      print('Error fetching messages: $e');
      return {
        'messages': <ChatMessage>[],
        'receiver_id': receiverId,
        'receiver_name': '',
        'receiver_username': '',
      };
    }
  }

  /// Send a message to a user
  Future<ChatMessage?> sendMessage(int receiverId, String content) async {
    try {
      final response = await request.postJson(
        '$baseUrl/chat/api/$receiverId/',
        jsonEncode({'content': content}),
      );
      
      if (response['success'] == true && response['message'] != null) {
        return ChatMessage.fromJson(response['message']);
      }
      return null;
    } catch (e) {
      print('Error sending message: $e');
      return null;
    }
  }

  /// Edit a message
  Future<bool> editMessage(int messageId, String newContent) async {
    try {
      final response = await request.request(
        '$baseUrl/chat/api/message/$messageId/edit/',
        'PUT',
        body: jsonEncode({'content': newContent}),
        headers: {'Content-Type': 'application/json'},
      );
      
      return response['success'] == true;
    } catch (e) {
      print('Error editing message: $e');
      return false;
    }
  }

  /// Delete a message
  Future<bool> deleteMessage(int messageId) async {
    try {
      final response = await request.request(
        '$baseUrl/chat/api/message/$messageId/delete/',
        'DELETE',
        headers: {'Content-Type': 'application/json'},
      );
      
      return response['success'] == true;
    } catch (e) {
      print('Error deleting message: $e');
      return false;
    }
  }
}
