import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../core/services/location_service.dart';
import '../../widgets/common/location_picker_sheet.dart';

class EmployerSignupScreen extends StatefulWidget {
  const EmployerSignupScreen({super.key});

  @override
  State<EmployerSignupScreen> createState() => _EmployerSignupScreenState();
}

class _EmployerSignupScreenState extends State<EmployerSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _companyController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _subLocationController = TextEditingController();
  final _officeAddressController = TextEditingController();
  final _referralCodeController = TextEditingController();

  String _selectedHirerType = 'Company / Organization';
  LatLng? _selectedLocation;
  bool _isDetectingLocation = false;
  bool _isAutoDetected = false;
  DateTime? _dateOfBirth;
  XFile? _profilePhoto;

  @override
  void initState() {
    super.initState();
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
            _selectedLocation = LatLng(position.latitude, position.longitude);
            _officeAddressController.text = locationData['fullLocation'] ?? locationData['city'];
            _subLocationController.text = locationData['subLocation'];
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
        'role': 'employer',
        'name': _nameController.text.trim(),
        'company': _companyController.text.trim(),
        'businessType': _selectedHirerType,
        'bio': _bioController.text.trim(),
        'experience': '',
        'latitude': _selectedLocation?.latitude.toString() ?? '',
        'longitude': _selectedLocation?.longitude.toString() ?? '',
        'location': _officeAddressController.text.trim(),
        'subLocation': _subLocationController.text.trim(),
        'dateOfBirth': _dateOfBirth!.toIso8601String(),
        'profilePhotoPath': _profilePhoto?.path,
        'referralCode': _referralCodeController.text.trim(),
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _subLocationController.dispose();
    _officeAddressController.dispose();
    _referralCodeController.dispose();
    super.dispose();
  }

  Widget _sectionLabel(String text, Color accentColor) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: accentColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 16),
        ),
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
    Widget? suffixIcon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          maxLines: maxLines,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14),
            filled: true,
            fillColor: Theme.of(context).cardColor,
            prefixIcon: prefixWidget,
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: maxLines > 1 ? 16 : 0),
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
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.primary),
          onPressed: () => context.pop(),
        ),
        title: Text('Establish Profile', style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Company Identity ───────────────────────────────────────
              Row(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.cardColor,
                            border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.05), style: BorderStyle.none),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: _profilePhoto != null
                              ? Image.file(File(_profilePhoto!.path), fit: BoxFit.cover)
                              : CustomPaint(
                                  painter: _DashedCirclePainter(color: Colors.grey.withOpacity(0.4)),
                                  child: const Center(
                                    child: Icon(Icons.camera_alt_rounded, color: Colors.grey, size: 28),
                                  ),
                                ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: theme.scaffoldBackgroundColor, width: 2),
                          ),
                          child: const Icon(Icons.edit, color: Colors.white, size: 12),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Company Identity",
                          style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Upload your company logo to build immediate trust with skilled talent.",
                          style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.4),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border.all(color: theme.colorScheme.primary.withOpacity(0.5)),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "Upload Company Logo",
                            style: TextStyle(color: theme.colorScheme.primary, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),

              // ── Company Details ────────────────────────────────────────
              _sectionLabel("Company Details", Theme.of(context).colorScheme.primary),
              const SizedBox(height: 20),

              _textField(
                label: "FULL NAME / EMPLOYER NAME",
                hint: "e.g. Rajesh Kumar",
                controller: _nameController,
                validator: (v) => (v == null || v.isEmpty) ? "Name is required" : null,
              ),
              const SizedBox(height: 20),

              _textField(
                label: "COMPANY NAME",
                hint: "e.g. RK Infrastructure Ltd.",
                controller: _companyController,
                validator: (v) => (v == null || v.isEmpty) ? "Company name is required" : null,
              ),
              const SizedBox(height: 20),

              _textField(
                label: "MOBILE NUMBER",
                hint: "98765 43210",
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                prefixWidget: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("+91", style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                ),
                suffixIcon: const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 20),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Phone is required';
                  if (v.length < 10) return 'Enter a valid phone number';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              const Text("DATE OF BIRTH", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
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
                            primary: Theme.of(context).colorScheme.primary,
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
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              _textField(
                label: "COMPANY DESCRIPTION / BIO",
                hint: "Describe your business, values, and what\nyou look for in partners...",
                controller: _bioController,
                maxLines: 4,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return "Company description is required";
                  if (v.trim().length < 20) return "Please provide at least 20 characters";
                  return null;
                },
              ),
              const SizedBox(height: 36),

              // ── Operational Scope ──────────────────────────────────────
              _sectionLabel("Operational Scope", const Color(0xFFD94625)), // Orange/Red accent
              const SizedBox(height: 20),

              const Text(
                "EMPLOYER TYPE",
                style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedHirerType,
                    isExpanded: true,
                    dropdownColor: theme.cardColor,
                    icon: Icon(Icons.keyboard_arrow_down_rounded, color: theme.colorScheme.primary),
                    style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 15, fontWeight: FontWeight.w500),
                    items: [
                      'Individual Hirer',
                      'Contractor',
                      'Company / Organization',
                      'Sub-Contractor'
                    ].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value, style: TextStyle(color: theme.colorScheme.onSurface)),
                      );
                    }).toList(),

                    onChanged: (val) {
                      if (val != null) setState(() => _selectedHirerType = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                "OFFICE/SITE LOCATION",
                style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8),
              ),
              const SizedBox(height: 8),

              // Interactive Map
              _MapCard(
                label: _officeAddressController.text.isEmpty 
                    ? (_isDetectingLocation ? 'Detecting...' : 'Select Location')
                    : _officeAddressController.text,
                isDetecting: _isDetectingLocation,
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => LocationPickerSheet(
                      onLocationSelected: (loc) {
                        setState(() {
                          _officeAddressController.text = loc['city'] ?? loc['description'];
                          _subLocationController.text = loc['subLocation'] ?? '';
                          if (loc['lat'] != null && loc['lon'] != null) {
                            _selectedLocation = LatLng(loc['lat'], loc['lon']);
                          }
                          _isAutoDetected = false;
                        });
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
               _textField(
                label: "OFFICE CITY / LOCATION",
                hint: "e.g. New Delhi",
                controller: _officeAddressController,
                validator: (v) => (v == null || v.isEmpty) ? "City is required" : null,
                suffixIcon: _isDetectingLocation 
                  ? const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      icon: const Icon(Icons.my_location, size: 20),
                      onPressed: _autoDetectLocation,
                    ),
              ),
              const SizedBox(height: 20),
              _textField(
                label: "SUB-LOCATION / AREA / LANDMARK",
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
                label: "REFERRAL CODE (OPTIONAL)",
                hint: "Enter code to earn rewards",
                controller: _referralCodeController,
                prefixWidget: const Icon(Icons.confirmation_num_outlined, size: 20),
              ),
              const SizedBox(height: 48), // Padding before bottom actions
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text("Complete Profile", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.save_outlined, color: Colors.grey, size: 20),
                    SizedBox(height: 6),
                    Text("Save Progress", style: TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.help_outline, color: Colors.grey, size: 20),
                    SizedBox(height: 6),
                    Text("Help", style: TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
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
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  final Color color;
  _DashedCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    
    final rect = Rect.fromCenter(center: Offset(size.width / 2, size.height / 2), width: size.width - 2, height: size.height - 2);
    for (int i = 0; i < 360; i += 15) {
      if (i % 30 == 0) {
        canvas.drawArc(rect, i * 3.14159 / 180, 10 * 3.14159 / 180, false, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
