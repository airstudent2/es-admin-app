import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/config/app_config.dart';

class AddEditNewsDialog extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final VoidCallback onSaved;

  const AddEditNewsDialog({
    super.key,
    this.initialData,
    required this.onSaved,
  });

  @override
  State<AddEditNewsDialog> createState() => _AddEditNewsDialogState();
}

class _AddEditNewsDialogState extends State<AddEditNewsDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _subtitleController;
  late TextEditingController _imageUrlController;
  late TextEditingController _redirectUrlController;
  late TextEditingController _orderController;

  String _selectedTag = 'LATEST NEWS';
  int _selectedSemester = 0;
  bool _isActive = true;
  bool _isSaving = false;

  final List<String> _tags = ['LATEST NEWS', 'NOTICE', 'EXAM', 'UPDATE'];

  @override
  void initState() {
    super.initState();
    final d = widget.initialData;
    _titleController = TextEditingController(text: d?['title'] ?? '');
    _subtitleController = TextEditingController(text: d?['subtitle'] ?? '');
    _imageUrlController = TextEditingController(text: d?['imageUrl'] ?? '');
    _redirectUrlController = TextEditingController(text: d?['redirectUrl'] ?? '');
    _orderController = TextEditingController(text: (d?['order'] ?? 1).toString());

    if (d != null) {
      if (_tags.contains(d['tag'])) _selectedTag = d['tag'];
      _selectedSemester = d['targetSemester'] is int ? d['targetSemester'] : (int.tryParse(d['targetSemester']?.toString() ?? '0') ?? 0);
      _isActive = d['isActive'] != false;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _imageUrlController.dispose();
    _redirectUrlController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final payload = {
      'title': _titleController.text.trim(),
      'subtitle': _subtitleController.text.trim(),
      'tag': _selectedTag,
      'targetSemester': _selectedSemester,
      'imageUrl': _imageUrlController.text.trim(),
      'redirectUrl': _redirectUrlController.text.trim(),
      'order': int.tryParse(_orderController.text.trim()) ?? 1,
      'isActive': _isActive,
      'updatedAt': DateTime.now().toIso8601String(),
    };

    bool success;
    if (widget.initialData != null && widget.initialData!['id'] != null) {
      success = await ApiClient.updateDocument(AppConfig.colNews, widget.initialData!['id'], payload);
    } else {
      payload['createdAt'] = DateTime.now().toIso8601String();
      success = await ApiClient.createDocument(AppConfig.colNews, payload);
    }

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        widget.onSaved();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.initialData != null ? 'স্লাইডার আপডেট করা হয়েছে' : 'নতুন ব্যানার সফলভাবে যুক্ত হয়েছে!'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('সংরক্ষণ ব্যর্থ হয়েছে! ইন্টারনেট চেক করুন।'),
            backgroundColor: AppColors.danger,
          ),
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
                      isEdit ? 'নিউজ স্লাইডার পরিমার্জন' : 'নতুন ব্যানার স্লাইডার',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20, color: AppColors.textSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(height: 20, color: AppColors.border),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'শিরোনাম (Title) *', hintText: 'যেমন: পরীক্ষার বিশেষ প্রস্তুতি রুটিন...'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'শিরোনাম আবশ্যক' : null,
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _subtitleController,
                  decoration: const InputDecoration(labelText: 'উপ-শিরোনাম (Subtitle / বর্ণনা)', hintText: 'সংক্ষিপ্ত বিবরণ...'),
                  maxLines: 2,
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedTag,
                        decoration: const InputDecoration(labelText: 'ট্যাগ (Tag)'),
                        items: _tags.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)))).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedTag = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _selectedSemester,
                        decoration: const InputDecoration(labelText: 'টার্গেট সেমিস্টার'),
                        items: const [
                          DropdownMenuItem(value: 0, child: Text('সমস্ত সেমিস্টার', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 3, child: Text('সেমিস্টার ৩', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 4, child: Text('সেমিস্টার ৪', style: TextStyle(fontSize: 12))),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedSemester = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _imageUrlController,
                  decoration: const InputDecoration(labelText: 'ছবি / ব্যানারের URL *', hintText: 'https://images.unsplash.com/...'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'ছবির লিংক আবশ্যক' : null,
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _redirectUrlController,
                        decoration: const InputDecoration(labelText: 'রিডাইরেক্ট লিংক (ঐচ্ছিক)', hintText: 'https://wa.me/...'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: _orderController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'ক্রমিক নং'),
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
                      const Text('ব্যানার সক্রিয় থাকবে (Active)?', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      Switch(
                        value: _isActive,
                        activeColor: AppColors.success,
                        onChanged: (val) => setState(() => _isActive = val),
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
                        : Text(isEdit ? 'পরিবর্তন সংরক্ষণ করুন' : 'ব্যানার যুক্ত করুন'),
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
