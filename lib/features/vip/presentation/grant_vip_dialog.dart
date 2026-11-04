import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/config/app_config.dart';

class GrantVipDialog extends StatefulWidget {
  final Map<String, dynamic>? student;
  final VoidCallback onSaved;

  const GrantVipDialog({
    super.key,
    this.student,
    required this.onSaved,
  });

  @override
  State<GrantVipDialog> createState() => _GrantVipDialogState();
}

class _GrantVipDialogState extends State<GrantVipDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _emailController;
  late TextEditingController _daysController;

  String _selectedGrant = 'combo_all';
  int _selectedDays = 30;
  bool _isSaving = false;

  final Map<String, String> _grantPackages = {
    'combo_all': '🌟 অল-ইন-ওয়ান কম্বো (মক + ভিডিও)',
    'combo_sem3': '🌟 সেম ৩ কম্বো (মক + ভিডিও)',
    'combo_sem4': '🌟 সেম ৪ কম্বো (মক + ভিডিও)',
    'premium_mock_all': '📝 সমস্ত মক টেস্ট (সেম ৩ ও ৪)',
    'premium_mock_sem3': '📝 সেমিস্টার ৩ মক টেস্ট',
    'premium_mock_sem4': '📝 সেমিস্টার ৪ মক টেস্ট',
    'video_library_all': '🎥 সমস্ত ভিডিও লাইব্রেরি (সেম ৩ ও ৪)',
    'video_library_sem3': '🎥 সেমিস্টার ৩ ভিডিও লাইব্রেরি',
    'video_library_sem4': '🎥 সেমিস্টার ৪ ভিডিও লাইব্রেরি',
  };

  final List<int> _presetDays = [7, 30, 90, 180, 365];

  @override
  void initState() {
    super.initState();
    final email = widget.student?['email'] ?? '';
    _emailController = TextEditingController(text: email);
    _daysController = TextEditingController(text: '30');

    // Preselect grant if student already has one
    if (widget.student != null && widget.student!['entitlements'] is List) {
      final ents = widget.student!['entitlements'] as List;
      if (ents.isNotEmpty && _grantPackages.containsKey(ents.first.toString())) {
        _selectedGrant = ents.first.toString();
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _daysController.dispose();
    super.dispose();
  }

  DateTime _calculateExpiry() {
    final days = int.tryParse(_daysController.text.trim()) ?? _selectedDays;
    return DateTime.now().add(Duration(days: days));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final email = _emailController.text.trim().toLowerCase();
    final days = int.tryParse(_daysController.text.trim()) ?? 30;
    final now = DateTime.now();
    final expiry = now.add(Duration(days: days));

    String? targetUid = widget.student?['id'];

    // If target UID not provided directly, look up user by email
    if (targetUid == null || targetUid.isEmpty) {
      final allUsers = await ApiClient.getCollection(AppConfig.colUsers);
      final matched = allUsers.firstWhere(
        (u) => (u['email'] ?? '').toString().trim().toLowerCase() == email,
        orElse: () => {},
      );
      if (matched.isNotEmpty && matched['id'] != null) {
        targetUid = matched['id'].toString();
      }
    }

    if (targetUid == null || targetUid.isEmpty) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('এই ইমেইলের কোনো শিক্ষার্থী পাওয়া যায়নি! সঠিক ইমেইল দিন।'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
      return;
    }

    // Determine entitlements list based on package
    List<String> entitlementsList = [_selectedGrant];
    if (_selectedGrant == 'combo_all') {
      entitlementsList = [
        'combo_all',
        'premium_mock_all',
        'premium_mock_sem3',
        'premium_mock_sem4',
        'video_library_all',
        'video_library_sem3',
        'video_library_sem4'
      ];
    } else if (_selectedGrant == 'combo_sem3') {
      entitlementsList = ['combo_sem3', 'premium_mock_sem3', 'video_library_sem3'];
    } else if (_selectedGrant == 'combo_sem4') {
      entitlementsList = ['combo_sem4', 'premium_mock_sem4', 'video_library_sem4'];
    } else if (_selectedGrant == 'premium_mock_all') {
      entitlementsList = ['premium_mock_all', 'premium_mock_sem3', 'premium_mock_sem4'];
    } else if (_selectedGrant == 'video_library_all') {
      entitlementsList = ['video_library_all', 'video_library_sem3', 'video_library_sem4'];
    }

    final Map<String, dynamic> updatePayload = {
      'is_vip': true,
      'is_premium': true,
      'entitlements': entitlementsList,
      'vip_expires_at': expiry.toIso8601String(),
      'vip_granted_at': now.toIso8601String(),
      'vip_grant_type': _selectedGrant,
      'vip_days': days,
      'updated_at': now.toIso8601String(),
    };

    final success = await ApiClient.updateDocument(AppConfig.colUsers, targetUid, updatePayload);

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        widget.onSaved();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('সফলভাবে $days দিনের ভিআইপি সাবস্ক্রিপশন প্রদান করা হয়েছে!'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ভিআইপি প্রদান ব্যর্থ হয়েছে! ক্লাউড সংযোগ চেক করুন।'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  static Future<void> show(
    BuildContext context, {
    Map<String, dynamic>? student,
    required VoidCallback onSaved,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GrantVipDialog(
        student: student,
        onSaved: onSaved,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final expiry = _calculateExpiry();
    final expiryStr = DateFormat('dd MMM yyyy').format(expiry);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 38,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 12, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.workspace_premium_rounded, color: AppColors.warning, size: 22),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'ভিআইপি সাবস্ক্রিপশন প্রদান',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20, color: AppColors.textSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Student Email field
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'শিক্ষার্থীর ইমেইল (Student Email) *',
                            hintText: 'student@example.com',
                            prefixIcon: Icon(Icons.email_outlined, size: 20),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'শিক্ষার্থীর ইমেইল আবশ্যক' : null,
                        ),
                        const SizedBox(height: 14),

                        // Package dropdown
                        DropdownButtonFormField<String>(
                          value: _selectedGrant,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'সাবস্ক্রিপশন প্যাকেজ / অ্যাক্সেস *',
                            prefixIcon: Icon(Icons.stars_rounded, size: 20, color: AppColors.warning),
                          ),
                          items: _grantPackages.entries
                              .map((e) => DropdownMenuItem(
                                    value: e.key,
                                    child: Text(
                                      e.value,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedGrant = val);
                          },
                        ),
                        const SizedBox(height: 14),

                        // Duration section
                        const Text('মেয়াদকাল (সময়সীমা নির্ধারণ করুন):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _presetDays.map((d) {
                            final isSel = _selectedDays == d && _daysController.text == d.toString();
                            return ChoiceChip(
                              label: Text('$d দিন', style: TextStyle(fontSize: 12, fontWeight: isSel ? FontWeight.bold : FontWeight.normal, color: isSel ? Colors.white : AppColors.textPrimary)),
                              selected: isSel,
                              selectedColor: AppColors.primary,
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: isSel ? AppColors.primary : AppColors.border)),
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _selectedDays = d;
                                    _daysController.text = d.toString();
                                  });
                                }
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _daysController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'কাস্টম দিন সংখ্যা (Days)',
                            hintText: 'যেমন: 30',
                            prefixIcon: Icon(Icons.calendar_month_outlined, size: 20),
                          ),
                          onChanged: (_) => setState(() {}),
                          validator: (v) {
                            final n = int.tryParse(v?.trim() ?? '');
                            if (n == null || n <= 0) return 'সঠিক দিন সংখ্যা লিখুন';
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Expiry Preview Banner
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.warningLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.event_available, color: AppColors.warning, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'মেয়াদ শেষ হবে: $expiryStr পর্যন্ত',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFF92400E)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Grant Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _submit,
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                            child: _isSaving
                                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('ভিআইপি অ্যাক্টিভেট করুন', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
