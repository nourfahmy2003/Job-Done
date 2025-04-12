import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../Controller/chat_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ChatPage extends StatefulWidget {
  final String receiverId;
  final String chatId;

  const ChatPage({
    super.key,
    required this.receiverId,
    required this.chatId,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _controller = TextEditingController();
  final ChatService _chatService = ChatService();
  final user = FirebaseAuth.instance.currentUser;
  final ImagePicker _picker = ImagePicker();

  String? receiverName;
  String? receiverPhotoUrl;
  String? userPhotoUrl;

  @override
  void initState() {
    super.initState();
    _loadProfileInfo();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileInfo() async {
    final receiverSnap = await FirebaseFirestore.instance.collection('users').doc(widget.receiverId).get();
    final currentSnap = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();

    setState(() {
      receiverName = receiverSnap.data()?['name'];
      receiverPhotoUrl = receiverSnap.data()?['photoUrl'];
      userPhotoUrl = currentSnap.data()?['photoUrl'];
    });
  }

  Future<void> _pickAndSendImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    File imageFile = File(image.path);
    String fileName = 'chat_images/${widget.chatId}/${DateTime.now().millisecondsSinceEpoch}.jpg';
    
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final ref = FirebaseStorage.instance.ref().child(fileName);
      await ref.putFile(imageFile);
      final imageUrl = await ref.getDownloadURL();

      await _chatService.sendImage(widget.chatId, imageUrl);

      if (mounted) Navigator.of(context).pop();

      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send image: $e')),
        );
      }
    }
  }

  Widget _buildMessageContent(Map<String, dynamic> msg) {
    if (msg['type'] == 'image') {
      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Scaffold(
                backgroundColor: Colors.black,
                appBar: AppBar(
                  backgroundColor: Colors.black,
                  iconTheme: const IconThemeData(color: Colors.white),
                ),
                body: Center(
                  child: InteractiveViewer(
                    child: CachedNetworkImage(
                      imageUrl: msg['imageUrl'],
                      placeholder: (context, url) => const CircularProgressIndicator(),
                      errorWidget: (context, url, error) => const Icon(Icons.error),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: msg['imageUrl'],
            width: 200,
            height: 200,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              width: 200,
              height: 200,
              color: Colors.grey[300],
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (context, url, error) => Container(
              width: 200,
              height: 200,
              color: Colors.grey[300],
              child: const Icon(Icons.error),
            ),
          ),
        ),
      );
    } else {
      return Text(
        msg['text'],
        style: TextStyle(color: msg['senderId'] == user?.uid ? Colors.white : Colors.black),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(receiverName ?? 'Chat'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<QueryDocumentSnapshot>>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: false) 
                  .snapshots()
                  .map((snapshot) {
                bool hasUnread = false;

                for (var doc in snapshot.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  if (data['senderId'] != user?.uid && data['isRead'] == false) {
                    hasUnread = true;
                    doc.reference.update({'isRead': true});
                  }
                }

                if (hasUnread) {
                  FirebaseFirestore.instance.collection('chats').doc(widget.chatId).update({
                    'isRead': true,
                  });
                }

                return snapshot.docs;
              }),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final messages = snapshot.data!;
                
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index].data() as Map<String, dynamic>;
                    final isMine = msg['senderId'] == user?.uid;

                    final profilePic = isMine ? userPhotoUrl : receiverPhotoUrl;
                    final alignment = isMine ? Alignment.centerRight : Alignment.centerLeft;
                    final bubbleColor = isMine ? Colors.black : Colors.grey[300];
                    final avatarMargin = isMine
                        ? const EdgeInsets.only(left: 8)
                        : const EdgeInsets.only(right: 8);

                    final timestamp = msg['timestamp'] != null
                        ? (msg['timestamp'] as Timestamp).toDate()
                        : null;

                    final timeStr = timestamp != null
                        ? DateFormat('h:mm a').format(timestamp)
                        : '';

                    final isRead = msg['isRead'] == true;

                    return Align(
                      alignment: alignment,
                      child: Column(
                        crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment:
                                isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
                            children: [
                              if (!isMine)
                                Container(
                                  margin: avatarMargin,
                                  child: CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Colors.grey[300],
                                    backgroundImage:
                                        profilePic != null ? NetworkImage(profilePic) : null,
                                    child: profilePic == null
                                        ? const Icon(Icons.person_outline, size: 16, color: Colors.black)
                                        : null,
                                  ),
                                ),
                              Flexible(
                                child: Container(
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: bubbleColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: _buildMessageContent(msg),
                                ),
                              ),
                              if (isMine)
                                Container(
                                  margin: avatarMargin,
                                  child: CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Colors.grey[300],
                                    backgroundImage:
                                        profilePic != null ? NetworkImage(profilePic) : null,
                                    child: profilePic == null
                                        ? const Icon(Icons.person_outline, size: 16, color: Colors.black)
                                        : null,
                                  ),
                                ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment:
                                isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
                            children: [
                              Text(
                                timeStr,
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              if (isMine)
                                Padding(
                                  padding: const EdgeInsets.only(left: 4),
                                  child: Text(
                                    isRead ? '✓✓' : '✓',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isRead ? Colors.blue : Colors.grey,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  tooltip: 'Attach image',
                  onPressed: _pickAndSendImage,
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    final text = _controller.text.trim();
                    if (text.isNotEmpty) {
                      await _chatService.sendMessage(widget.chatId, text);
                      _controller.clear();
                      
                      if (_scrollController.hasClients) {
                        _scrollController.animateTo(
                          _scrollController.position.maxScrollExtent,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      }
                    }
                  },
                  child: const Icon(Icons.send),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}