import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class EditJobPage extends StatefulWidget {
  final DocumentSnapshot jobDoc;

  const EditJobPage({super.key, required this.jobDoc});

  @override
  State<EditJobPage> createState() => _EditJobPageState();
}

class _EditJobPageState extends State<EditJobPage> {
  late TextEditingController _descController;
  late TextEditingController _priceController;
  String? selectedCategory;
  List<String> imageUrls = [];

  final categories = ['Plumbing', 'Electrical', 'Cleaning', 'Painting', 'Gardening', 'Other'];

  @override
  void initState() {
    super.initState();
    final job = widget.jobDoc.data() as Map<String, dynamic>;

    final price = job['price'];
    final displayPrice = price != null
        ? (price is int ? price : (price as num).toInt()).toString()
        : '--';
    final priceText = (price is num) ? price.toString() : '';

    _descController = TextEditingController(text: job['desc'] ?? '');
    _priceController = TextEditingController(text: priceText);
    selectedCategory = job['category'];
    imageUrls = List<String>.from(job['imageUrls'] ?? []);
  }

  Future<void> _pickAndReplaceImage(int index) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final file = File(picked.path);
    final fileName = 'job_images/${widget.jobDoc.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = FirebaseStorage.instance.ref().child(fileName);
    await ref.putFile(file);
    final url = await ref.getDownloadURL();

    setState(() {
      if (index < imageUrls.length) {
        imageUrls[index] = url;
      } else {
        imageUrls.add(url);
      }
    });
  }

  Future<void> _saveChanges() async {
    await widget.jobDoc.reference.update({
      'desc': _descController.text,
      'category': selectedCategory,
      'price': double.tryParse(_priceController.text),
      'imageUrls': imageUrls,
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Job updated successfully')),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Job"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveChanges,
            tooltip: 'Save changes',
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            const Text("Description", style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(controller: _descController),

            const SizedBox(height: 16),
            const Text("Category", style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButtonFormField<String>(
              value: selectedCategory,
              items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (value) => setState(() => selectedCategory = value),
            ),

            const SizedBox(height: 16),
            const Text("Price", style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(prefixText: '\$'),
            ),

            const SizedBox(height: 20),
            const Text("Images", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              children: List.generate(
                imageUrls.length + 1,
                (index) {
                  if (index < imageUrls.length) {
                    return GestureDetector(
                      onTap: () => _pickAndReplaceImage(index),
                      child: Image.network(
                        imageUrls[index],
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    );
                  } else {
                    return GestureDetector(
                      onTap: () => _pickAndReplaceImage(index),
                      child: Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[200],
                        child: const Icon(Icons.add),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
