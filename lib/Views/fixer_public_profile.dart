import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class FixerPublicProfileView extends StatelessWidget {
  final String fixerId;

  const FixerPublicProfileView({super.key, required this.fixerId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(fixerId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;

        if (data == null) {
          return const Scaffold(
            body: Center(child: Text("Fixer not found")),
          );
        }

        final name = data['name'] ?? "Unknown Fixer";
        final selfieUrl = data['selfieUrl'] ?? '';
        final avgRating = data['avgRating']?.toDouble() ?? 0.0;

        return Scaffold(
          appBar: AppBar(title: const Text("Fixer Profile")),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (selfieUrl.isNotEmpty)
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(selfieUrl),
                  ),
                const SizedBox(height: 12),
                Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                avgRating > 0
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.star, color: Colors.amber),
                          const SizedBox(width: 6),
                          Text("${avgRating.toStringAsFixed(1)} / 5.0"),
                        ],
                      )
                    : const Text("No ratings yet"),
              ],
            ),
          ),
        );
      },
    );
  }
}
