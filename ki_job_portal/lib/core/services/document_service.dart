import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../models/document_model.dart';

class DocumentService {
  static final _firestore = FirebaseFirestore.instance;
  static final _storage = FirebaseStorage.instance;

  static Future<DocumentModel> uploadDocument({
    required String uid,
    required String name,
    required String phone,
    String? category,
    required File file,
  }) async {
    final extension = file.path.split('.').last.toLowerCase();
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$extension';
    final storagePath = 'users/$uid/documents/$fileName';
    final ref = _storage.ref().child(storagePath);

    // 1. Upload to Storage
    final metadata = SettableMetadata(
      contentType: _getContentType(extension),
      customMetadata: {
        'userId': uid,
        'originalName': name,
        'phone': phone,
      },
    );
    
    await ref.putFile(file, metadata);
    final url = await ref.getDownloadURL();

    // 2. Create DocumentModel
    final docModel = DocumentModel(
      id: fileName,
      name: name,
      url: url,
      type: extension,
      category: category,
      timestamp: DateTime.now(),
      userId: uid,
      phone: phone,
    );

    // 3. Update Firestore (Add to list in user document)
    await _firestore.collection('users').doc(uid).update({
      'documents': FieldValue.arrayUnion([docModel.toMap()]),
    });

    return docModel;
  }

  static String _getContentType(String extension) {
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'application/octet-stream';
    }
  }

  static Future<void> deleteDocument(String uid, DocumentModel doc) async {
    // 1. Delete from Storage
    try {
      await _storage.ref().child('users/$uid/documents/${doc.id}').delete();
    } catch (e) {
      print('Error deleting from storage: $e');
    }

    // 2. Delete from Firestore
    await _firestore.collection('users').doc(uid).update({
      'documents': FieldValue.arrayRemove([doc.toMap()]),
    });
  }
}
