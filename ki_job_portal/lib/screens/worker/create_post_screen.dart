import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/theme/app_colors.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  File? _selectedImage;
  final TextEditingController _contentController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    // Request permission (mocked behaviour or real depending on platform)
    final status = await Permission.storage.request();
    if (status.isGranted || await Permission.photos.request().isGranted) {
      try {
        final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
        if (image != null) {
          setState(() {
            _selectedImage = File(image.path);
          });
        }
      } catch (e) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Failed to pick image: $e')),
           );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Storage permission is required.')),
        );
      }
    }
  }

  void _submitPost() {
    if (_contentController.text.trim().isEmpty && _selectedImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add an image or text to post.')),
        );
        return;
    }

    // Mocking the post submission process
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Successfully submitted the post. It will go live once the admin approves it.'),
        backgroundColor: AppColors.secondary,
        duration: Duration(seconds: 4),
      ),
    );

    // Return to the previous screen
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _submitPost,
            child: const Text('Post', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppColors.surfaceContainerHigh,
                  child: Icon(Icons.person, color: AppColors.outline),
                ),
                const SizedBox(width: 12),
                Text(
                  'Rahul Sharma',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            TextField(
              controller: _contentController,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              decoration: const InputDecoration(
                hintText: 'What do you want to share?',
                border: InputBorder.none,
              ),
            ),
            
            const SizedBox(height: 16),
            
            if (_selectedImage != null)
               Stack(
                 alignment: Alignment.topRight,
                 children: [
                   ClipRRect(
                     borderRadius: BorderRadius.circular(12),
                     // Note: On Flutter Web, FileImage might fail inside standard run unless it is compiled properly with dart:html. 
                     // Kept as simple file render for Android native compilation.
                     child: Image.file(_selectedImage!, fit: BoxFit.cover),
                   ),
                   IconButton(
                     icon: const Icon(Icons.cancel, color: Colors.white, size: 30),
                     onPressed: () => setState(() => _selectedImage = null),
                   ),
                 ],
               ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            border: Border(
              top: BorderSide(color: AppColors.outlineVariant.withOpacity(0.5)),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.image_outlined, color: AppColors.primary),
                tooltip: 'Add Image',
                onPressed: _pickImage,
              ),
              IconButton(
                icon: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
                tooltip: 'Take Photo',
                onPressed: () {
                  // Stub for camera
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
