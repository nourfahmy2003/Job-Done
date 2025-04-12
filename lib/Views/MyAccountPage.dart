import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import './EditJobPage.dart';
import '../Controller/chat_service.dart'; 
import './chatpage.dart'; 


class MyAccountPage extends StatefulWidget {
  const MyAccountPage({super.key});

  @override
  State<MyAccountPage> createState() => _MyAccountPageState();
}

class _MyAccountPageState extends State<MyAccountPage> {
  final user = FirebaseAuth.instance.currentUser!;
  String? photoUrl;
  String? name;
  String? email;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = doc.data();
    if (data != null) {
      setState(() {
        photoUrl = data['photoUrl'];
        name = data['name'];
        email = data['email'];
      });
    }
  }

  Future<void> _uploadProfilePicture() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    final file = File(pickedFile.path);
    final ref = FirebaseStorage.instance.ref().child('profile_pics/${user.uid}.jpg');

    await ref.putFile(file);
    final downloadUrl = await ref.getDownloadURL();

    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'photoUrl': downloadUrl,
    });

    setState(() => photoUrl = downloadUrl);
  }

  void _openEditJobPage(DocumentSnapshot doc) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditJobPage(jobDoc: doc),
      ),
    );
  }

  Future<void> _acceptOffer(DocumentReference jobRef, String offerId, num offeredPrice) async {
    await jobRef.update({'price': offeredPrice});
    await jobRef.collection('offers').doc(offerId).update({'status': 'accepted'});
  }

  Future<void> _rejectOffer(DocumentReference jobRef, String offerId) async {
    await jobRef.collection('offers').doc(offerId).update({'status': 'rejected'});
  }

  Widget _buildOffers(DocumentReference jobRef) {
  return StreamBuilder<QuerySnapshot>(
    stream: jobRef.collection('offers').orderBy('timestamp', descending: true).snapshots(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) return const SizedBox.shrink();

      final offers = snapshot.data!.docs;
      if (offers.isEmpty) return const Text("No offers yet.");

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const Text("Offers:", style: TextStyle(fontWeight: FontWeight.bold)),
          ...offers.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final price = data['price'];
            final status = data['status'];
            final offeredBy = data['offeredBy'];

            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text("Offer: \$${price.toString()}"),
              subtitle: Text("Status: $status"),
              trailing: Wrap(
                spacing: 4,
                children: [
                  if (status == 'pending') ...[
                    TextButton(
                      onPressed: () => _acceptOffer(jobRef, doc.id, price),
                      child: const Text("Accept"),
                    ),
                    TextButton(
                      onPressed: () => _rejectOffer(jobRef, doc.id),
                      child: const Text("Reject"),
                    ),
                  ],
                  IconButton(
                    icon: const Icon(Icons.chat),
                    tooltip: "Message",
                    onPressed: () async {
                      final chatService = ChatService();
                      final chatId = await chatService.createOrGetChat(offeredBy);

                      if (!mounted) return;
                      Navigator.pushNamed(
                        context,
                        '/chat',
                        arguments: {'chatId': chatId, 'receiverId': offeredBy},
                      );
                    },
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      );
    },
  );
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Account"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _uploadProfilePicture,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
                        child: photoUrl == null
                            ? const Icon(Icons.camera_alt, size: 40, color: Colors.black)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(name ?? 'Name not set',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text(email ?? 'Email not available', style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              const Text("Your Postings", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .collection('job')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                  final jobs = snapshot.data!.docs;

                  if (jobs.isEmpty) {
                    return const Text("You haven't posted any jobs yet.");
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: jobs.length,
                    itemBuilder: (context, index) {
                      final doc = jobs[index];
                      final job = doc.data() as Map<String, dynamic>;
                      final images = job['imageUrls'] as List<dynamic>?;
                      final price = job['price'];
                      final displayPrice = price != null
                          ? (price is int ? price : (price as num).toInt()).toString()
                          : '--';

                      return GestureDetector(
                        onTap: () => _openEditJobPage(doc),
                        child: Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: images != null && images.isNotEmpty
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(6),
                                          child: Image.network(
                                            images[0],
                                            width: 60,
                                            height: 60,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : const Icon(Icons.image_not_supported),
                                  title: Text(job['desc'] ?? 'No description'),
                                  subtitle: Text(job['category'] ?? 'No category'),
                                  trailing: Text(
                                    '\$$displayPrice',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                _buildOffers(doc.reference),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
