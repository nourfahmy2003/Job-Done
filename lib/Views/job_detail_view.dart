import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Model/job_entry_model.dart';
import '../Controller/chat_service.dart';
import './chatpage.dart';

class JobDetailView extends StatelessWidget {
  final Job job;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;

  const JobDetailView({
    super.key,
    required this.job,
    required this.isFavorite,
    required this.onFavoriteToggle,
  });

  void _showOfferDialog(BuildContext context) {
    final TextEditingController _priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Suggest a Price'),
        content: TextField(
          controller: _priceController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Your offer (\$)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final price = double.tryParse(_priceController.text.trim());
              final user = FirebaseAuth.instance.currentUser;
              if (price == null || user == null) return;

              final offerData = {
                'price': price,
                'offeredBy': user.uid,
                'timestamp': FieldValue.serverTimestamp(),
                'status': 'pending',
              };

              final docRef = FirebaseFirestore.instance
                  .collection('users')
                  .doc(job.ownerId)
                  .collection('job')
                  .doc(job.id)
                  .collection('offers');

              await docRef.add(offerData);
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Offer sent!')),
              );
            },
            child: const Text('Send Offer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final String displayImage = job.imageUrls.isNotEmpty
        ? job.imageUrls.first
        : 'https://via.placeholder.com/400x250.png?text=No+Image';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
                child: Image.network(
                  displayImage,
                  height: 300,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 40,
                left: 16,
                child: CircleAvatar(
                  backgroundColor: Colors.black.withOpacity(0.5),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              Positioned(
                top: 40,
                right: 16,
                child: CircleAvatar(
                  backgroundColor: Colors.black.withOpacity(0.5),
                  child: IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : Colors.white,
                    ),
                    onPressed: onFavoriteToggle,
                  ),
                ),
              ),
              if (job.imageUrls.length > 1)
                Positioned(
                  bottom: 10,
                  left: 0,
                  right: 0,
                  child: SizedBox(
                    height: 60,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: job.imageUrls.map((url) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(url, height: 60, width: 60, fit: BoxFit.cover),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
            ],
          ),

          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(job.title,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.place, color: Colors.grey, size: 18),
                      const SizedBox(width: 6),
                      Text("Lat: ${job.latitude.toStringAsFixed(4)}  •  "
                          "Lng: ${job.longitude.toStringAsFixed(4)}",
                          style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.category, color: Colors.grey, size: 18),
                      const SizedBox(width: 6),
                      Text(job.category, style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text("Description", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    job.desc.isNotEmpty ? job.desc : "(No details provided)",
                    style: const TextStyle(fontSize: 14, height: 1.4),
                  ),
                  const Spacer(),
                  Text("\$${job.price}",
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showOfferDialog(context),
                    icon: const Icon(Icons.local_offer),
                    label: const Text('Make Offer'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final currentUserId = FirebaseAuth.instance.currentUser!.uid;

                      if (job.ownerId.isEmpty || job.ownerId == currentUserId) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Cannot message this user.")),
                        );
                        return;
                      }

                      final chatService = ChatService();
                      final chatId = await chatService.createOrGetChat(job.ownerId);

                      if (chatId.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Failed to start chat.")),
                        );
                        return;
                      }

                      if (!context.mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatPage(
                            chatId: chatId,
                            receiverId: job.ownerId,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('Message'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
