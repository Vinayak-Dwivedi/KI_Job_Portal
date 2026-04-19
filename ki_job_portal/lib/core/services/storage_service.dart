import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StorageService {
  static Future<String> uploadProfilePhoto(String uid, File imageFile) async {
    final ref = FirebaseStorage.instance.ref('users/$uid/profile.jpg');
    final uploadTask = ref.putFile(
      imageFile,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  static Future<void> updateProfilePhoto(String uid, String role, String url) async {
    final batch = FirebaseFirestore.instance.batch();
    batch.update(FirebaseFirestore.instance.collection('users').doc(uid),
        {'profilePhotoUrl': url});
    batch.update(
        FirebaseFirestore.instance.collection('${role}s').doc(uid),
        {'profilePhotoUrl': url});
    await batch.commit();
  }

  static Future<String> uploadPostImage(String uid, String postId, int index, File imageFile) async {
    final ref = FirebaseStorage.instance.ref('posts/$postId/image_$index.jpg');
    final task = ref.putFile(
      imageFile,
      SettableMetadata(contentType: 'image/jpeg')
    );
    final snapshot = await task;
    return await snapshot.ref.getDownloadURL();
  }
}
