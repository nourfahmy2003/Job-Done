import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  Future<List<String>> uploadJobImages(List<XFile> images, String jobId) async {
    final List<String> downloadUrls = [];
    final storage = FirebaseStorage.instance;

    for (final image in images) {
      try {
        final String fileName =
            'jobs/$jobId/${DateTime.now().millisecondsSinceEpoch}';
        final Reference ref = storage.ref().child(fileName);

        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
        } else {
          final path = image.path;
          if (path.toLowerCase().endsWith('.heic')) {
            throw Exception('HEIC format not supported');
          }
          await ref.putFile(File(path));
        }

        final String downloadUrl = await ref.getDownloadURL();
        downloadUrls.add(downloadUrl);
      } catch (e) {
        print('Error uploading image: $e');
      }
    }

    return downloadUrls;
  }
}
