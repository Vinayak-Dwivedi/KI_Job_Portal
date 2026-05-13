import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ki_job_portal/models/promotion_model.dart';
import 'package:ki_job_portal/providers/promotions_provider.dart';
import 'package:ki_job_portal/core/theme/app_colors.dart';

class AdminPromotionsScreen extends ConsumerStatefulWidget {
  const AdminPromotionsScreen({super.key});

  @override
  ConsumerState<AdminPromotionsScreen> createState() => _AdminPromotionsScreenState();
}

class _AdminPromotionsScreenState extends ConsumerState<AdminPromotionsScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _targetPlanIdController = TextEditingController();
  final _targetUrlController = TextEditingController();
  bool _isActive = true;
  bool _isSaving = false;

  void _resetForm() {
    _titleController.clear();
    _descController.clear();
    _imageUrlController.clear();
    _targetPlanIdController.clear();
    _targetUrlController.clear();
    setState(() => _isActive = true);
  }

  Future<void> _savePromotion({String? id}) async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title is required')));
      return;
    }

    setState(() => _isSaving = true);
    try {
      final data = {
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'imageUrl': _imageUrlController.text.trim().isEmpty ? null : _imageUrlController.text.trim(),
        'targetPlanId': _targetPlanIdController.text.trim().isEmpty ? null : _targetPlanIdController.text.trim(),
        'targetUrl': _targetUrlController.text.trim().isEmpty ? null : _targetUrlController.text.trim(),
        'isActive': _isActive,
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (id != null) {
        await FirebaseFirestore.instance.collection('promotions').doc(id).update(data);
      } else {
        await FirebaseFirestore.instance.collection('promotions').add(data);
      }

      Navigator.pop(context);
      _resetForm();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Promotion saved successfully')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showAddDialog({PromotionModel? promotion}) {
    if (promotion != null) {
      _titleController.text = promotion.title;
      _descController.text = promotion.description;
      _imageUrlController.text = promotion.imageUrl ?? '';
      _targetPlanIdController.text = promotion.targetPlanId ?? '';
      _targetUrlController.text = promotion.targetUrl ?? '';
      _isActive = promotion.isActive;
    } else {
      _resetForm();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 20,
          left: 20,
          right: 20,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                promotion == null ? 'Add Promotion/Ad' : 'Edit Promotion',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _imageUrlController,
                decoration: const InputDecoration(labelText: 'Image URL (optional)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _targetPlanIdController,
                decoration: const InputDecoration(labelText: 'Target Plan ID (optional)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _targetUrlController,
                decoration: const InputDecoration(labelText: 'External Target URL (optional)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Is Active'),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : () => _savePromotion(id: promotion?.id),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: _isSaving 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Save Promotion', style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final promotionsAsync = ref.watch(promotionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Promotions'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: promotionsAsync.when(
        data: (promotions) {
          if (promotions.isEmpty) {
            return const Center(child: Text('No active promotions.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: promotions.length,
            itemBuilder: (context, index) {
              final promo = promotions[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: promo.imageUrl != null 
                      ? Image.network(promo.imageUrl!, width: 50, height: 50, fit: BoxFit.cover)
                      : const Icon(Icons.campaign, size: 40),
                  title: Text(promo.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(promo.description, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit), onPressed: () => _showAddDialog(promotion: promo)),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => FirebaseFirestore.instance.collection('promotions').doc(promo.id).delete(),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, __) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
