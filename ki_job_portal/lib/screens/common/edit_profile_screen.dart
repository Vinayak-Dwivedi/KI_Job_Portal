import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import '../../providers/auth_provider.dart';
import '../../providers/worker_provider.dart';
import '../../providers/employer_provider.dart';
import '../../core/services/document_service.dart';
import '../../core/services/location_service.dart';
import '../../models/document_model.dart';
import '../../widgets/common/location_picker_sheet.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isDetectingLocation = false;

  String _role = 'worker';
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _subLocationController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  
  // Extended Fields
  final TextEditingController _permanentAddressController = TextEditingController();
  final TextEditingController _aadhaarController = TextEditingController();
  final TextEditingController _emergencyContactController = TextEditingController();
  final TextEditingController _companyRegController = TextEditingController();
  final TextEditingController _gstController = TextEditingController();
  
  String? _selectedGender;
  final List<String> _genderOptions = ['Male', 'Female', 'Other'];

  String? _selectedNationality;
  final List<String> _nationalityOptions = ['Indian', 'Nepali', 'Bangladeshi', 'Bhutanese', 'Sri Lankan', 'Other'];

  List<String> _selectedSkills = [];
  List<Map<String, dynamic>> _documents = [];
  List<String> _availableCategories = [];
  String _profilePhotoUrl = '';
  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final auth = ref.read(authProvider);
    if (auth == null) return;

    try {
      // 1. Fetch Job Categories
      final catsSnapshot = await FirebaseFirestore.instance.collection('job_categories').where('isActive', isEqualTo: true).get();
      _availableCategories = catsSnapshot.docs.map((d) => d['name'] as String).toList();

      // 2. Fetch User Profile
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(auth.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        _role = data['role'] ?? 'worker';
        _nameController.text = data['name'] ?? '';
        _emailController.text = data['email'] ?? '';
        _bioController.text = data['bio'] ?? '';
        
        final loc = data['location'];
        if (loc is Map<String, dynamic>) {
          _addressController.text = loc['address'] ?? '';
          _subLocationController.text = loc['subLocation'] ?? data['subLocation'] ?? '';
        } else if (loc is String) {
          _addressController.text = loc;
          _subLocationController.text = data['subLocation'] ?? '';
        }
        
        _latitude = data['latitude'] ?? (loc is Map ? loc['lat'] : null);
        _longitude = data['longitude'] ?? (loc is Map ? loc['lng'] : null);
        
        if (_role == 'worker') {
          _experienceController.text = (data['experience'] ?? 0).toString();
          final skillsList = data['skills'];
          if (skillsList is List) {
            _selectedSkills = List<String>.from(skillsList);
          }
          _selectedGender = data['gender'];
          final nationality = data['nationality'];
          if (nationality != null && _nationalityOptions.contains(nationality)) {
            _selectedNationality = nationality;
          } else if (nationality != null && nationality.isNotEmpty) {
            _selectedNationality = 'Other';
          }
          _permanentAddressController.text = data['permanentAddress'] ?? '';
          _aadhaarController.text = data['aadhaarNumber'] ?? '';
          _emergencyContactController.text = data['emergencyContact'] ?? '';
        } else {
          _companyRegController.text = data['companyRegistrationNumber'] ?? '';
          _gstController.text = data['gstNumber'] ?? '';
        }

        final docsList = data['documents'];
        if (docsList is List) {
          _documents = List<Map<String, dynamic>>.from(docsList);
        }
        _profilePhotoUrl = data['profilePhotoUrl'] ?? '';
      }
    } catch (e) {
      debugPrint("Error fetching data: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = ref.read(authProvider);
    if (auth == null) return;

    setState(() => _isSaving = true);

    try {
      final Map<String, dynamic> updateData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'bio': _bioController.text.trim(),
        'location': {
          'address': _addressController.text.trim(),
          'subLocation': _subLocationController.text.trim(),
          'lat': _latitude ?? 0.0,
          'lng': _longitude ?? 0.0,
        },
        'subLocation': _subLocationController.text.trim(), // Keep for backward compat
        'latitude': _latitude,
        'longitude': _longitude,
        'documents': _documents,
      };

      if (_role == 'worker') {
        updateData['experience'] = int.tryParse(_experienceController.text) ?? 0;
        updateData['skills'] = _selectedSkills;
        updateData['gender'] = _selectedGender;
        updateData['nationality'] = _selectedNationality;
        updateData['permanentAddress'] = _permanentAddressController.text.trim();
        updateData['aadhaarNumber'] = _aadhaarController.text.trim();
        updateData['emergencyContact'] = _emergencyContactController.text.trim();
      } else {
        updateData['companyRegistrationNumber'] = _companyRegController.text.trim();
        updateData['gstNumber'] = _gstController.text.trim();
      }

      await FirebaseFirestore.instance.collection('users').doc(auth.uid).update(updateData);

      // Refresh Provider State
      if (_role == 'worker') {
        ref.read(workerProvider.notifier).loadProfile(auth.uid);
      } else {
        ref.read(employerProvider.notifier).loadProfile(auth.uid);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green),
        );
        context.pop();
      }
    } catch (e) {
      debugPrint("Error updating Profile: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error updating profile'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _updateProfilePhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (image != null) {
        setState(() => _isLoading = true);
        final auth = ref.read(authProvider);
        if (auth == null) return;
        final file = File(image.path);
        final extension = image.path.split('.').last.toLowerCase();
        final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.$extension';
        final storageRef = FirebaseStorage.instance.ref().child('users').child(auth.uid).child(fileName);
        await storageRef.putFile(file);
        final url = await storageRef.getDownloadURL();
        await FirebaseFirestore.instance.collection('users').doc(auth.uid).update({'profilePhotoUrl': url});
        
        setState(() {
          _profilePhotoUrl = url;
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile photo updated'), backgroundColor: Colors.green));
        
        if (_role == 'worker') {
          ref.read(workerProvider.notifier).loadProfile(auth.uid);
        } else {
          ref.read(employerProvider.notifier).loadProfile(auth.uid);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint("Photo upload error: $e");
    }
  }

  Future<String?> _showCategoryDialog() async {
    String? selectedCategory = 'ID Proof';
    final categories = ['ID Proof', 'Address Proof', 'GST', 'Certificate', 'Resume', 'Other'];
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Document Category'),
        content: DropdownButtonFormField<String>(
          value: selectedCategory,
          items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (val) => selectedCategory = val,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => context.pop(null), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => context.pop(selectedCategory), child: const Text('Upload')),
        ],
      ),
    );
  }

  Future<void> _pickDocument() async {
    if (_documents.length >= 4) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Maximum 4 documents allowed. Delete an existing one to add another.'), backgroundColor: Colors.orange));
      return;
    }
    
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );
 
      if (result != null && result.files.single.path != null) {
        final category = await _showCategoryDialog();
        if (category == null) return; // User cancelled

        setState(() => _isLoading = true);
        final auth = ref.read(authProvider);
        if (auth == null) return;
        
        // Use our new DocumentService
        final doc = await DocumentService.uploadDocument(
          uid: auth.uid,
          name: result.files.single.name,
          phone: auth.phone,
          category: category,
          file: File(result.files.single.path!),
        );
        
        setState(() {
          _documents.add(doc.toMap());
          _isLoading = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document uploaded successfully!'), backgroundColor: Colors.green));
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint("Document upload error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error uploading document'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _pickLocation() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LocationPickerSheet(
        onLocationSelected: (loc) {
          setState(() {
            _addressController.text = loc['city'] ?? loc['description'];
            _subLocationController.text = loc['subLocation'] ?? '';
            _latitude = loc['lat'];
            _longitude = loc['lon'];
          });
        },
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _subLocationController.dispose();
    _bioController.dispose();
    _experienceController.dispose();
    _permanentAddressController.dispose();
    _aadhaarController.dispose();
    _emergencyContactController.dispose();
    _companyRegController.dispose();
    _gstController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(child: CircularProgressIndicator(color: theme.colorScheme.primary)),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text('Edit Profile', style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.5), width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: theme.colorScheme.surfaceVariant,
                        backgroundImage: _profilePhotoUrl.isNotEmpty 
                            ? CachedNetworkImageProvider(_profilePhotoUrl)
                            : null,
                        child: _profilePhotoUrl.isEmpty 
                            ? Icon(Icons.person_rounded, size: 50, color: theme.colorScheme.onSurfaceVariant)
                            : null,
                      ),
                    ),
                    InkWell(
                      onTap: _updateProfilePhoto,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: theme.scaffoldBackgroundColor, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _buildSectionTitle('Basic Information', theme),
              const SizedBox(height: 16),
              _buildTextField('Full Name', _nameController, theme, isRequired: true, icon: Icons.person_outline),
              const SizedBox(height: 16),
              _buildTextField('Email Address', _emailController, theme, icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 16),
              _buildTextField('About / Bio', _bioController, theme, maxLines: 5, icon: Icons.description_outlined),
              const SizedBox(height: 16),
              _buildTextField(
                'City / Location', 
                _addressController, 
                theme, 
                icon: Icons.location_on_outlined,
                readOnly: true,
                onTap: _pickLocation,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.map_rounded, size: 18),
                  onPressed: _pickLocation,
                ),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                'Sub-Location / Area', 
                _subLocationController, 
                theme, 
                icon: Icons.map_outlined,
                readOnly: true,
                onTap: _pickLocation,
              ),
              const SizedBox(height: 32),
              
              if (_role == 'worker') ...[
                _buildSectionTitle('Professional Details', theme),
                const SizedBox(height: 16),
                _buildTextField('Experience (Years)', _experienceController, theme, isNumber: true, icon: Icons.work_outline),
                const SizedBox(height: 24),
                Text('Expertise / Skills', style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _availableCategories.map((skill) {
                    final isSelected = _selectedSkills.contains(skill);
                    return InkWell(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedSkills.remove(skill);
                          } else {
                            _selectedSkills.add(skill);
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? theme.colorScheme.primary : theme.cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline.withOpacity(0.3)),
                        ),
                        child: Text(
                          skill,
                          style: TextStyle(
                            color: isSelected ? Colors.white : theme.colorScheme.onSurfaceVariant,
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),
                
                _buildSectionTitle('Verification Details', theme),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.people_outline, size: 20, color: theme.colorScheme.primary.withOpacity(0.7)),
                    filled: true,
                    fillColor: theme.cardColor,
                    hintText: 'Select Gender',
                    hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5), fontSize: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.1))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.1))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  items: _genderOptions.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                  onChanged: (val) => setState(() => _selectedGender = val),
                  dropdownColor: theme.cardColor,
                  style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 15),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedNationality,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.public, size: 20, color: theme.colorScheme.primary.withOpacity(0.7)),
                    filled: true,
                    fillColor: theme.cardColor,
                    hintText: 'Select Nationality',
                    hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5), fontSize: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.1))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.1))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  items: _nationalityOptions.map((n) => DropdownMenuItem(value: n, child: Text(n))).toList(),
                  onChanged: (val) => setState(() => _selectedNationality = val),
                  dropdownColor: theme.cardColor,
                  style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 15),
                ),
                const SizedBox(height: 16),
                _buildTextField('Permanent Address', _permanentAddressController, theme, maxLines: 2, icon: Icons.home_work_outlined),
                const SizedBox(height: 16),
                _buildTextField('Aadhaar / National ID', _aadhaarController, theme, icon: Icons.badge_outlined),
                const SizedBox(height: 16),
                _buildTextField('Emergency Contact Number', _emergencyContactController, theme, icon: Icons.phone_callback_outlined, keyboardType: TextInputType.phone),
                const SizedBox(height: 32),
              ] else ...[
                _buildSectionTitle('Company Registration details', theme),
                const SizedBox(height: 16),
                _buildTextField('Registration Number', _companyRegController, theme, icon: Icons.business_outlined),
                const SizedBox(height: 16),
                _buildTextField('GST Number', _gstController, theme, icon: Icons.receipt_long_outlined),
                const SizedBox(height: 32),
              ],

              // Documents Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionTitle('Documents', theme),
                  TextButton.icon(
                    onPressed: _documents.length >= 4 ? null : _pickDocument,
                    icon: Icon(Icons.add_circle_outline, color: _documents.length >= 4 ? Colors.grey : theme.colorScheme.primary, size: 18),
                    label: Text('Add New (Max 4)', style: TextStyle(color: _documents.length >= 4 ? Colors.grey : theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_documents.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
                  ),
                  child: Center(
                    child: Text('No documents added yet.', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13)),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _documents.length,
                  itemBuilder: (context, index) {
                    final doc = _documents[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.description_outlined, color: theme.colorScheme.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(doc['name'] ?? '', style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w600)),
                                if (doc['category'] != null) ...[
                                  const SizedBox(height: 2),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(doc['category'], style: TextStyle(color: theme.colorScheme.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () async {
                              final auth = ref.read(authProvider);
                              if (auth == null) return;
                              
                              setState(() => _isLoading = true);
                              try {
                                await DocumentService.deleteDocument(auth.uid, DocumentModel.fromMap(doc));
                                setState(() {
                                  _documents.removeAt(index);
                                });
                              } catch (e) {
                                debugPrint("Error deleting document: $e");
                              } finally {
                                setState(() => _isLoading = false);
                              }
                            },
                          )
                        ],
                      ),
                    );
                  },
                ),
              const SizedBox(height: 48),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isSaving 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Confirm Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Text(
      title,
      style: TextStyle(
        color: theme.colorScheme.onSurface,
        fontSize: 18,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, ThemeData theme, {bool isRequired = false, bool isNumber = false, int maxLines = 1, IconData? icon, TextInputType? keyboardType, Widget? suffixIcon, bool readOnly = false, VoidCallback? onTap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          readOnly: readOnly,
          onTap: onTap,
          style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 15),
          keyboardType: keyboardType ?? (isNumber ? TextInputType.number : TextInputType.text),
          validator: isRequired ? (value) {
            if (value == null || value.trim().isEmpty) return 'This field is required';
            return null;
          } : null,
          decoration: InputDecoration(
            prefixIcon: icon != null ? Icon(icon, size: 20, color: theme.colorScheme.primary.withOpacity(0.7)) : null,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: theme.cardColor,
            hintText: 'Enter your ${label.toLowerCase()}',
            hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5), fontSize: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }
}
