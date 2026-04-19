import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/category_service.dart';

class CreateJobScreen extends StatefulWidget {
  const CreateJobScreen({super.key});

  @override
  State<CreateJobScreen> createState() => _CreateJobScreenState();
}

class _CreateJobScreenState extends State<CreateJobScreen> {
  final _formKey = GlobalKey<FormState>();

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final wageController = TextEditingController();
  final durationController = TextEditingController();
  final workersController = TextEditingController();
  final locationController = TextEditingController();
  final experienceController = TextEditingController();
  final skillsController = TextEditingController();

  String? _selectedCategory;
  bool isLoading = false;
  
  late Future<List<String>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = CategoryService().getCategories();
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    wageController.dispose();
    durationController.dispose();
    workersController.dispose();
    locationController.dispose();
    experienceController.dispose();
    skillsController.dispose();
    super.dispose();
  }

  Future<void> _postJob() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a category")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('jobs').add({
        'uid': "uid_9999999999", // ⚠️ replace later with auth uid
        'title': titleController.text.trim(),
        'category': _selectedCategory,
        'description': descriptionController.text.trim(),
        'wage': wageController.text.trim(),
        'duration': durationController.text.trim(),
        'workersNeeded': workersController.text.trim(),
        'location': locationController.text.trim(),
        'experience': experienceController.text.trim(),
        'skills': skillsController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'active',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Job Posted Successfully")),
      );

      Navigator.pop(context);
    } catch (e) {
      print("❌ ERROR: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed: $e")),
      );
    }

    setState(() => isLoading = false);
  }

  InputDecoration input(String label) {
    final theme = Theme.of(context);
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: theme.cardColor,
      labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("New Job Post", style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: theme.colorScheme.onSurface,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: isLoading ? null : _postJob,
            child: isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.primary),
                  )
                : Text("Post", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.colorScheme.primary)),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: titleController,
                decoration: input("Job Title"),
                style: TextStyle(color: theme.colorScheme.onSurface),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),

              FutureBuilder<List<String>>(
                future: _categoriesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return TextFormField(
                      enabled: false,
                      decoration: input("Loading Categories..."),
                    );
                  }

                  if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                    return DropdownButtonFormField<String>(
                      decoration: input("Category"),
                      items: const [
                        DropdownMenuItem(value: "General", child: Text("General")),
                      ],
                      onChanged: (v) => setState(() => _selectedCategory = v),
                      validator: (v) => v == null ? "Required" : null,
                    );
                  }

                  final categories = snapshot.data!;

                  return DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: input("Category"),
                    items: categories.map((cat) {
                      return DropdownMenuItem(
                        value: cat,
                        child: Text(cat, style: TextStyle(color: theme.colorScheme.onSurface)),
                      );
                    }).toList(),
                    onChanged: (v) {
                      setState(() {
                        _selectedCategory = v;
                      });
                    },
                    validator: (v) => v == null ? "Required" : null,
                    icon: Icon(Icons.keyboard_arrow_down_rounded, color: theme.colorScheme.primary),
                    dropdownColor: theme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                  );
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: descriptionController,
                maxLines: 4,
                decoration: input("Job Description"),
                style: TextStyle(color: theme.colorScheme.onSurface),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: wageController,
                      keyboardType: TextInputType.number,
                      decoration: input("Daily Wage ₹"),
                      style: TextStyle(color: theme.colorScheme.onSurface),
                      validator: (v) => v!.isEmpty ? "Required" : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: durationController,
                      keyboardType: TextInputType.number,
                      decoration: input("Duration (Days)"),
                      style: TextStyle(color: theme.colorScheme.onSurface),
                      validator: (v) => v!.isEmpty ? "Required" : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: workersController,
                keyboardType: TextInputType.number,
                decoration: input("Workers Needed"),
                style: TextStyle(color: theme.colorScheme.onSurface),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: locationController,
                decoration: input("Location"),
                style: TextStyle(color: theme.colorScheme.onSurface),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: experienceController,
                decoration: input("Experience Required"),
                style: TextStyle(color: theme.colorScheme.onSurface),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: skillsController,
                decoration: input("Required Skills (e.g. Plumbing, Wiring)"),
                style: TextStyle(color: theme.colorScheme.onSurface),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),

              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: isLoading ? null : _postJob,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Post Job", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ),
      ),
    );
  }
}