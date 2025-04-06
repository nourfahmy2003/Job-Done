import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/job_entry_model.dart';
import './login.dart';
import './fixer_profile_view.dart';

class FixerJobListView extends StatefulWidget {
  const FixerJobListView({super.key});

  @override
  State<FixerJobListView> createState() => _FixerJobListViewState();
}

class _FixerJobListViewState extends State<FixerJobListView> {
  String? fixerField;
  String? fixerId;

  @override
  void initState() {
    super.initState();
    fetchFixerField();
  }

  Future<void> fetchFixerField() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    fixerId = user.uid;

    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    setState(() {
      fixerField = userDoc.data()?['field'];
    });
  }

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

              if (price == null || fixerId == null || message.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please fill in all fields.")),
                );
                return;
              }

              // Check if offer already exists
              final existing = await FirebaseFirestore.instance
                  .collection('offers')
                  .where('fixerId', isEqualTo: fixerId)
                  .where('jobId', isEqualTo: job.id)
                  .limit(1)
                  .get();

              if (existing.docs.isNotEmpty) {
                await existing.docs.first.reference.update({
                  'price': price,
                  'message': message,
                  'timestamp': FieldValue.serverTimestamp(),
                });
              } else {
                await FirebaseFirestore.instance.collection('offers').add({
                  'fixerId': fixerId,
                  'jobId': job.id,
                  'price': price,
                  'message': message,
                  'status': 'pending',
                  'timestamp': FieldValue.serverTimestamp(),
                });
              }

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
    if (fixerField == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final jobStream = FirebaseFirestore.instance
        .collectionGroup('job')
        .where('assignedFixerId', isNull: true)
        .where('field', isEqualTo: fixerField)
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
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("🎉 No jobs available in your field."));
          }

          final jobs =
              snapshot.data!.docs.map((doc) => Job.fromMap(doc)).toList();

          return ListView.builder(
            itemCount: jobs.length,
            itemBuilder: (context, index) {
              final job = jobs[index];

              return FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('offers')
                    .where('fixerId', isEqualTo: fixerId)
                    .where('jobId', isEqualTo: job.id)
                    .get(),
                builder: (context, offerSnapshot) {
                  bool offerExists = offerSnapshot.hasData &&
                      offerSnapshot.data!.docs.isNotEmpty;

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: ListTile(
                      title: Text(
                        job.desc,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        "From ${job.jobDateRange.start.toLocal().toString().split(' ')[0]} "
                        "to ${job.jobDateRange.end.toLocal().toString().split(' ')[0]}",
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("\$${job.price}"),
                          offerExists
                              ? const Text("Offer Sent", style: TextStyle(fontSize: 12))
                              : TextButton(
                                  onPressed: () => _showOfferDialog(context, job),
                                  child: const Text("Make Offer"),
                                ),
                        ],
                      ),
                    ),
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
