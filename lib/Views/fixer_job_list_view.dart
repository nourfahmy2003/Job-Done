import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/job_entry_model.dart';
import './login.dart';
import './fixer_profile_view.dart';
import './fixer_map_view.dart';

class FixerJobListView extends StatefulWidget {
  const FixerJobListView({super.key});

  @override
  State<FixerJobListView> createState() => _FixerJobListViewState();
}

class _FixerJobListViewState extends State<FixerJobListView> {
  String? fixerId;

  @override
  void initState() {
    super.initState();
    fixerId = FirebaseAuth.instance.currentUser?.uid;
  }

  Future<void> _acceptJob(Job job) async {
    if (fixerId == null || job.id == null) return;

    // Submit offer to the job owner at listed price
    await FirebaseFirestore.instance.collection('offers').add({
      'fixerId': fixerId,
      'jobId': job.id,
      'proposedPrice': job.price,
      'proposedStart': Timestamp.fromDate(job.jobDateRange.start),
      'proposedEnd': Timestamp.fromDate(job.jobDateRange.end),
      'message': 'Accepting job at listed price.',
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text("Your offer at listed price has been sent.")),
    );
  }

  void _showOfferDialog(BuildContext context, Job job) {
    final priceController = TextEditingController();
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Make Your Offer'),
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
            child: const Text("Submit Offer"),
            onPressed: () async {
              final price = double.tryParse(priceController.text.trim());
              final message = messageController.text.trim();

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
                'proposedPrice': job.price,
                'proposedStart': Timestamp.fromDate(job.jobDateRange.start),
                'proposedEnd': Timestamp.fromDate(job.jobDateRange.end),
                'timestamp': FieldValue.serverTimestamp(),
              });

              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Your offer has been submitted.")),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (fixerId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(
                child: Text("🎉 No unassigned jobs available."));
          }

          final jobs = snapshot.data!.docs.map((doc) {
            final job = Job.fromMap(doc);
            return job.copyWith(id: doc.id);
          }).toList();

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
                  final alreadyApplied = offerSnapshot.hasData &&
                      offerSnapshot.data!.docs.isNotEmpty;

                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (job.imageUrls.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                job.imageUrls.first,
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                          const SizedBox(height: 10),
                          Text(
                            job.desc,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "From ${job.jobDateRange.start.toLocal().toString().split(' ')[0]} "
                            "to ${job.jobDateRange.end.toLocal().toString().split(' ')[0]}",
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "\$${job.price}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (alreadyApplied)
                            Container(
                              padding: const EdgeInsets.all(10),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Text(
                                  "✅ You already applied to this job",
                                  style: TextStyle(color: Colors.black87),
                                ),
                              ),
                            )
                          else
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _acceptJob(job),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text("Accept Job as Listed"),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () =>
                                        _showOfferDialog(context, job),
                                    style: OutlinedButton.styleFrom(
                                      side:
                                          const BorderSide(color: Colors.black),
                                      foregroundColor: Colors.black,
                                    ),
                                    child: const Text("Make Your Offer"),
                                  ),
                                ),
                              ],
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
      floatingActionButton: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FixerMapView()),
            );
          },
          backgroundColor: Colors.black,
          child: const Icon(Icons.map, color: Colors.white),
          tooltip: 'Open Map',
        ),
      ),
    );
  }
}
