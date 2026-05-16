import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/post_service.dart';
import '../../providers/worker_provider.dart';
import '../../providers/employer_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/common/location_picker_sheet.dart';
import '../../core/services/location_service.dart';
import '../../l10n/app_localizations.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? post;
  const CreatePostScreen({super.key, this.post});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  late final TextEditingController _descController;
  late final TextEditingController _jobTitleController;
  late final TextEditingController _jobSalaryController;
  late final TextEditingController _jobLocationController;
  late final TextEditingController _jobExperienceController;
  late final TextEditingController _jobSkillsController;
  late final TextEditingController _jobSubLocationController;

  List<String> _skillCategories = [];

  @override
  void initState() {
    super.initState();
    final post = widget.post;
    _descController = TextEditingController(text: post?['text'] ?? '');
    _jobTitleController = TextEditingController(text: post?['jobTitle'] ?? '');
    _jobSalaryController = TextEditingController(text: post?['jobSalary'] ?? '');
    _jobLocationController = TextEditingController(text: post?['location'] ?? '');
    _jobExperienceController = TextEditingController(text: post?['jobExperience'] ?? '');
    _jobSkillsController = TextEditingController(text: post?['jobSkills'] ?? '');
    _jobSubLocationController = TextEditingController(text: post?['subLocation'] ?? '');
    
    _fetchSkillCategories();
    
    if (post != null) {
      _isJobPost = post['isJobPost'] ?? false;
      _isAvailabilityPost = post['isAvailabilityPost'] ?? false;
      _visibility = post['visibility'] ?? 'public';
      
      if (post['eventDate'] != null) {
        _eventDate = (post['eventDate'] as Timestamp).toDate();
        _eventTime = TimeOfDay.fromDateTime(_eventDate!);
        _eventLocation = post['eventLocation'];
        _eventSubLocation = post['eventSubLocation'];
        _eventTitle = post['eventTitle'];
      }
      
      if (post['media'] != null) {
        final List<dynamic> mediaList = post['media'];
        for (var m in mediaList) {
          _existingMedia.add({
            'url': m['url'],
            'type': m['type'],
          });
        }
      }
    }
  }

  final ImagePicker _picker = ImagePicker();
  final List<Map<String, dynamic>> _selectedMedia = []; // {'file': File, 'type': 'image' or 'video'}
  final List<Map<String, dynamic>> _existingMedia = []; // {'url': String, 'type': 'image' or 'video'}

  bool _isLoading = false;
  bool _isJobPost = false;
  bool _isAvailabilityPost = false;

  // Event state
  DateTime? _eventDate;
  TimeOfDay? _eventTime;
  String? _eventLocation;
  String? _eventSubLocation;
  String? _eventTitle;
  bool _isAutoDetected = false;
  bool _isDetectingLocation = false;

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
        for (var item in media) {
          if (_selectedMedia.length < 4) {
            final extension = item.path.split('.').last.toLowerCase();
            final isVideo = ['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(extension);
            
            if (isVideo) {
              final controller = VideoPlayerController.file(File(item.path));
              await controller.initialize();
              final duration = controller.value.duration;
              await controller.dispose();
              
              if (duration.inSeconds > 20) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Videos cannot exceed 20 seconds.')),
                  );
                }
                continue;
              }
            }

            setState(() {
              _selectedMedia.add({'file': File(item.path), 'type': isVideo ? 'video' : 'image'});
            });
          }
        }
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
        final controller = VideoPlayerController.file(File(video.path));
        await controller.initialize();
        final duration = controller.value.duration;
        await controller.dispose();
        
        if (duration.inSeconds > 20) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Videos cannot exceed 20 seconds.')),
            );
          }
          return;
        }

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
    _jobSubLocationController.dispose();
    super.dispose();
  }

  Future<void> _autoDetectLocation({
    required Function(String location, String subLocation) onDetected,
    VoidCallback? onStateChanged,
  }) async {
    setState(() => _isDetectingLocation = true);
    if (onStateChanged != null) onStateChanged();
    try {
      final position = await LocationService.getCurrentLocation();
      if (position != null) {
        final locationData = await LocationService.getLocationFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (locationData != null && mounted) {
          setState(() {
            _isAutoDetected = true;
          });
          onDetected(
            locationData['fullLocation'] ?? locationData['city'],
            locationData['subLocation'],
          );
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
      if (mounted) {
        setState(() => _isDetectingLocation = false);
        if (onStateChanged != null) onStateChanged();
      }
    }
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

  Future<void> _fetchSkillCategories() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('job_categories')
          .where('isActive', isEqualTo: true)
          .get();
      setState(() {
        _skillCategories = snapshot.docs.map((doc) => doc['name'].toString()).toList();
      });
    } catch (e) {
      debugPrint("Error fetching skill categories: $e");
    }
  }

  void _showAvailabilityDialog() {
    final theme = Theme.of(context);
    final isWorker = ref.read(authProvider)?.role == 'worker';
    
    final l10n = AppLocalizations.of(context)!;
    String? tempSkill = _jobTitleController.text.isNotEmpty ? _jobTitleController.text : (_skillCategories.isNotEmpty ? _skillCategories.first : null);
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(isWorker ? l10n.listAvailability : l10n.postAJob, style: const TextStyle(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isWorker) ...[
                    Text(l10n.selectSkillExpertise, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: tempSkill,
                          isExpanded: true,
                          hint: const Text("Select Skill"),
                          items: _skillCategories.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                          onChanged: (val) => setDialogState(() => tempSkill = val),
                        ),
                      ),
                    ),
                  ] else ...[
                    _buildJobField('Job Title', _jobTitleController, theme),
                  ],
                  const SizedBox(height: 12),
                  _buildJobField(isWorker ? l10n.expectedPay : l10n.salaryRate, _jobSalaryController, theme),
                  const SizedBox(height: 12),
                  _buildJobField(
                    l10n.location, 
                    _jobLocationController, 
                    theme,
                    readOnly: true,
                    suffixIcon: _isDetectingLocation 
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                        )
                      : IconButton(
                          icon: const Icon(Icons.my_location),
                          onPressed: () => _autoDetectLocation(
                            onDetected: (loc, sub) {
                              setDialogState(() {
                                _jobLocationController.text = loc;
                                _jobSubLocationController.text = sub;
                              });
                            },
                            onStateChanged: () => setDialogState(() {}),
                          ),
                        ),
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => LocationPickerSheet(
                          onLocationSelected: (loc) {
                            setDialogState(() {
                              _jobLocationController.text = loc['city'] ?? loc['description'];
                              _jobSubLocationController.text = loc['subLocation'] ?? '';
                            });
                            setState(() {
                              _isAutoDetected = false;
                            });
                          },
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildJobField(l10n.subLocationArea, _jobSubLocationController, theme),
                  if (_isAutoDetected)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Row(
                        children: [
                          Icon(Icons.location_on, size: 10, color: Colors.green.shade600),
                          const SizedBox(width: 4),
                          Text(
                            "📍 Auto-detected",
                            style: TextStyle(color: Colors.green.shade600, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  _buildJobField(l10n.experienceExample, _jobExperienceController, theme),
                  const SizedBox(height: 12),
                  _buildJobField(l10n.specificSkills, _jobSkillsController, theme),
                  ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    if (isWorker) {
                      _jobTitleController.text = tempSkill ?? '';
                      _isAvailabilityPost = true;
                      _isJobPost = false;
                    } else {
                      _isJobPost = true;
                      _isAvailabilityPost = false;
                    }
                  });
                  Navigator.pop(context);
                },
                child: Text(l10n.saveDetails)
              )
            ],
          );
        });
      }
    );
  }

  void _showEventDialog() {
    final titleCtrl = TextEditingController(text: _eventTitle);
    final locCtrl = TextEditingController(text: _eventLocation);
    final subLocCtrl = TextEditingController(text: _eventSubLocation);
    DateTime? tempDate = _eventDate;
    TimeOfDay? tempTime = _eventTime;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setDialogState) {
          final theme = Theme.of(context);
          final l10n = AppLocalizations.of(context)!;
          return AlertDialog(
            title: Text(l10n.addEventDetails, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: theme.colorScheme.onSurface)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   _buildJobField(l10n.eventTitle, titleCtrl, theme),
                   const SizedBox(height: 12),
                   _buildJobField(
                     l10n.location, 
                     locCtrl, 
                     theme,
                     readOnly: true,
                     suffixIcon: _isDetectingLocation 
                       ? const Padding(
                           padding: EdgeInsets.all(12.0),
                           child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                         )
                       : IconButton(
                           icon: const Icon(Icons.my_location),
                           onPressed: () => _autoDetectLocation(
                             onDetected: (loc, sub) {
                               setDialogState(() {
                                 locCtrl.text = loc;
                                 subLocCtrl.text = sub;
                               });
                             },
                             onStateChanged: () => setDialogState(() {}),
                           ),
                         ),
                     onTap: () {
                       showModalBottomSheet(
                         context: context,
                         isScrollControlled: true,
                         backgroundColor: Colors.transparent,
                         builder: (context) => LocationPickerSheet(
                           onLocationSelected: (loc) {
                             setDialogState(() {
                               locCtrl.text = loc['city'] ?? loc['description'];
                               subLocCtrl.text = loc['subLocation'] ?? '';
                             });
                             setState(() {
                               _isAutoDetected = false;
                             });
                           },
                         ),
                       );
                     },
                   ),
                   if (_isAutoDetected)
                     Padding(
                       padding: const EdgeInsets.only(top: 4.0),
                       child: Row(
                         children: [
                           Icon(Icons.location_on, size: 10, color: Colors.green.shade600),
                           const SizedBox(width: 4),
                           Text(
                             "📍 Auto-detected",
                             style: TextStyle(color: Colors.green.shade600, fontSize: 10, fontWeight: FontWeight.bold),
                           ),
                         ],
                       ),
                     ),
                   const SizedBox(height: 12),
                   _buildJobField(l10n.subLocationArea, subLocCtrl, theme),
                   const SizedBox(height: 16),
                   ListTile(
                     contentPadding: EdgeInsets.zero,
                     title: Text(tempDate == null ? l10n.selectDate : '${tempDate!.day}/${tempDate!.month}/${tempDate!.year}'),
                     trailing: const Icon(Icons.calendar_today),
                     onTap: () async {
                       final dt = await showDatePicker(context: context, initialDate: tempDate ?? DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2030));
                       if (dt != null) setDialogState(() => tempDate = dt);
                     },
                   ),
                   ListTile(
                     contentPadding: EdgeInsets.zero,
                     title: Text(tempTime == null ? l10n.selectTime : tempTime!.format(context)),
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
              TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _eventTitle = titleCtrl.text.trim();
                    _eventLocation = locCtrl.text.trim();
                    _eventSubLocation = subLocCtrl.text.trim();
                    _eventDate = tempDate;
                    _eventTime = tempTime;
                  });
                  Navigator.pop(context);
                },
                child: Text(l10n.saveEvent)
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

      if (widget.post != null) {
        // Updating existing post
        await PostService.updatePost(
          widget.post!['id'],
          {
            'text': desc,
            'location': (_isJobPost || _isAvailabilityPost) ? _jobLocationController.text.trim() : 'Current Location',
            'isJobPost': _isJobPost,
            'isAvailabilityPost': _isAvailabilityPost,
            'jobTitle': (_isJobPost || _isAvailabilityPost) ? _jobTitleController.text.trim() : null,
            'jobSalary': (_isJobPost || _isAvailabilityPost) ? _jobSalaryController.text.trim() : null,
            'jobExperience': (_isJobPost || _isAvailabilityPost) ? _jobExperienceController.text.trim() : null,
            'jobSkills': (_isJobPost || _isAvailabilityPost) ? _jobSkillsController.text.trim() : null,
            'subLocation': (_isJobPost || _isAvailabilityPost) ? _jobSubLocationController.text.trim() : null,
            'eventDate': _eventDate != null ? Timestamp.fromDate(_eventDate!) : null,
            'eventTime': _eventTime?.format(context),
            'eventLocation': _eventLocation,
            'eventSubLocation': _eventSubLocation,
            'eventTitle': _eventTitle,
            'visibility': _visibility,
            'media': [
              ..._existingMedia, // Keep existing media
            ],
          },
          isAdmin: auth.role == 'admin',
          newMediaFiles: _selectedMedia,
        );

        if (auth.role != 'admin' && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Post sent for re-approval after editing.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        // Creating new post
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
          subLocation: (_isJobPost || _isAvailabilityPost) ? _jobSubLocationController.text.trim() : null,
          companyName: _isJobPost ? (employerCompany?.isNotEmpty == true ? employerCompany : name) : null,
          eventDate: _eventDate,
          eventTime: _eventTime?.format(context),
          eventLocation: _eventLocation?.isNotEmpty == true ? _eventLocation : null,
          eventSubLocation: _eventSubLocation?.isNotEmpty == true ? _eventSubLocation : null,
          eventTitle: _eventTitle?.isNotEmpty == true ? _eventTitle : null,
          visibility: _visibility,
          isFeatured: isWorker 
              ? ref.read(workerProvider)?.isFeatured 
              : ref.read(employerProvider)?.isFeatured,
        );
      }

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

    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: theme.colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(widget.post != null ? 'Edit Post' : l10n.newPost, 
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
                : Text(l10n.post, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          if (widget.post != null && auth?.role != 'admin')
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.orange.withOpacity(0.1),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Note: Editing this post will require re-approval from moderators.',
                      style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
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
                        : l10n.whatDoYouWantToTalkAbout,
                      hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 18),
                      border: InputBorder.none,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Summary of special post type
                  if (_isJobPost || _isAvailabilityPost || _eventDate != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _eventDate != null ? Icons.event : (_isJobPost ? Icons.work : Icons.engineering),
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _eventDate != null ? 'Event: $_eventTitle' : (_isJobPost ? 'Job: ${_jobTitleController.text}' : 'Availability: ${_jobTitleController.text}'),
                                  style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                Text(
                                  _eventDate != null ? _eventLocation ?? '' : _jobLocationController.text,
                                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, size: 18),
                            onPressed: _eventDate != null ? _showEventDialog : _showAvailabilityDialog,
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () {
                              setState(() {
                                _isJobPost = false;
                                _isAvailabilityPost = false;
                                _eventDate = null;
                                _eventTitle = null;
                              });
                            },
                          ),
                        ],
                      ),
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
                  if (_existingMedia.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _existingMedia.asMap().entries.map((entry) {
                          final index = entry.key;
                          final mediaItem = entry.value;
                          final String url = mediaItem['url'];
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
                                      : Image.network(url, fit: BoxFit.cover),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => setState(() => _existingMedia.removeAt(index)),
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
                _buildToolbarItem(
                  isWorker ? Icons.engineering_outlined : Icons.work_outline, 
                  isWorker ? 'Availability' : 'Job', 
                  theme, 
                  _showAvailabilityDialog
                ),
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

  Widget _buildJobField(String hint, TextEditingController controller, ThemeData theme, {bool readOnly = false, VoidCallback? onTap, Widget? suffixIcon}) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 14),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
