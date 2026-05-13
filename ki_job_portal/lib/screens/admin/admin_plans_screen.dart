import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../models/subscription_plan_model.dart';
import '../../providers/subscription_provider.dart';

class AdminPlansScreen extends ConsumerStatefulWidget {
  const AdminPlansScreen({super.key});

  @override
  ConsumerState<AdminPlansScreen> createState() => _AdminPlansScreenState();
}

class _AdminPlansScreenState extends ConsumerState<AdminPlansScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('Plans & Packs Manager',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Subscription Plans'),
            Tab(text: 'Credit Packs'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _SubscriptionPlansTab(),
          _CreditPacksTab(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Subscription Plans Tab
// ─────────────────────────────────────────────────────────────────────────────
class _SubscriptionPlansTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(subscriptionPlansProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: plansAsync.when(
        data: (plans) {
          if (plans.isEmpty) {
            return _emptyState('No subscription plans yet.\nTap + to add one.');
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: plans.length,
            itemBuilder: (ctx, i) => _PlanTile(plan: plans[i]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPlanDialog(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _emptyState(String msg) => Center(
        child: Text(msg,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 16)),
      );

  void _showPlanDialog(BuildContext context, {SubscriptionPlan? plan}) {
    showDialog(
      context: context,
      builder: (_) => _PlanDialog(plan: plan),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Subscription Plan Card
// ─────────────────────────────────────────────────────────────────────────────
class _PlanTile extends StatelessWidget {
  final SubscriptionPlan plan;
  const _PlanTile({required this.plan});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(plan.name,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold)),
                ),
                if (plan.badgeLabel != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _hexColor(plan.badgeColor, fallback: Colors.red),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(plan.badgeLabel!,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text('₹${plan.price} / ${plan.durationDays} days',
                style: const TextStyle(
                    color: Colors.grey, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _chip(
                  plan.limitType == kLimitTypeCredits
                      ? '${plan.credits} Credits'
                      : 'Limits mode',
                  plan.limitType == kLimitTypeCredits
                      ? Colors.amber
                      : Colors.blue,
                ),
                if (plan.limitType == kLimitTypeLimits) ...[
                  _chip(
                    plan.maxContactUnlocks == null
                        ? '∞ Contacts'
                        : '${plan.maxContactUnlocks} Contacts',
                    Colors.teal,
                  ),
                  _chip(
                    plan.maxJobApplications == null
                        ? '∞ Applications'
                        : '${plan.maxJobApplications} Applications',
                    Colors.indigo,
                  ),
                  _chip(
                    plan.maxHires == null
                        ? '∞ Hires'
                        : '${plan.maxHires} Hires',
                    Colors.purple,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                  onPressed: () =>
                      showDialog(context: context, builder: (_) => _PlanDialog(plan: plan)),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                  label: const Text('Delete', style: TextStyle(color: Colors.red)),
                  onPressed: () => _confirmDelete(context, plan.id, 'subscription_plans'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.bold)),
      );

  Color _hexColor(String? hex, {required Color fallback}) {
    if (hex == null || hex.isEmpty) return fallback;
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return fallback;
    }
  }

  void _confirmDelete(BuildContext context, String id, String collection) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Plan?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              FirebaseFirestore.instance.collection(collection).doc(id).delete();
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add / Edit Plan Dialog
// ─────────────────────────────────────────────────────────────────────────────
class _PlanDialog extends StatefulWidget {
  final SubscriptionPlan? plan;
  const _PlanDialog({this.plan});

  @override
  State<_PlanDialog> createState() => _PlanDialogState();
}

class _PlanDialogState extends State<_PlanDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _name, _price, _duration, _credits;
  late TextEditingController _maxContacts, _maxApplications, _maxHires;
  late TextEditingController _badgeLabel, _badgeColor;
  late TextEditingController _features, _color;
  String _limitType = kLimitTypeLimits;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.plan;
    _name = TextEditingController(text: p?.name ?? '');
    _price = TextEditingController(text: p?.price.toString() ?? '');
    _duration = TextEditingController(text: p?.durationDays.toString() ?? '30');
    _credits = TextEditingController(text: p?.credits.toString() ?? '0');
    _maxContacts = TextEditingController(text: p?.maxContactUnlocks?.toString() ?? '');
    _maxApplications = TextEditingController(text: p?.maxJobApplications?.toString() ?? '');
    _maxHires = TextEditingController(text: p?.maxHires?.toString() ?? '');
    _badgeLabel = TextEditingController(text: p?.badgeLabel ?? '');
    _badgeColor = TextEditingController(text: p?.badgeColor ?? '#F43F5E');
    _features = TextEditingController(text: p?.features.join('\n') ?? '');
    _color = TextEditingController(text: p?.color ?? '#1D4ED8');
    _limitType = p?.limitType ?? kLimitTypeLimits;
  }

  @override
  void dispose() {
    for (final c in [_name, _price, _duration, _credits, _maxContacts,
        _maxApplications, _maxHires, _badgeLabel, _badgeColor, _features, _color]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final featuresList = _features.text
        .split('\n')
        .map((f) => f.trim())
        .where((f) => f.isNotEmpty)
        .toList();

    final data = <String, dynamic>{
      'name': _name.text.trim(),
      'price': int.tryParse(_price.text) ?? 0,
      'durationDays': int.tryParse(_duration.text) ?? 30,
      'limitType': _limitType,
      'credits': int.tryParse(_credits.text) ?? 0,
      'maxApplicationsPerDay': int.tryParse(_maxApplications.text) ?? 0,
      'features': featuresList,
      'color': _color.text.trim(),
      'description': '',
      'badgeLabel': _badgeLabel.text.trim().isEmpty ? null : _badgeLabel.text.trim(),
      'badgeColor': _badgeColor.text.trim().isEmpty ? null : _badgeColor.text.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // Limits mode quotas
    if (_limitType == kLimitTypeLimits) {
      data['maxContactUnlocks'] = int.tryParse(_maxContacts.text);
      data['maxJobApplications'] = int.tryParse(_maxApplications.text);
      data['maxHires'] = int.tryParse(_maxHires.text);
    } else {
      // Credits mode — remove limit fields
      data['maxContactUnlocks'] = null;
      data['maxJobApplications'] = null;
      data['maxHires'] = null;
    }

    final collection = FirebaseFirestore.instance.collection('subscription_plans');
    if (widget.plan != null) {
      await collection.doc(widget.plan!.id).update(data);
    } else {
      data['createdAt'] = FieldValue.serverTimestamp();
      await collection.add(data);
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plan saved!'), backgroundColor: Colors.green),
      );
    }
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.plan == null ? 'Add Subscription Plan' : 'Edit Plan'),
      contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _field(_name, 'Plan Name', required: true),
                _field(_price, 'Price (₹)', keyboardType: TextInputType.number, required: true),
                _field(_duration, 'Duration (days)', keyboardType: TextInputType.number, required: true),

                const SizedBox(height: 16),
                const Text('Limit Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: kLimitTypeLimits, label: Text('Quotas'), icon: Icon(Icons.block, size: 16)),
                    ButtonSegment(value: kLimitTypeCredits, label: Text('Credits'), icon: Icon(Icons.bolt, size: 16)),
                  ],
                  selected: {_limitType},
                  onSelectionChanged: (s) => setState(() => _limitType = s.first),
                  style: ButtonStyle(
                    foregroundColor: WidgetStateProperty.resolveWith((s) =>
                        s.contains(WidgetState.selected) ? Colors.white : Colors.grey[700]),
                    backgroundColor: WidgetStateProperty.resolveWith((s) =>
                        s.contains(WidgetState.selected) ? AppColors.primary : Colors.grey[100]),
                  ),
                ),
                const SizedBox(height: 16),

                if (_limitType == kLimitTypeCredits) ...[
                  _field(_credits, 'Credits to grant on purchase', keyboardType: TextInputType.number),
                ] else ...[
                  const Text('Quotas per period (leave empty = unlimited)',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 8),
                  _field(_maxContacts, 'Max Contact Unlocks', keyboardType: TextInputType.number),
                  _field(_maxApplications, 'Max Job Applications', keyboardType: TextInputType.number),
                  _field(_maxHires, 'Max Hires', keyboardType: TextInputType.number),
                ],

                const Divider(height: 24),
                const Text('Admin Badge (optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 4),
                const Text('Displayed as a tag on the plan card (e.g. "Most Popular")',
                    style: TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 8),
                _field(_badgeLabel, 'Badge Label (e.g. Most Popular, Best Value)'),
                _field(_badgeColor, 'Badge Color (hex, e.g. #F43F5E)'),

                const Divider(height: 24),
                _field(
                  _features,
                  'Features (one per line)',
                  maxLines: 5,
                ),
                _field(_color, 'Plan Card Color (hex)'),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: _saving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Save', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label, {
    TextInputType keyboardType = TextInputType.text,
    bool required = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          isDense: true,
        ),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
            : null,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Credit Packs Tab
// ─────────────────────────────────────────────────────────────────────────────
class _CreditPacksTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packsAsync = ref.watch(creditPacksProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: packsAsync.when(
        data: (packs) {
          if (packs.isEmpty) {
            return Center(
              child: Text('No credit packs yet.\nTap + to add one.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 16)),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: packs.length,
            itemBuilder: (ctx, i) => _PackTile(pack: packs[i]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showDialog(context: context, builder: (_) => const _PackDialog()),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _PackTile extends StatelessWidget {
  final Map<String, dynamic> pack;
  const _PackTile({required this.pack});

  @override
  Widget build(BuildContext context) {
    final id = pack['id'] as String;
    final credits = pack['credits'] ?? 0;
    final price = pack['price'] ?? 0;
    final bonusText = pack['bonusText'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.bolt_rounded, color: AppColors.primary),
        ),
        title: Text('$credits Credits',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('₹$price', style: const TextStyle(color: Colors.grey)),
            if (bonusText.isNotEmpty)
              Text(bonusText, style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => showDialog(context: context, builder: (_) => _PackDialog(pack: pack)),
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
              onPressed: () => _confirmDelete(context, id),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Pack?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              FirebaseFirestore.instance.collection('credit_bundles').doc(id).delete();
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _PackDialog extends StatefulWidget {
  final Map<String, dynamic>? pack;
  const _PackDialog({this.pack});

  @override
  State<_PackDialog> createState() => _PackDialogState();
}

class _PackDialogState extends State<_PackDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _credits, _price, _bonus;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.pack;
    _credits = TextEditingController(text: p?['credits']?.toString() ?? '');
    _price = TextEditingController(text: p?['price']?.toString() ?? '');
    _bonus = TextEditingController(text: p?['bonusText'] ?? '');
  }

  @override
  void dispose() {
    _credits.dispose();
    _price.dispose();
    _bonus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final data = {
      'credits': int.tryParse(_credits.text) ?? 0,
      'price': int.tryParse(_price.text) ?? 0,
      'bonusText': _bonus.text.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final col = FirebaseFirestore.instance.collection('credit_bundles');
    if (widget.pack != null) {
      await col.doc(widget.pack!['id']).update(data);
    } else {
      data['createdAt'] = FieldValue.serverTimestamp();
      await col.add(data);
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Credit pack saved!'), backgroundColor: Colors.green),
      );
    }
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.pack == null ? 'Add Credit Pack' : 'Edit Credit Pack'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _credits,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Credits', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _price,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Price (₹)', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _bonus,
              decoration: const InputDecoration(
                  labelText: 'Bonus Text (optional, e.g. "+50 Free Credits")',
                  border: OutlineInputBorder()),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: _saving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Save', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
