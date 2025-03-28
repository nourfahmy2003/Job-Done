import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/job_entry_model.dart';
import './login.dart';
import './fixer_profile_view.dart';

class FixerJobListView extends StatelessWidget {
  const FixerJobListView({super.key});

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
          // Profile button
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FixerProfileView()),
              );
            },
          ),
          // Logout button
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
                    trailing: Text("\$${job.price}"),
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
