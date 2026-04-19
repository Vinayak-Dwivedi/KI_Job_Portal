import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/post_service.dart';
// import '../../widgets/feed/post_pending_banner.dart';
import '../../providers/worker_provider.dart';
import '../../providers/employer_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _jobTitleController = TextEditingController();
  final TextEditingController _jobSalaryController = TextEditingController();
  final TextEditingController _jobLocationController = TextEditingController();
  final TextEditingController _jobExperienceController = TextEditingController();
  final TextEditingController _jobSkillsController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final List<Map<String, dynamic>> _selectedMedia = []; // {'file': File, 'type': 'image' or 'video'}

  bool _isLoading = false;
  bool _isJobPost = false;
  bool _isAvailabilityPost = false;

  // Event state
  DateTime? _eventDate;
  TimeOfDay? _eventTime;
  String? _eventLocation;
  String? _eventTitle;

  // Visibility state
  String _visibility = 'public';

  Future<void> _pickImages() async {
    if (_selectedMedia.length >= 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 4 media files allowed per post')),
      );
      return;
    }

    try {
      final List<XFile> media = await _picker.pickMultipleMedia(
        imageQuality: 80,
      );
      
      if (media.isNotEmpty) {
        setState(() {
          for (var item in media) {
            if (_selectedMedia.length < 4) {
              final extension = item.path.split('.').last.toLowerCase();
              final isVideo = ['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(extension);
              _selectedMedia.add({'file': File(item.path), 'type': isVideo ? 'video' : 'image'});
            }
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick media: $e')),
      );
    }
  }

  Future<void> _pickCamera() async {
    if (_selectedMedia.length >= 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 4 media files allowed per post')),
      );
      return;
    }

    try {
      // Pick video from camera
      final XFile? video = await _picker.pickVideo(source: ImageSource.camera);
      if (video != null) {
        setState(() {
          _selectedMedia.add({'file': File(video.path), 'type': 'video'});
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick video: $e')),
      );
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    _jobTitleController.dispose();
    _jobSalaryController.dispose();
    _jobLocationController.dispose();
    _jobExperienceController.dispose();
    _jobSkillsController.dispose();
    super.dispose();
  }

  void _showVisibilitySheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Who can see this post?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              _visibilityOption('Public', 'public', Icons.public),
              _visibilityOption('Following', 'following', Icons.people),
              if (ref.read(authProvider)?.role != 'employer') 
                _visibilityOption('Employers Only', 'employers', Icons.work),
              if (ref.read(authProvider)?.role != 'worker')
                _visibilityOption('Workers Only', 'workers', Icons.engineering),
            ],
          ),
        );
      }
    );
  }

  Widget _visibilityOption(String title, String value, IconData icon) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: _visibility == value ? const Icon(Icons.check, color: Colors.blue) : null,
      onTap: () {
        setState(() => _visibility = value);
        Navigator.pop(context);
      },
    );
  }

  void _showEventDialog() {
    final titleCtrl = TextEditingController(text: _eventTitle);
    final locCtrl = TextEditingController(text: _eventLocation);
    DateTime? tempDate = _eventDate;
    TimeOfDay? tempTime = _eventTime;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setDialogState) {
          final theme = Theme.of(context);
          return AlertDialog(
            title: Text('Add Event Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: theme.colorScheme.onSurface)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Event Title')),
                   TextField(controller: locCtrl, decoration: const InputDecoration(labelText: 'Location')),
                   const SizedBox(height: 16),
                   ListTile(
                     contentPadding: EdgeInsets.zero,
                     title: Text(tempDate == null ? 'Select Date' : '${tempDate!.day}/${tempDate!.month}/${tempDate!.year}'),
                     trailing: const Icon(Icons.calendar_today),
                     onTap: () async {
                       final dt = await showDatePicker(context: context, initialDate: tempDate ?? DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2030));
                       if (dt != null) setDialogState(() => tempDate = dt);
                     },
                   ),
                   ListTile(
                     contentPadding: EdgeInsets.zero,
                     title: Text(tempTime == null ? 'Select Time' : tempTime!.format(context)),
                     trailing: const Icon(Icons.access_time),
                     onTap: () async {
                       final tm = await showTimePicker(context: context, initialTime: tempTime ?? TimeOfDay.now());
                       if (tm != null) setDialogState(() => tempTime = tm);
                     },
                   ),
                 ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _eventTitle = titleCtrl.text.trim();
                    _eventLocation = locCtrl.text.trim();
                    _eventDate = tempDate;
                    _eventTime = tempTime;
                  });
                  Navigator.pop(context);
                },
                child: const Text('Save Event')
              )
            ],
          );
        });
      }
    );
  }

  Future<void> _submitPost() async {
    final desc = _descController.text.trim();

    if (desc.isEmpty && _selectedMedia.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add some text or an image to post!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final auth = ref.read(authProvider);
      if (auth == null) throw Exception("User not logged in");

      final isWorker = auth.role == 'worker';
      
      String name = 'Unknown User';
      String? photoUrl;
      bool isVerified = false;

      String? employerCompany;

      if (isWorker) {
        final worker = ref.read(workerProvider);
        name = worker?.name ?? 'Worker';
        photoUrl = worker?.profilePhotoUrl;
        isVerified = worker?.isVerified ?? false;
      } else if (auth.role == 'admin') {
        final adminDoc = await FirebaseFirestore.instance.collection('users').doc(auth.uid).get();
        final adminData = adminDoc.data();
        name = adminData?['name'] ?? adminData?['fullName'] ?? 'Admin';
        photoUrl = adminData?['profilePhotoUrl'];
        isVerified = true;
      } else {
        final employer = ref.read(employerProvider);
        name = employer?.name ?? 'Employer';
        photoUrl = employer?.profilePhotoUrl;
        isVerified = employer?.isVerified ?? false;
        employerCompany = employer?.companyName;
      }

      await PostService.createPost(
        uid: auth.uid,
        name: name,
        role: auth.role,
        text: desc,
        mediaFiles: _selectedMedia,
        isAdmin: auth.role == 'admin',
        profilePhotoUrl: photoUrl,
        isVerified: isVerified,
        location: (_isJobPost || _isAvailabilityPost) ? _jobLocationController.text.trim() : 'Current Location',
        isJobPost: _isJobPost,
        isAvailabilityPost: _isAvailabilityPost,
        jobTitle: (_isJobPost || _isAvailabilityPost) ? _jobTitleController.text.trim() : null,
        jobSalary: (_isJobPost || _isAvailabilityPost) ? _jobSalaryController.text.trim() : null,
        jobExperience: (_isJobPost || _isAvailabilityPost) ? _jobExperienceController.text.trim() : null,
        jobSkills: (_isJobPost || _isAvailabilityPost) ? _jobSkillsController.text.trim() : null,
        companyName: _isJobPost ? (employerCompany?.isNotEmpty == true ? employerCompany : name) : null,
        eventDate: _eventDate,
        eventTime: _eventTime?.format(context),
        eventLocation: _eventLocation?.isNotEmpty == true ? _eventLocation : null,
        eventTitle: _eventTitle?.isNotEmpty == true ? _eventTitle : null,
        visibility: _visibility,
      );

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to publish post: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final isWorker = auth?.role == 'worker';
    final theme = Theme.of(context);
    
    String name = 'User';
    String? photoUrl;
    if (isWorker) {
      name = ref.watch(workerProvider)?.name ?? 'Worker';
      photoUrl = ref.watch(workerProvider)?.profilePhotoUrl;
    } else {
      name = ref.watch(employerProvider)?.name ?? 'Employer';
      photoUrl = ref.watch(employerProvider)?.profilePhotoUrl;
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: theme.colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text('New Post', 
          style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w900, fontSize: 20)),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitPost,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              child: _isLoading 
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Post', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: theme.colorScheme.surfaceVariant,
                        backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                          ? NetworkImage(photoUrl)
                          : null,
                        child: (photoUrl == null || photoUrl.isEmpty)
                          ? Icon(Icons.person, color: theme.colorScheme.onSurfaceVariant)
                          : null,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          GestureDetector(
                            onTap: _showVisibilitySheet,
                            child: Container(
                              margin: const EdgeInsets.only(top: 2),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceVariant,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.public, size: 12, color: theme.colorScheme.onSurfaceVariant),
                                  const SizedBox(width: 4),
                                  Text(_visibility.toUpperCase(), style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 10, fontWeight: FontWeight.bold)),
                                  Icon(Icons.arrow_drop_down, size: 14, color: theme.colorScheme.onSurfaceVariant),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _descController,
                    maxLines: null,
                    minLines: 5,
                    autofocus: true,
                    style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 18, height: 1.5),
                    decoration: InputDecoration(
                      hintText: (_isJobPost || _isAvailabilityPost) 
                        ? (isWorker ? 'Tell employers why they should hire you...' : 'Describe the job requirements...') 
                        : 'What do you want to talk about?',
                      hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 18),
                      border: InputBorder.none,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Role-specific toggles
                  if (!isWorker)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.colorScheme.outline),
                      ),
                      child: SwitchListTile(
                        value: _isJobPost,
                        onChanged: (val) {
                          setState(() {
                            _isJobPost = val;
                            if (val) _isAvailabilityPost = false;
                          });
                        },
                        title: Text('Post as a Job', style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold)),
                        subtitle: Text('Will be featured in workers recommended jobs', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
                        activeColor: AppColors.primary,
                      ),
                    ),
                    
                  if (isWorker)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.colorScheme.outline),
                      ),
                      child: SwitchListTile(
                        value: _isAvailabilityPost,
                        onChanged: (val) {
                          setState(() {
                            _isAvailabilityPost = val;
                            if (val) _isJobPost = false;
                          });
                        },
                        title: Text('List as available for work', style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold)),
                        subtitle: Text('Tell employers about your skills and expected pay', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
                        activeColor: AppColors.primary,
                      ),
                    ),

                  if (_isJobPost || _isAvailabilityPost)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildJobField(
                          isWorker ? 'Position / Expertise (e.g. Senior Welder)' : 'Job Title (e.g. Senior Welder)', 
                          _jobTitleController, 
                          theme
                        ),
                        const SizedBox(height: 12),
                        _buildJobField(
                          isWorker ? 'Expected Pay (e.g. ₹35,000/mo)' : 'Salary / Rate (e.g. ₹35,000/mo)', 
                          _jobSalaryController, 
                          theme
                        ),
                        const SizedBox(height: 12),
                        _buildJobField('Location (e.g. Mumbai, MH)', _jobLocationController, theme),
                        const SizedBox(height: 12),
                        _buildJobField(
                          isWorker ? 'My Experience (e.g. 5 Years)' : 'Experience Required (e.g. 5 Years)', 
                          _jobExperienceController, 
                          theme
                        ),
                        const SizedBox(height: 12),
                        _buildJobField(
                          isWorker ? 'My Top Skills (e.g. Plumbing, Wiring)' : 'Skills Required (e.g. Plumbing, Wiring)', 
                          _jobSkillsController, 
                          theme
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  const SizedBox(height: 16),
                  if (_selectedMedia.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _selectedMedia.asMap().entries.map((entry) {
                        final index = entry.key;
                        final mediaItem = entry.value;
                        final File file = mediaItem['file'];
                        final bool isVideo = mediaItem['type'] == 'video';

                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 100,
                                height: 100,
                                color: theme.colorScheme.surfaceVariant,
                                child: isVideo
                                    ? Icon(Icons.videocam, size: 40, color: theme.colorScheme.onSurfaceVariant)
                                    : Image.file(file, fit: BoxFit.cover),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedMedia.removeAt(index)),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                  child: const Icon(Icons.close, color: Colors.white, size: 14),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  if (_eventTitle != null && _eventTitle!.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: theme.colorScheme.surfaceVariant.withOpacity(0.5), borderRadius: BorderRadius.circular(8)),
                      child: Row(
                         children: [
                           const Icon(Icons.event, color: AppColors.primary),
                           const SizedBox(width: 12),
                           Expanded(
                             child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                  Text(_eventTitle!, style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                                  if (_eventDate != null) Text('${_eventDate!.day}/${_eventDate!.month}/${_eventDate!.year} ${(_eventTime != null) ? _eventTime!.format(context) : ""}', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                                  if (_eventLocation != null && _eventLocation!.isNotEmpty) Text(_eventLocation!, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                               ],
                             )
                           ),
                           IconButton(icon: Icon(Icons.close, color: theme.colorScheme.onSurfaceVariant, size: 20), onPressed: () => setState(() { _eventTitle = null; _eventDate = null; _eventLocation = null; _eventTime = null; }))
                         ]
                      )
                    ),
                ],
              ),
            ),
          ),
          
          /// ── Bottom Toolbar ────────────────────────────
          Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 8,
              left: 16,
              right: 16,
              top: 8,
            ),
            decoration: BoxDecoration(
              color: theme.cardColor,
              border: Border(top: BorderSide(color: theme.colorScheme.outline, width: 0.5)),
            ),
            child: Row(
              children: [
                _buildToolbarItem(Icons.image_outlined, 'Photo', theme, _pickImages),
                _buildToolbarItem(Icons.camera_alt_outlined, 'Video', theme, _pickCamera),
                _buildToolbarItem(Icons.event_outlined, 'Event', theme, _showEventDialog),
                const Spacer(),
                _buildToolbarItem(Icons.more_horiz, 'Visibility', theme, _showVisibilitySheet),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarItem(IconData icon, String label, ThemeData theme, VoidCallback onTap) {
    return IconButton(
      icon: Icon(icon, color: theme.colorScheme.onSurfaceVariant, size: 24),
      onPressed: onTap,
      tooltip: label,
    );
  }

  Widget _buildJobField(String hint, TextEditingController controller, ThemeData theme) {
    return TextField(
      controller: controller,
      style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 14),
        filled: true,
        fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
