import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service to compress and upload images to Firebase Storage.
class ImageStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Compresses an image file down to [quality] (0-100) and
  /// a maximum dimension of [maxDimension] pixels.
  /// Returns the compressed file, or null on failure.
  Future<File?> compressImage(
    File file, {
    int quality = 70,
    int maxDimension = 1024,
  }) async {
    final filePath = file.absolute.path;
    // Generate output path with _compressed suffix
    final lastDot = filePath.lastIndexOf('.');
    final outPath = lastDot != -1
        ? '${filePath.substring(0, lastDot)}_compressed${filePath.substring(lastDot)}'
        : '${filePath}_compressed.jpg';

    final result = await FlutterImageCompress.compressAndGetFile(
      filePath,
      outPath,
      quality: quality,
      minWidth: maxDimension,
      minHeight: maxDimension,
    );

    if (result == null) return null;
    return File(result.path);
  }

  /// Uploads [imageFile] to Firebase Storage under
  /// `reports/{userId}/{timestamp}_{fileName}`.
  /// Compresses the image first, then uploads.
  /// Returns the public download URL on success.
  Future<String> uploadReportImage(File imageFile) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('User not authenticated');

    // Compress before uploading
    final compressed = await compressImage(imageFile);
    final fileToUpload = compressed ?? imageFile;

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = imageFile.path.split(Platform.pathSeparator).last;
    final ref = _storage.ref('reports/$uid/${timestamp}_$fileName');

    final uploadTask = ref.putFile(
      fileToUpload,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    final snapshot = await uploadTask;
    final downloadUrl = await snapshot.ref.getDownloadURL();

    // Clean up temporary compressed file
    if (compressed != null && await compressed.exists()) {
      await compressed.delete();
    }

    return downloadUrl;
  }
}
