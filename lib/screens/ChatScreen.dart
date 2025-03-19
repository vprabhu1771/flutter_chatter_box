import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chat_bubbles/chat_bubbles.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

final supabase = Supabase.instance.client;

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String userId;

  const ChatScreen({Key? key, required this.chatId, required this.userId}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _listenForNewMessages();
  }

  void _listenForNewMessages() {
    supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', widget.chatId)
        .order('sent_at')
        .listen((messages) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final messageId = const Uuid().v4();  // Generate unique message ID
    await supabase.from('messages').insert({
      'id': messageId,
      'chat_id': widget.chatId,
      'sender_id': widget.userId,
      'message': _messageController.text.trim(),
      'message_type': 'text',
      'sent_at': DateTime.now().toIso8601String(),
      'is_read': false,
    });

    _messageController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder(
              future: supabase
                  .from('messages')
                  .select()
                  .eq('chat_id', widget.chatId)
                  .order('sent_at'),
              builder: (context, AsyncSnapshot<dynamic> snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data as List<dynamic>;

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isSender = message['sender_id'] == widget.userId;
                    final sentTime = DateFormat('hh:mm a').format(DateTime.parse(message['sent_at']));

                    return BubbleSpecialOne(
                      text: message['message'],
                      isSender: isSender,
                      color: isSender ? Colors.blue : Colors.grey[300]!,
                      tail: true,
                      textStyle: TextStyle(
                        color: isSender ? Colors.white : Colors.black,
                        fontSize: 16,
                      ),
                      delivered: message['is_read'],
                      seen: message['is_read'],
                    );
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: "Type a message...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.blue),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}
