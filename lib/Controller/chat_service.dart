import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String _generateChatId(String userA, String userB) {
    final sorted = [userA, userB]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  Future<String> createOrGetChat(String receiverId) async {
    final currentUserId = _auth.currentUser!.uid;

    if (receiverId.isEmpty || receiverId == currentUserId) {
      print("❌ Invalid receiver ID: $receiverId");
      return "";
    }

    final chatId = _generateChatId(currentUserId, receiverId);
    final chatRef = _firestore.collection('chats').doc(chatId);

    final doc = await chatRef.get();
    if (!doc.exists) {
      await chatRef.set({
        'participants': [currentUserId, receiverId],
        'lastMessage': '',
        'lastTimestamp': FieldValue.serverTimestamp(),
      });
    }

    return chatId;
  }

  Stream<List<Map<String, dynamic>>> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<void> sendMessage(String chatId, String text) async {
    final currentUserId = _auth.currentUser!.uid;
    final message = {
      'senderId': currentUserId,
      'text': text,
      'type': 'text',
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    };

    await _firestore.collection('chats').doc(chatId).collection('messages').add(message);

    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': text,
      'lastTimestamp': FieldValue.serverTimestamp(),
      'senderId': currentUserId,
      'isRead': false,
    });
  }

  Future<void> sendImage(String chatId, String imageUrl) async {
    final currentUserId = _auth.currentUser!.uid;

    await _firestore.collection('chats').doc(chatId).collection('messages').add({
      'senderId': currentUserId,
      'imageUrl': imageUrl,
      'type': 'image',
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': '[Image]',
      'lastTimestamp': FieldValue.serverTimestamp(),
      'senderId': currentUserId,
      'isRead': false,
    });
  }

  Stream<List<Map<String, dynamic>>> watchRecentChats() {
    final currentUserId = _auth.currentUser!.uid;

    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .orderBy('lastTimestamp', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final List<Map<String, dynamic>> chatData = [];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        data['chatId'] = doc.id;

        final lastMsgQuery = await _firestore
            .collection('chats')
            .doc(doc.id)
            .collection('messages')
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();

        if (lastMsgQuery.docs.isNotEmpty) {
          final lastMsg = lastMsgQuery.docs.first.data();
          data['senderId'] = lastMsg['senderId'];
          data['isRead'] = lastMsg['isRead'];
          data['lastMessage'] =
              lastMsg['type'] == 'image' ? '[Image]' : lastMsg['text'];
        }

        chatData.add(data);
      }

      return chatData;
    });
  }

  Future<List<Map<String, dynamic>>> getRecentChats() async {
    final currentUserId = _auth.currentUser!.uid;
    print("🔍 Fetching recent chats for $currentUserId");

    try {
      final query = await _firestore
          .collection('chats')
          .where('participants', arrayContains: currentUserId)
          .orderBy('lastTimestamp', descending: true)
          .get();

      print("✅ Found ${query.docs.length} chats");

      final List<Map<String, dynamic>> chatData = [];

      for (final doc in query.docs) {
        final data = doc.data();
        data['chatId'] = doc.id;

        final lastMsgQuery = await _firestore
            .collection('chats')
            .doc(doc.id)
            .collection('messages')
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();

        if (lastMsgQuery.docs.isNotEmpty) {
          final lastMsg = lastMsgQuery.docs.first.data();
          data['senderId'] = lastMsg['senderId'];
          data['isRead'] = lastMsg['isRead'];
          data['lastMessage'] =
              lastMsg['type'] == 'image' ? '[Image]' : lastMsg['text'];
        }

        chatData.add(data);
      }

      return chatData;
    } catch (e) {
      print("❌ Error fetching chats: $e");
      return [];
    }
  }
}
