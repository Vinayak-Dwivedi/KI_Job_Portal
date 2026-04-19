import 'dart:io';

class WorkerProfileModel {
  String name;
  String phone;
  String primarySkill;
  String experience;
  File? profileImage;
  List<String> subSkills;
  
  WorkerProfileModel({
    required this.name,
    required this.phone,
    required this.primarySkill,
    required this.experience,
    this.profileImage,
    this.subSkills = const [],
  });
}
