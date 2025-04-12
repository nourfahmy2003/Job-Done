import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import './login.dart';
<<<<<<< HEAD
import './HomePage.dart';
=======
import './job_list_view.dart';
import './fixer_job_list_view.dart';
>>>>>>> b6204569c36ca6ddad69002b8753ca10b451a41f

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LoginScreen();

        final user = snapshot.data!;
<<<<<<< HEAD

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            if (!snap.data!.exists) {
              FirebaseFirestore.instance.collection('users').doc(user.uid).set({
                'name': user.displayName ?? 'Unnamed User',
                'email': user.email,
              });
            }

            return const HomePage();
=======
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
          builder: (context, snap) {
            if (!snap.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));

            final role = snap.data?.get('role') ?? 'problemer';
            return role == 'fixer' ? const FixerJobListView() : const JobListView();
>>>>>>> b6204569c36ca6ddad69002b8753ca10b451a41f
          },
        );
      },
    );
  }
}
