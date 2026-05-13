import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../core/services/location_service.dart';
import '../../widgets/common/location_picker_sheet.dart';
import '../../core/theme/app_colors.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const PrimaryButton({super.key, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16)),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }
}

class WorkerSignupScreen extends ConsumerStatefulWidget {
  const WorkerSignupScreen({super.key});

  @override
  ConsumerState<WorkerSignupScreen> createState() => _WorkerSignupScreenState();
}

class _WorkerSignupScreenState extends ConsumerState<WorkerSignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _bioController = TextEditingController();
  final _subLocationController = TextEditingController();
  final _referralCodeController = TextEditingController();
  List<String> _skills = [];
  bool _isLoading = true;
  bool _isAutoDetected = false;

  @override
  void initState() {
    super.initState();
    fetchSkills();
    _autoDetectLocation();
  }

  Future<void> _autoDetectLocation() async {
    setState(() => _isDetectingLocation = true);
    try {
      final position = await LocationService.getCurrentLocation();
      if (position != null) {
        final locationData = await LocationService.getLocationFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (locationData != null && mounted) {
          setState(() {
            _locationLabel = locationData['fullLocation'] ?? locationData['city'];
            _subLocationController.text = locationData['subLocation'];
            _latitude = locationData['latitude'];
            _longitude = locationData['longitude'];
            _isAutoDetected = true;
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Enable location for auto-fill.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error auto-detecting location: $e");
    } finally {
      if (mounted) setState(() => _isDetectingLocation = false);
    }
  }

  Future<void> fetchSkills() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('job_categories')
        .where('isActive', isEqualTo: true)
        .get();

    final skills = snapshot.docs
        .map((doc) => doc['name'].toString())
        .toList();

    setState(() {
      _skills = skills;
      _selectedSkill = skills.isNotEmpty ? skills[0] : '';
      _isLoading = false;
    });
  }

  String _selectedSkill = '';
  int _experience = 0;
  String _locationLabel = 'Detecting...';
  double? _latitude;
  double? _longitude;
  bool _isDetectingLocation = false;
  DateTime? _dateOfBirth;
  XFile? _profilePhoto;

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (image != null) {
        setState(() {
          _profilePhoto = image;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _submitForm() {
    if (_dateOfBirth == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select your Date of Birth')));
      return;
    }
    if (_formKey.currentState!.validate()) {
      context.push('/otp', extra: {
        'phone': _phoneController.text.trim(),
        'role': 'worker',
        'name': _nameController.text.trim(),
        'skill': _selectedSkill,
        'experience': _experience.toString(),
        'email': _emailController.text.trim(),
        'bio': _bioController.text.trim(),
        'location': _locationLabel,
        'subLocation': _subLocationController.text.trim(),
        'latitude': _latitude?.toString(),
        'longitude': _longitude?.toString(),
        'dateOfBirth': _dateOfBirth!.toIso8601String(),
        'profilePhotoPath': _profilePhoto?.path,
        'referralCode': _referralCodeController.text.trim(),
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    _subLocationController.dispose();
    _referralCodeController.dispose();
    super.dispose();
  }

  Widget _sectionLabel(String text, Color accentColor) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: accentColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(text,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
      ],
    );
  }

  Widget _textField({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    Widget? prefixWidget,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          maxLines: maxLines,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            filled: true,
            fillColor: Theme.of(context).cardColor,
            prefixIcon: prefixWidget,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            contentPadding:
                 EdgeInsets.symmetric(horizontal: 16, vertical: maxLines > 1 ? 16 : 0),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
        title: _StepIndicator(current: 1, total: 3),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Create Your Profile",
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface),
              ),
              const SizedBox(height: 6),
              Text(
                "Tell us about your professional expertise and basic details to get started.",
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
              ),
              const SizedBox(height: 24),

              _ProfilePhotoCard(
                profilePhoto: _profilePhoto,
                onPickImage: _pickImage,
              ),
              const SizedBox(height: 28),

              _sectionLabel("Personal Information", AppColors.primary),
              const SizedBox(height: 16),

              _textField(
                label: "Full Name",
                hint: "e.g. Rajesh Kumar",
                controller: _nameController,
                validator: (v) =>
                    (v == null || v.isEmpty) ? "Full name is required" : null,
              ),
              const SizedBox(height: 16),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Mobile Number",
                      style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        height: 54,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text("+91",
                            style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                                fontSize: 15)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: TextStyle(color: theme.colorScheme.onSurface),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return "Mobile number is required";
                            }
                            if (v.length < 10) {
                              return "Enter a valid mobile number";
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            hintText: "98765 43210",
                            hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                            filled: true,
                            fillColor: theme.cardColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Colors.redAccent),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _textField(
                label: "Email (Optional)",
                hint: "rajesh@example.com",
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              const Text("Date of Birth", style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: Theme.of(context).colorScheme.copyWith(
                            primary: AppColors.primary,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    setState(() => _dateOfBirth = picked);
                  }
                },
                child: Container(
                  height: 54,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _dateOfBirth == null 
                      ? "Select your Date of Birth" 
                      : "${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}",
                    style: TextStyle(
                      color: _dateOfBirth == null ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.onSurface,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              _textField(
                label: "Biography / Professional Bio",
                hint: "Tell us about your expertise, experience,\nand what you are looking for...",
                controller: _bioController,
                maxLines: 4,
              ),
              const SizedBox(height: 28),

              _sectionLabel("Work Details", const Color(0xFF10B981)),
              const SizedBox(height: 16),

              const Text("Skill Category",
                  style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.dividerColor, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(theme.brightness == Brightness.dark ? 0.2 : 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: DropdownButtonHideUnderline(
                  child: _isLoading
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        )
                      : DropdownButton<String>(
                          value: _selectedSkill.isEmpty ? null : _selectedSkill,
                          isExpanded: true,
                          dropdownColor: theme.cardColor,
                          iconEnabledColor: theme.colorScheme.onSurfaceVariant,
                          style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 15, fontWeight: FontWeight.w500),
                          items: _skills.map((skill) {
                            return DropdownMenuItem(
                              value: skill,
                              child: Text(skill),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedSkill = val);
                            }
                          },
                        ),
                ),
              ),
              const SizedBox(height: 16),

              const Text("Years of Experience",
                  style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _StepperButton(
                      icon: Icons.remove,
                      onTap: () {
                        if (_experience > 0) {
                          setState(() => _experience--);
                        }
                      },
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            _experience.toString().padLeft(2, '0'),
                            style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface),
                          ),
                          const Text("YEARS",
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 11)),
                        ],
                      ),
                    ),
                    _StepperButton(
                      icon: Icons.add,
                      onTap: () => setState(() => _experience++),
                      filled: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              const Text("Preferred Work Location",
                  style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 8),
              _MapCard(
                label: _locationLabel,
                isDetecting: _isDetectingLocation,
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => LocationPickerSheet(
                      onLocationSelected: (loc) {
                        setState(() {
                          _locationLabel = loc['city'] ?? loc['description'];
                          _subLocationController.text = loc['subLocation'] ?? '';
                          _latitude = loc['lat'];
                          _longitude = loc['lon'];
                          _isAutoDetected = false;
                        });
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _textField(
                label: "Sub-Location / Area / Landmark",
                hint: "e.g. Near HDFC Bank, Sector 15",
                controller: _subLocationController,
                validator: (v) => (v == null || v.isEmpty) ? "Sub-location is required" : null,
              ),
              if (_isAutoDetected)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0, left: 4.0),
                  child: Row(
                    children: [
                      Icon(Icons.location_on, size: 12, color: Colors.green.shade600),
                      const SizedBox(width: 4),
                      Text(
                        "📍 Auto-detected",
                        style: TextStyle(
                          color: Colors.green.shade600,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              _textField(
                label: "Referral Code (Optional)",
                hint: "Enter code to earn rewards",
                controller: _referralCodeController,
                prefixWidget: const Icon(Icons.confirmation_num_outlined, size: 20),
              ),
              const SizedBox(height: 30),

              PrimaryButton(
                label: "Continue to Verification",
                onPressed: _submitForm,
              ),
              const SizedBox(height: 16),

              Center(
                child: GestureDetector(
                  onTap: () => context.push('/login'),
                  child: RichText(
                    text: TextSpan(
                      text: "Already have an account? ",
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
                      children: [
                        TextSpan(
                          text: "Log In",
                          style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int current;
  final int total;
  const _StepIndicator({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(total, (i) {
        final active = i + 1 == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            color:
                active ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

class _ProfilePhotoCard extends StatelessWidget {
  final XFile? profilePhoto;
  final VoidCallback onPickImage;

  const _ProfilePhotoCard({
    this.profilePhoto,
    required this.onPickImage,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPickImage,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: Theme.of(context).dividerColor, width: 1.5),
                    borderRadius: BorderRadius.circular(14),
                    color: Theme.of(context).scaffoldBackgroundColor,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: profilePhoto != null
                      ? Image.file(File(profilePhoto!.path), fit: BoxFit.cover)
                      : Icon(Icons.camera_alt_outlined,
                          color: Theme.of(context).colorScheme.onSurfaceVariant, size: 28),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Theme.of(context).cardColor, width: 2),
                    ),
                    child: const Icon(Icons.edit, color: Colors.white, size: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Profile Photo",
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text(
                    "Clear facial photo helps in getting 2× more work requests.",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  const _StepperButton({
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: filled ? Theme.of(context).colorScheme.primary : Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: filled ? Colors.white : Theme.of(context).colorScheme.onSurface, size: 20),
      ),
    );
  }
}

class _MapCard extends StatelessWidget {
  final String label;
  final bool isDetecting;
  final VoidCallback onTap;

  const _MapCard({required this.label, required this.onTap, this.isDetecting = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 130,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(14),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            CustomPaint(
              size: const Size(double.infinity, 130),
              painter: _MapGridPainter(theme.colorScheme.onSurface.withOpacity(0.03)),
            ),
            Positioned(
              top: 28,
              left: 90,
              child: Icon(Icons.location_on, color: theme.colorScheme.onSurface.withOpacity(0.1), size: 22),
            ),
            Positioned(
              top: 55,
              left: 40,
              child: Icon(Icons.location_on, color: theme.colorScheme.onSurface.withOpacity(0.05), size: 18),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: isDetecting 
                  ? const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location, color: Colors.white, size: 18),
              ),
            ),
            Positioned(
              bottom: 12,
              left: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.dividerColor, width: 0.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on,
                        color: theme.colorScheme.primary, size: 14),
                    const SizedBox(width: 5),
                    Text(label,
                        style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontSize: 12,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  final Color gridColor;
  _MapGridPainter(this.gridColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    const step = 24.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_MapGridPainter oldDelegate) => false;
}
