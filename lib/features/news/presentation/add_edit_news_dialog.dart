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

  static Future<void> show(
    BuildContext context, {
    Map<String, dynamic>? initialData,
    required VoidCallback onSaved,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddEditNewsDialog(
        initialData: initialData,
        onSaved: onSaved,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialData != null;
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
                    Expanded(
                      child: Text(
                        isEdit ? 'নিউজ স্লাইডার পরিমার্জন' : 'নতুন ব্যানার স্লাইডার',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

                        DropdownButtonFormField<String>(
                          value: _selectedTag,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'ট্যাগ (Tag)'),
                          items: _tags.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)))).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedTag = val);
                          },
                        ),
                        const SizedBox(height: 14),

                        DropdownButtonFormField<int>(
                          value: _selectedSemester,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'টার্গেট সেমিস্টার'),
                          items: const [
                            DropdownMenuItem(value: 0, child: Text('সমস্ত সেমিস্টার (All)', style: TextStyle(fontSize: 13))),
                            DropdownMenuItem(value: 3, child: Text('সেমিস্টার ৩', style: TextStyle(fontSize: 13))),
                            DropdownMenuItem(value: 4, child: Text('সেমিস্টার ৪', style: TextStyle(fontSize: 13))),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedSemester = val);
                          },
                        ),
                        const SizedBox(height: 14),

                        TextFormField(
                          controller: _imageUrlController,
                          decoration: const InputDecoration(labelText: 'ছবি / ব্যানারের URL *', hintText: 'https://images.unsplash.com/...'),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'ছবির লিংক আবশ্যক' : null,
                        ),
                        const SizedBox(height: 14),

                        TextFormField(
                          controller: _redirectUrlController,
                          decoration: const InputDecoration(labelText: 'রিডাইরেক্ট লিংক (ঐচ্ছিক)', hintText: 'https://wa.me/...'),
                        ),
                        const SizedBox(height: 14),

                        TextFormField(
                          controller: _orderController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'ক্রমিক নং (Order Number)', hintText: '1'),
                        ),
                        const SizedBox(height: 14),

                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Expanded(
                                child: Text('ব্যানার সক্রিয় থাকবে (Active)?', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              ),
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
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _save,
                            child: _isSaving
                                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : Text(isEdit ? 'পরিবর্তন সংরক্ষণ করুন' : 'ব্যানার যুক্ত করুন', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
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
