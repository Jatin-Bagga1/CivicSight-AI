import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service to upload images to Firebase Storage.
class ImageStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Uploads [imageFile] to Firebase Storage under
  /// `reports/{userId}/{timestamp}_{fileName}`.
  /// Returns the public download URL on success.
  Future<String> uploadReportImage(File imageFile) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('User not authenticated');

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = imageFile.path.split(Platform.pathSeparator).last;
    final ref = _storage.ref('report_images/$uid/${timestamp}_$fileName');

    final uploadTask = ref.putFile(
      imageFile,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  /// Deletes an image from Firebase Storage by its download URL.
  Future<void> deleteImage(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
    } catch (e) {
      debugPrint('Failed to delete image: $e');
    }
  }
}
