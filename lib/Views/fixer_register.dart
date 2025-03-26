import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import './AuthGate.dart';

class FixerRegisterScreen extends StatefulWidget {
  const FixerRegisterScreen({super.key});

  @override
  State<FixerRegisterScreen> createState() => _FixerRegisterScreenState();
}

class _FixerRegisterScreenState extends State<FixerRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _nameController = TextEditingController();
  final _birthYearController = TextEditingController();

  File? _govIdImage;
  File? _selfieImage;
  bool _isLoading = false;

  Future<void> _pickImage(bool isGovId) async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        if (isGovId) {
          _govIdImage = File(picked.path);
        } else {
          _selfieImage = File(picked.path);
        }
      });
    }
  }

  Future<String> _uploadImage(File file, String path) async {
    final ref = FirebaseStorage.instance.ref().child(path);
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<void> _registerFixer() async {
    if (!_formKey.currentState!.validate() || _govIdImage == null || _selfieImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields and upload both images")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Create user
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passController.text.trim(),
      );

      final uid = cred.user!.uid;

      // Upload images
      final govIdUrl = await _uploadImage(_govIdImage!, 'govIds/$uid.jpg');
      final selfieUrl = await _uploadImage(_selfieImage!, 'selfies/$uid.jpg');

      // Save user data in Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'role': 'fixer',
        'email': _emailController.text.trim(),
        'name': _nameController.text.trim(),
        'birthYear': int.parse(_birthYearController.text.trim()),
        'govIdUrl': govIdUrl,
        'selfieUrl': selfieUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthGate()));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Fixer Signup")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "Email"),
                validator: (v) => v == null || !v.contains('@') ? "Enter a valid email" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _passController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Password"),
                validator: (v) => v == null || v.length < 6 ? "Min 6 characters" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Full Name"),
                validator: (v) => v == null || v.isEmpty ? "Enter your name" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _birthYearController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Birth Year"),
                validator: (v) {
                  if (v == null || v.isEmpty) return "Enter birth year";
                  final year = int.tryParse(v);
                  return (year == null || year < 1900 || year > DateTime.now().year)
                      ? "Enter a valid year"
                      : null;
                },
              ),
              const SizedBox(height: 20),

              // Government ID
              Row(
                children: [
                  const Text("Government ID: "),
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(true),
                    icon: const Icon(Icons.upload),
                    label: Text(_govIdImage != null ? "Selected" : "Upload"),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Selfie
              Row(
                children: [
                  const Text("Selfie: "),
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(false),
                    icon: const Icon(Icons.upload),
                    label: Text(_selfieImage != null ? "Selected" : "Upload"),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _registerFixer,
                child: const Text("Register"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
