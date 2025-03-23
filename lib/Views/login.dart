import 'package:flutter/material.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart' as auth_ui;
import 'register.dart';
import './AuthGate.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return auth_ui.SignInScreen(
      providers: [auth_ui.EmailAuthProvider()],
      showAuthActionSwitch: false, 
      actions: [
        auth_ui.ForgotPasswordAction((context, email) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const auth_ui.ForgotPasswordScreen()));
        }),
        auth_ui.AuthStateChangeAction((context, state) {
          if (state is auth_ui.SignedIn || state is auth_ui.UserCreated) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthGate()));
          }
        }),
      ],
      footerBuilder: (context, _) {
        return TextButton(
          child: const Text("Don't have an account? Register here"),
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomRegisterScreen()));
          },
        );
      },
    );
  }
}
