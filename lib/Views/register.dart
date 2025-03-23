import 'package:flutter/material.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart' as auth_ui;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import './AuthGate.dart';

class CustomRegisterScreen extends StatefulWidget {
  const CustomRegisterScreen({super.key});

  @override
  State<CustomRegisterScreen> createState() => _CustomRegisterScreenState();
}

class _CustomRegisterScreenState extends State<CustomRegisterScreen> {
  String selectedRole = 'problemer';

  @override
  Widget build(BuildContext context) {
    return auth_ui.RegisterScreen(
      providers: [auth_ui.EmailAuthProvider()],
      actions: [
        auth_ui.AuthStateChangeAction<auth_ui.SignedIn>((context, state) async {
          final user = FirebaseAuth.instance.currentUser!;
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'role': selectedRole,
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthGate()));
        }),
      ],
      footerBuilder: (context, _) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: DropdownButtonFormField<String>(
            value: selectedRole,
            decoration: const InputDecoration(labelText: "I am a..."),
            items: const [
              DropdownMenuItem(value: 'problemer', child: Text('Problemer')),
              DropdownMenuItem(value: 'fixer', child: Text('Fixer')),
            ],
            onChanged: (value) => setState(() => selectedRole = value!),
          ),
        );
      },
    );
  }
}
