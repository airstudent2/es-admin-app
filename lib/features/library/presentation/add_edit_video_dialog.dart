import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/config/app_config.dart';

class AddEditVideoDialog extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final int defaultSemester;
  final String defaultSubjectId;
  final VoidCallback onSaved;

  const AddEditVideoDialog({
    super.key,
    this.initialData,
    this.defaultSemester = 3,
    this.defaultSubjectId = 'bengali',
    required this.onSaved,
  });

  @override
  State<AddEditVideoDialog> createState() => _AddEditVideoDialogState();
}

class _AddEditVideoDialogState extends State<AddEditVideoDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _topicController;
  late TextEditingController _youtubeUrlController;
  late TextEditingController _orderController;

  late int _selectedSemester;
  late String _selectedSubjectId;
  bool _isFree = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final d = widget.initialData;
    _titleController = TextEditingController(text: d?['title'] ?? '');
    _topicController = TextEditingController(text: d?['topicName'] ?? d?['topic'] ?? '');
    _youtubeUrlController = TextEditingController(text: d?['youtubeUrl'] ?? d?['youtubeVideoId'] ?? '');
    _orderController = TextEditingController(text: (d?['order'] ?? 1).toString());

    _selectedSemester = d != null ? (int.tryParse(d['semester']?.toString() ?? '3') ?? 3) : widget.defaultSemester;
    _selectedSubjectId = d != null ? (d['subjectId'] ?? widget.defaultSubjectId) : widget.defaultSubjectId;
    _isFree = d?['isFree'] == true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _topicController.dispose();
    _youtubeUrlController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  String _extractYoutubeId(String input) {
    final trimmed = input.trim();
    final regExp = RegExp(r'(?:youtu\.be\/|youtube\.com\/(?:embed\/|v\/|watch\?v=|watch\?.+&v=))([\w-]{11})');
    final match = regExp.firstMatch(trimmed);
    if (match != null && match.groupCount >= 1) {
      return match.group(1)!;
    }
    if (RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(trimmed)) {
      return trimmed;
    }
    return trimmed;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final rawUrl = _youtubeUrlController.text.trim();
    final videoId = _extractYoutubeId(rawUrl);

    final payload = {
      'title': _titleController.text.trim(),
      'topicName': _topicController.text.trim(),
      'topic': _topicController.text.trim(),
      'subjectId': _selectedSubjectId,
      'semester': _selectedSemester,
      'youtubeUrl': rawUrl,
      'youtubeVideoId': videoId,
      'thumbnailUrl': 'https://img.youtube.com/vi/$videoId/hqdefault.jpg',
      'order': int.tryParse(_orderController.text.trim()) ?? 1,
      'isFree': _isFree,
      'updatedAt': DateTime.now().toIso8601String(),
    };

    bool success;
    if (widget.initialData != null && widget.initialData!['id'] != null) {
      success = await ApiClient.updateDocument(AppConfig.colVideos, widget.initialData!['id'], payload);
    } else {
      payload['createdAt'] = DateTime.now().toIso8601String();
      success = await ApiClient.createDocument(AppConfig.colVideos, payload);
    }

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        widget.onSaved();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.initialData != null ? 'ক্লাস ভিডিও পরিমার্জিত হয়েছে' : 'নতুন ক্লাস সফলভাবে যুক্ত হয়েছে!'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('সংরক্ষণ ব্যর্থ হয়েছে! ক্লাউড চেক করুন।'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialData != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEdit ? 'ক্লাস ভিডিও সম্পাদনা' : 'নতুন ভিডিও ক্লাস যুক্ত করুন',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20, color: AppColors.textSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(height: 20, color: AppColors.border),
                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _selectedSemester,
                        decoration: const InputDecoration(labelText: 'সেমিস্টার *'),
                        items: const [
                          DropdownMenuItem(value: 3, child: Text('সেমিস্টার ৩', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
                          DropdownMenuItem(value: 4, child: Text('সেমিস্টার ৪', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedSemester = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedSubjectId,
                        decoration: const InputDecoration(labelText: 'বিষয় *'),
                        items: const [
                          DropdownMenuItem(value: 'bengali', child: Text('বাংলা', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
                          DropdownMenuItem(value: 'english', child: Text('English', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedSubjectId = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'ক্লাসের শিরোনাম *', hintText: 'যেমন: কে বাঁচায়, কে বাঁচে - লাইন বাই লাইন বিশ্লেষণ'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'শিরোনাম আবশ্যক' : null,
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _topicController,
                  decoration: const InputDecoration(labelText: 'অধ্যায় / টপিকের নাম', hintText: 'যেমন: কে বাঁচায় কে বাঁচে'),
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _youtubeUrlController,
                  decoration: const InputDecoration(
                    labelText: 'ইউটিউব ভিডিও লিংক বা আইডি *',
                    hintText: 'https://youtube.com/watch?v=... বা 11 অক্ষরের আইডি',
                    prefixIcon: Icon(Icons.play_circle_fill, color: Colors.red),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'ইউটিউব লিংক আবশ্যক' : null,
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _orderController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'ক্রমিক নং', prefixIcon: Icon(Icons.format_list_numbered, size: 18)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ফ্রি ভিডিও ক্লাস (Free for All)?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text('অন থাকলে সবাই দেখতে পারবে, অফ থাকলে ভিআইপি লাগবে', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        ],
                      ),
                      Switch(
                        value: _isFree,
                        activeColor: AppColors.success,
                        onChanged: (val) => setState(() => _isFree = val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    child: _isSaving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(isEdit ? 'পরিবর্তন সংরক্ষণ করুন' : 'ক্লাস যুক্ত করুন'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
