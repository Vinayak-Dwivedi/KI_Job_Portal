import 'package:cloud_firestore/cloud_firestore.dart';

class DocumentModel {
  final String id;
  final String name;
  final String url;
  final String type; // e.g., 'pdf', 'image', 'other'
  final DateTime timestamp;
  final String? userId; // Metadata
  final String? phone;  // Metadata

  DocumentModel({
    required this.id,
    required this.name,
    required this.url,
    required this.type,
    required this.timestamp,
    this.userId,
    this.phone,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'type': type,
      'timestamp': Timestamp.fromDate(timestamp),
      'userId': userId,
      'phone': phone,
    };
  }

  factory DocumentModel.fromMap(Map<String, dynamic> map) {
    return DocumentModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      url: map['url'] ?? '',
      type: map['type'] ?? 'other',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      userId: map['userId'],
      phone: map['phone'],
    );
  }
}
