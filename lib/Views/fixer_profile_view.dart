import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import './fixer_map_view.dart';

class FixerProfileView extends StatefulWidget {
  const FixerProfileView({super.key});

  @override
  State<FixerProfileView> createState() => _FixerProfileViewState();
}

class _FixerProfileViewState extends State<FixerProfileView> {
  String name = '';
  String email = '';
  int totalEarnings = 0;
  Map<String, int> categoryTotals = {};
  String selfieUrl = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadProfileData();
  }

  Future<void> loadProfileData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      name = userDoc['name'] ?? '';
      email = user.email ?? '';
      selfieUrl = userDoc['selfieUrl'] ?? '';

      final offersSnapshot = await FirebaseFirestore.instance
          .collection('offers')
          .where('fixerId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'accepted')
          .get();

      totalEarnings = 0;
      categoryTotals = {};

      for (var offerDoc in offersSnapshot.docs) {
        final jobId = offerDoc['jobId'];
        final jobSnapshot = await FirebaseFirestore.instance
            .collectionGroup('job')
            .where(FieldPath.documentId, isEqualTo: jobId)
            .get();

        if (jobSnapshot.docs.isNotEmpty) {
          final jobData = jobSnapshot.docs.first.data();
          final int price = jobData['price'] ?? 0;
          final String category = jobData['category'] ?? 'Other';

          totalEarnings += price;
          categoryTotals[category] = (categoryTotals[category] ?? 0) + price;
        }
      }

      setState(() => isLoading = false);
    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to load data")));
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Fixer Profile"),
        
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (selfieUrl.isNotEmpty)
              CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(selfieUrl),
              ),
            const SizedBox(height: 16),
            Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(email),
            const Divider(height: 32),
            Text("Total Earnings: \$${totalEarnings}", style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            const Text("Earnings by Category:", style: TextStyle(fontWeight: FontWeight.bold)),
            ...categoryTotals.entries.map((e) => ListTile(
              title: Text(e.key),
              trailing: Text("\$${e.value}"),
            )),
          ],
        ),
      ),
    );
  }
}
