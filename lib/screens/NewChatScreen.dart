import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './ChatDetailScreen.dart';

class NewChatScreen extends StatefulWidget {
  final String title;

  const NewChatScreen({super.key, required this.title});

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  final supabase = Supabase.instance.client;

  // Stream to get real-time updates
  Stream<List<Map<String, dynamic>>> getUsersStream() {
    return supabase
        .from('users')
        .stream(primaryKey: ['id']) // Ensures real-time updates
        .map((data) {
      // print("Real-time data update: $data"); // Debugging print statement
      return data;
    });
  }

  void _startChat(String receiverId, String receiverEmail) async {
    final currentUser = supabase.auth.currentUser?.id;
    if (currentUser == null) return;

    // Check if conversation exists
    final existingConversation = await supabase
        .from('participants')
        .select('conversation_id')
        .eq('user_id', currentUser)
        .or('user_id.eq.$receiverId')
        .maybeSingle();

    String conversationId;

    if (existingConversation != null) {
      conversationId = existingConversation['conversation_id'];
    } else {
      // Create new conversation
      final conversation = await supabase.from('conversations').insert({
        'is_group': false,
        // 'name': receiverEmail
      }).select().single();

      conversationId = conversation['id'];

      // Add participants
      await supabase.from('participants').insert([
        {'conversation_id': conversationId, 'user_id': currentUser},
        {'conversation_id': conversationId, 'user_id': receiverId},
      ]);
    }

    // Navigate to chat detail screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailScreen(
          conversationId: conversationId,
          receiverEmail: receiverEmail,
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: getUsersStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          final users = snapshot.data!;
          final currentUser = supabase.auth.currentUser?.id;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];

              // Prevent showing the current user in the list
              if (user['id'] == currentUser) return SizedBox.shrink();

              // Extract user metadata safely
              // final userMetadata = user['user_metadata'] as Map<String, dynamic>? ?? {};

              // print(user.toString());

              final avatarUrl = user['image_path'] as String? ??
                  'https://www.gravatar.com/avatar/${user['email'].hashCode}?d=identicon';

              return ListTile(
                title: Text(user['email']),
                subtitle: Text(user['phone'] ?? 'No phone number'),
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(avatarUrl),
                ),
                onTap: () {

                  print(user['id']);
                  print(user['email']);
                  print(user['phone']);

                  // Navigate to ChatDetailScreen with the selected user
                  _startChat(user['id'], user['email']);


                },
              );
            },
          );
        },
      ),
    );
  }
}