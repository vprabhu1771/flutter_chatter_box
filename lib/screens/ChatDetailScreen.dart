import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chat_bubbles/chat_bubbles.dart';

class ChatDetailScreen extends StatefulWidget {
  final String conversationId;
  final String receiverEmail;

  const ChatDetailScreen({super.key, required this.conversationId, required this.receiverEmail});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late String userId;
  late Stream<List<Map<String, dynamic>>> messageStream;

  @override
  void initState() {
    super.initState();
    // userId = supabase.auth.currentUser!.id;
    // messageStream = _streamMessages();
    // _subscribeToRealtimeMessages();

    final user = supabase.auth.currentUser;
    if (user != null) {
      userId = user.id;
      print("User ID: $userId"); // ✅ Debugging user ID
      messageStream = _streamMessages();
      _subscribeToRealtimeMessages();
    } else {
      print("No user logged in!");
    }
  }

  // 🔹 Function to stream messages for the given conversation ID
  Stream<List<Map<String, dynamic>>> _streamMessages() {
    return supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', widget.conversationId)
        .order('created_at', ascending: true) // ✅ Explicit ordering
    // .map((messages) => messages);
        .map((messages) {
      print("📩 New Messages Retrieved: ${messages.length}");
      for (var msg in messages) {
        print("🔹 Message: ${msg['content']} | Sender: ${msg['sender_id']} | Time: ${msg['created_at']}");
      }
      return messages;
    });
  }


  // 🔹 Subscribe to Supabase Realtime for new messages
  void _subscribeToRealtimeMessages() {
    supabase.channel('messages_realtime')
        .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'messages',
      callback: (payload) {
        if (payload.newRecord['conversation_id'] == widget.conversationId) {
          setState(() {}); // ✅ Ensure new messages are shown
        }
      },
    ).subscribe();
  }


  // 🔹 Function to send a new message
  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    try {
      await supabase.from('messages').insert({
        'conversation_id': widget.conversationId,
        'sender_id': userId,
        'content': _messageController.text.trim(),
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });

      _messageController.clear();

      // 🔹 Scroll to the latest message
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.receiverEmail)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: messageStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!;

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final bool isMe = msg['sender_id'] == userId;

                    return CustomChatBubble(
                      message: msg['content'],
                      isSentByMe: isMe,
                    );
                  },
                );
              },
            ),
          ),
          MessageBar(
            onSend: (text) async {
              if (text.trim().isEmpty) return;
              _messageController.text = text;
              await _sendMessage();
            },
            actions: [
              InkWell(
                child: const Icon(Icons.add, color: Colors.black, size: 24),
                onTap: () {},
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8, right: 8),
                child: InkWell(
                  child: const Icon(Icons.camera_alt, color: Colors.green, size: 24),
                  onTap: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// 🔹 Chat Bubble Widget
class CustomChatBubble extends StatelessWidget {
  final String message;
  final bool isSentByMe;

  const CustomChatBubble({
    super.key,
    required this.message,
    required this.isSentByMe,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
      child: BubbleSpecialThree(
        text: message,
        color: isSentByMe ? Colors.blue : Colors.grey[300]!,
        tail: true,
        textStyle: TextStyle(
          color: isSentByMe ? Colors.white : Colors.black,
          fontSize: 16,
        ),
        isSender: isSentByMe,
      ),
    );
  }
}