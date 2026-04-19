import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

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

  String _selectedHirerType = 'Company / Organization';
  LatLng? _selectedLocation;
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
        'profilePhotoPath': _profilePhoto?.path,
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
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
              Container(
                height: 160,
                width: double.infinity,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.05)),
                ),
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: const LatLng(19.0760, 72.8777), // Default initialization point
                    initialZoom: 11.0,
                    onTap: (tapPosition, point) {
                      setState(() {
                        _selectedLocation = point;
                      });
                    },
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.drag | InteractiveFlag.pinchZoom | InteractiveFlag.doubleTapZoom,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.kijobportal',
                    ),
                    if (_selectedLocation != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _selectedLocation!,
                            width: 80,
                            height: 80,
                            child: const Icon(Icons.location_on, color: Colors.redAccent, size: 40),
                          ),
                        ],
                      )
                    else
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: const LatLng(19.0760, 72.8777),
                            width: 120,
                            height: 40,
                            child: Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text('Tap map to pin location', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Center(
                child: Text(
                  "Tap the map to pin your exact operational\nheadquarters",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 11, height: 1.4),
                ),
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
