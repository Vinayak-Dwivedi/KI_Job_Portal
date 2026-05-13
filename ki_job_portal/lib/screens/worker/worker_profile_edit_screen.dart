import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/worker_provider.dart';
import '../../widgets/common/location_picker_sheet.dart';
import '../../core/services/location_service.dart';

class WorkerProfileEditScreen extends ConsumerStatefulWidget {
  const WorkerProfileEditScreen({super.key});

  @override
  ConsumerState<WorkerProfileEditScreen> createState() => _WorkerProfileEditScreenState();
}

class _WorkerProfileEditScreenState extends ConsumerState<WorkerProfileEditScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _subLocationCtrl = TextEditingController();
  double _experienceYears = 8.0;
  double? _latitude;
  double? _longitude;
  bool _isDetectingLocation = false;
  bool _isAutoDetected = false;

  @override
  void initState() {
    super.initState();
    final worker = ref.read(workerProvider);
    if (worker != null) {
      _nameCtrl.text = worker.name;
      _phoneCtrl.text = worker.phone;
      _emailCtrl.text = 'rajesh.kumar@worker.com'; // Mock email
      _locationCtrl.text = worker.location;
      _subLocationCtrl.text = worker.subLocation ?? '';
      _latitude = worker.latitude;
      _longitude = worker.longitude;
    }
  }

  void _saveChanges() {
    final worker = ref.read(workerProvider);
    if (worker != null) {
      ref.read(workerProvider.notifier).updateWorker(
        worker.copyWith(
          name: _nameCtrl.text, 
          phone: _phoneCtrl.text, 
          location: _locationCtrl.text,
          subLocation: _subLocationCtrl.text,
          latitude: _latitude,
          longitude: _longitude,
        ),
      );
    }
    context.pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated!'), backgroundColor: AppColors.secondary),
    );
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
            _locationCtrl.text = locationData['fullLocation'] ?? locationData['city'];
            _subLocationCtrl.text = locationData['subLocation'];
            _latitude = locationData['latitude'];
            _longitude = locationData['longitude'];
            _isAutoDetected = true;
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Enable location for auto-fill.')),
          );
        }
      }
    } catch (e) {
      debugPrint("Error auto-detecting location: $e");
    } finally {
      if (mounted) setState(() => _isDetectingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkSurface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Professional Profile',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.more_vert, color: Colors.white), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header Card with banner
            Container(
              decoration: BoxDecoration(
                color: AppColors.darkSurfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  // Blue banner
                  Container(
                    height: 80,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1E3A8A),
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                    ),
                  ),
                  // Avatar and details
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Transform.translate(
                          offset: const Offset(0, -30),
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              CircleAvatar(
                                radius: 40,
                                backgroundColor: Colors.white,
                                backgroundImage: ref.watch(workerProvider)?.profilePhotoUrl != null 
                                  ? NetworkImage(ref.watch(workerProvider)!.profilePhotoUrl!)
                                  : null,
                                child: ref.watch(workerProvider)?.profilePhotoUrl == null 
                                  ? const Icon(Icons.person, size: 40, color: Colors.grey)
                                  : null,
                              ),
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                                child: const Icon(Icons.edit, size: 16, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Transform.translate(
                          offset: const Offset(0, -10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _nameCtrl.text.isNotEmpty ? _nameCtrl.text : 'Rajesh Kumar',
                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const Text(
                                'Master Electrician & Plumber',
                                style: TextStyle(color: AppColors.darkOnSurfaceVariant, fontSize: 12, fontStyle: FontStyle.italic),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            _buildSectionHeader('PERSONAL INFORMATION'),
            const SizedBox(height: 16),
            _buildTextField('FULL NAME', _nameCtrl),
            const SizedBox(height: 16),
            _buildTextField('MOBILE NUMBER', _phoneCtrl),
            const SizedBox(height: 16),
            _buildTextField('EMAIL ADDRESS', _emailCtrl),
            const SizedBox(height: 32),

            _buildSectionHeader('WORK DETAILS'),
            const SizedBox(height: 16),
            const Text('SKILL CATEGORIES', style: TextStyle(color: AppColors.darkOnSurfaceVariant, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildSkillChip('Electrician'),
                _buildSkillChip('Plumbing'),
                _buildSkillChip('Home Repair'),
                _buildAddSkillChip(),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('EXPERIENCE', style: TextStyle(color: AppColors.darkOnSurfaceVariant, fontSize: 12, fontWeight: FontWeight.bold)),
                Text('${_experienceYears.toInt()} Years', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ],
            ),
            Slider(
              value: _experienceYears,
              min: 0,
              max: 20,
              activeColor: AppColors.primary,
              inactiveColor: AppColors.darkSurfaceContainerHighest,
              onChanged: (val) => setState(() => _experienceYears = val),
            ),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('BEGINNER', style: TextStyle(color: AppColors.darkOnSurfaceVariant, fontSize: 10)),
                Text('INTERMEDIATE', style: TextStyle(color: AppColors.darkOnSurfaceVariant, fontSize: 10)),
                Text('EXPERT', style: TextStyle(color: AppColors.darkOnSurfaceVariant, fontSize: 10)),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('SERVICE LOCATION', style: TextStyle(color: AppColors.darkOnSurfaceVariant, fontSize: 12, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: _isDetectingLocation ? null : _autoDetectLocation,
                  icon: _isDetectingLocation 
                    ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                    : const Icon(Icons.my_location, size: 14, color: AppColors.primary),
                  label: Text(
                    _isDetectingLocation ? 'Detecting...' : 'Auto-detect',
                    style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => LocationPickerSheet(
                    onLocationSelected: (loc) {
                      setState(() {
                        _locationCtrl.text = loc['city'] ?? loc['description'];
                        _subLocationCtrl.text = loc['subLocation'] ?? '';
                        _latitude = loc['lat'];
                        _longitude = loc['lon'];
                        _isAutoDetected = false;
                      });
                    },
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.darkSurfaceContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _locationCtrl.text.isNotEmpty ? _locationCtrl.text : 'Select Location',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        const Icon(Icons.map_rounded, color: AppColors.primary, size: 20),
                      ],
                    ),
                    if (_subLocationCtrl.text.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        _subLocationCtrl.text,
                        style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (_isAutoDetected)
              Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                child: Row(
                  children: [
                    Icon(Icons.location_on, size: 12, color: Colors.green.shade400),
                    const SizedBox(width: 4),
                    Text(
                      "📍 Auto-detected",
                      style: TextStyle(
                        color: Colors.green.shade400,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 32),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionHeader('PORTFOLIO'),
                const Text('6 / 12 PHOTOS', style: TextStyle(color: AppColors.darkOnSurfaceVariant, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildPortfolioItem('https://images.unsplash.com/photo-1540569014015-19a7be504e3a?w=200'),
                  const SizedBox(width: 12),
                  _buildPortfolioItem('https://images.unsplash.com/photo-1581092921461-eab62e97a780?w=200'),
                  const SizedBox(width: 12),
                  _buildAddPortfolioItem(),
                ],
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saveChanges,
                style: FilledButton.styleFrom(
                   backgroundColor: AppColors.primary,
                   padding: const EdgeInsets.symmetric(vertical: 20),
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('SAVE CHANGES', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 40), // Bottom padding
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(width: 4, height: 16, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.darkOnSurfaceVariant, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.darkSurfaceContainer,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildSkillChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(color: Colors.lightBlue, fontSize: 12)),
          const SizedBox(width: 8),
          const Icon(Icons.close, size: 14, color: Colors.lightBlue),
        ],
      ),
    );
  }

  Widget _buildAddSkillChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.add, size: 14, color: Colors.white70),
          SizedBox(width: 4),
          Text('Add Skill', style: TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildPortfolioItem(String image) {
    return Container(
      width: 100,
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(image: NetworkImage(image), fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildAddPortfolioItem() {
    return Container(
      width: 100,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkSurfaceContainerHighest, style: BorderStyle.solid),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt, color: AppColors.darkOnSurfaceVariant, size: 24),
            SizedBox(height: 4),
            Text('UPLOAD WORK', style: TextStyle(color: AppColors.darkOnSurfaceVariant, fontSize: 8, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
