import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/storage_service.dart';

class ProfileImagePicker extends StatefulWidget {
  final String? currentImageUrl;
  final String role;
  final Function(String newUrl) onUploaded;
  
  const ProfileImagePicker({
    super.key, 
    required this.onUploaded, 
    this.currentImageUrl,
    required this.role,
  });

  @override
  State<ProfileImagePicker> createState() => _ProfileImagePickerState();
}

class _ProfileImagePickerState extends State<ProfileImagePicker> {
  String? _imageUrl;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _imageUrl = widget.currentImageUrl;
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile == null) return;

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: pickedFile.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
            toolbarTitle: 'Cropper',
            toolbarColor: const Color(0xFF1A56DB),
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true),
        IOSUiSettings(
          title: 'Cropper',
          aspectRatioLockEnabled: true,
        ),
      ],
    );

    if (croppedFile != null) {
      await _uploadImage(File(croppedFile.path));
    }
  }

  Future<void> _uploadImage(File imageFile) async {
    setState(() => _isUploading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final url = await StorageService.uploadProfilePhoto(uid, imageFile);
      await StorageService.updateProfilePhoto(uid, widget.role, url);
      setState(() {
        _imageUrl = url;
      });
      widget.onUploaded(url);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image: $e')),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _removePhoto() async {
    // Optionally delete from Storage, but overriding the URL is usually enough.
    // For now, we update Firestore to set it to null or empty.
    setState(() => _isUploading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await StorageService.updateProfilePhoto(uid, widget.role, '');
      setState(() {
        _imageUrl = null;
      });
      widget.onUploaded('');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove image: $e')),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _showBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Take Photo'),
            onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Choose from Gallery'),
            onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
          ),
          if (_imageUrl != null && _imageUrl!.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Remove Photo', style: TextStyle(color: Colors.red)),
              onTap: () { Navigator.pop(context); _removePhoto(); },
            ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showBottomSheet(context),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircleAvatar(
            radius: 52,
            backgroundImage: _imageUrl != null && _imageUrl!.isNotEmpty
                ? NetworkImage(_imageUrl!) as ImageProvider
                : const AssetImage('assets/images/default_avatar.png'),
            child: _isUploading
                ? Container(
                    decoration: const BoxDecoration(
                      color: Colors.black45, shape: BoxShape.circle),
                    child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : null,
          ),
          Positioned(
            bottom: 0, right: 0,
            child: Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFF1A56DB),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
            ),
          ),
        ],
      ),
    );
  }
}
