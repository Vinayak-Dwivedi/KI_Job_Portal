import 'package:cloud_firestore/cloud_firestore.dart';

class SubscriptionPlan {
  final String id;
  final String name;
  final int price;
  final int durationDays;
  final int credits;
  final int maxApplicationsPerDay;
  final List<String> features;
  final String color;
  final bool isPopular;
  final String description;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.durationDays,
    required this.credits,
    required this.maxApplicationsPerDay,
    required this.features,
    required this.color,
    required this.isPopular,
    this.description = '',
  });

  factory SubscriptionPlan.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SubscriptionPlan(
      id: doc.id,
      name: data['name'] ?? 'Unnamed Plan',
      price: data['price'] ?? 0,
      durationDays: data['durationDays'] ?? 30,
      credits: data['credits'] ?? 0,
      maxApplicationsPerDay: data['maxApplicationsPerDay'] ?? 0,
      features: List<String>.from(data['features'] ?? []),
      color: data['color'] ?? '#1D4ED8',
      isPopular: data['isPopular'] ?? false,
      description: data['description'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'durationDays': durationDays,
      'credits': credits,
      'maxApplicationsPerDay': maxApplicationsPerDay,
      'features': features,
      'color': color,
      'isPopular': isPopular,
      'description': description,
    };
  }
}
