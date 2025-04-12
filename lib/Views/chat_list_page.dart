import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Controller/chat_service.dart';
import './chatpage.dart';
import 'package:timeago/timeago.dart' as timeago;

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final ChatService _chatService = ChatService();
  final currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Messages"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _chatService.watchRecentChats(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final chats = snapshot.data!;
          if (chats.isEmpty) return const Center(child: Text("No chats yet"));

          return ListView.separated(
            itemCount: chats.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final chat = chats[index];
              final otherId = (chat['participants'] as List).firstWhere((id) => id != currentUserId);
              final lastMessage = chat['lastMessage'] ?? '';
              final chatId = chat['chatId'];
              final senderId = chat['senderId'];
              final isUnread = chat['isRead'] == false && senderId == otherId;
              final isMine = senderId == currentUserId;

              final timestamp = chat['lastTimestamp'] as Timestamp?;
              final timeString = timestamp != null
                  ? timeago.format(timestamp.toDate(), locale: 'en_short')
                  : '';

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(otherId).get(),
                builder: (context, userSnap) {
                  if (!userSnap.hasData) return const ListTile(title: Text("Loading..."));
                  if (!userSnap.data!.exists) {
                    return ListTile(
                      title: const Text("Unknown User"),
                      subtitle: Text(lastMessage),
                      leading: const CircleAvatar(child: Icon(Icons.person_off)),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatPage(
                              chatId: chatId,
                              receiverId: otherId,
                            ),
                          ),
                        );
                      },
                    );
                  }

                  final userData = userSnap.data!.data() as Map<String, dynamic>;
                  final displayMessage = isMine ? 'You: $lastMessage' : lastMessage;

                  return ListTile(
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            userData['name'] ?? 'Unnamed User',
                            style: TextStyle(
                              fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                        Text(
                          timeString,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Row(
                      children: [
                        if (isUnread)
                          Container(
                            margin: const EdgeInsets.only(right: 6),
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.red,
                            ),
                          ),
                        Expanded(
                          child: Text(
                            displayMessage,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey[300],
                      backgroundImage: userData['photoUrl'] != null
                          ? NetworkImage(userData['photoUrl'])
                          : null,
                      child: userData['photoUrl'] == null
                          ? const Icon(Icons.person_outline, color: Colors.black)
                          : null,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatPage(
                            chatId: chatId,
                            receiverId: otherId,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
