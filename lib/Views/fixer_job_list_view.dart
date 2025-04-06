import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/job_entry_model.dart';
import './login.dart';
import './fixer_profile_view.dart';

class FixerJobListView extends StatelessWidget {
  const FixerJobListView({super.key});

  void _showOfferDialog(BuildContext context, Job job) {
    final priceController = TextEditingController();
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Make an Offer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Your Price"),
            ),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(labelText: "Message"),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            child: const Text("Submit"),
            onPressed: () async {
              final price = double.tryParse(priceController.text.trim());
              final message = messageController.text.trim();
              final fixerId = FirebaseAuth.instance.currentUser?.uid;

              if (price == null || fixerId == null || message.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please fill in all fields.")),
                );
                return;
              }

              await FirebaseFirestore.instance.collection('offers').add({
                'fixerId': fixerId,
                'jobId': job.id,
                'price': price,
                'message': message,
                'status': 'pending',
                'timestamp': FieldValue.serverTimestamp(),
              });

              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Offer submitted!")),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final jobStream = FirebaseFirestore.instance
        .collectionGroup('job')
        .where('assignedFixerId', isNull: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Available Jobs for Fixers"),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FixerProfileView()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: jobStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
                child: Text("🎉 No unassigned jobs available."));
          }

          try {
            final jobs =
                snapshot.data!.docs.map((doc) => Job.fromMap(doc)).toList();

            return ListView.builder(
              itemCount: jobs.length,
              itemBuilder: (context, index) {
                final job = jobs[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: ListTile(
                    title: Text(job.desc),
                    subtitle: Text(
                      "From ${job.jobDateRange.start.toLocal().toString().split(' ')[0]} "
                      "to ${job.jobDateRange.end.toLocal().toString().split(' ')[0]}",
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("\$${job.price}"),
                        TextButton(
                          onPressed: () => _showOfferDialog(context, job),
                          child: const Text("Make Offer"),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          } catch (e) {
            return Center(child: Text("⚠️ Error loading job list: $e"));
          }
        },
      ),
    );
  }
}
