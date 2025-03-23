import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';


class StorageService {
  final FirebaseStorage storage = FirebaseStorage.instance;

  /// Uploads multiple images and returns a list of download URLs.
  Future<List<String>> uploadJobImages(List<File> imageFiles, String jobId) async {
    List<String> imageUrls = [];

    try {
      for (File imageFile in imageFiles) {
        final ref = storage
            .ref()
            .child('jobImages')
            .child('$jobId-${DateTime.now().millisecondsSinceEpoch}');

        await ref.putFile(imageFile);
        String downloadUrl = await ref.getDownloadURL();
        imageUrls.add(downloadUrl);
      }
    } catch (e) {
      print('Error uploading images: $e');
    }

    return imageUrls;
  }
}
