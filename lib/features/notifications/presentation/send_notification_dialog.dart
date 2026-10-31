import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/config/app_config.dart';

class SendNotificationDialog extends StatefulWidget {
  final VoidCallback onSent;

  const SendNotificationDialog({super.key, required this.onSent});

  @override
  State<SendNotificationDialog> createState() => _SendNotificationDialogState();
}

class _SendNotificationDialogState extends State<SendNotificationDialog> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _actionUrlController = TextEditingController();

  String _selectedAudience = 'all'; // 'all', 'sem3', 'sem4'
  bool _isSending = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _imageUrlController.dispose();
    _actionUrlController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSending = true);

    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    final imgUrl = _imageUrlController.text.trim();
    final actionUrl = _actionUrlController.text.trim();
    final nowIso = DateTime.now().toIso8601String();

    final sem = _selectedAudience == 'sem3' ? 3 : (_selectedAudience == 'sem4' ? 4 : 0);

    final payload = {
      'title': title,
      'body': body,
      'message': body,
      'imageUrl': imgUrl.isNotEmpty ? imgUrl : null,
      'audience': _selectedAudience,
      'targetSemester': sem,
      'actionUrl': actionUrl.isNotEmpty ? actionUrl : null,
      'isActive': true,
      'createdAt': nowIso,
    };

    // Broadcast via FCM v1 Push API (Status Bar), Firestore, and Realtime Database
    final pushFuture = ApiClient.sendPushNotification(
      title: title,
      body: body,
      audience: _selectedAudience,
      imageUrl: imgUrl.isNotEmpty ? imgUrl : null,
      actionUrl: actionUrl.isNotEmpty ? actionUrl : null,
    );
    final firestoreFuture = ApiClient.createDocument(AppConfig.colNotifications, payload);
    final rtdbFuture = ApiClient.broadcastRtdbNotification(payload);

    final results = await Future.wait([pushFuture, firestoreFuture, rtdbFuture]);
    final success = results[0] || results[1] || results[2];

    if (mounted) {
      setState(() => _isSending = false);
      if (success) {
        widget.onSent();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('নোটিফিকেশন সফলভাবে সমস্ত শিক্ষার্থীর কাছে ব্রডকাস্ট হয়েছে!'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('নোটিফিকেশন পাঠানো ব্যর্থ হয়েছে! ক্লাউড কানেকশন চেক করুন।'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    const Row(
                      children: [
                        Icon(Icons.campaign, color: AppColors.primary, size: 24),
                        SizedBox(width: 8),
                        Text('নতুন পুশ নোটিফিকেশন', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20, color: AppColors.textSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(height: 20, color: AppColors.border),
                const SizedBox(height: 8),

                // Audience selector
                DropdownButtonFormField<String>(
                  value: _selectedAudience,
                  decoration: const InputDecoration(labelText: 'টার্গেট প্রাপক (Audience) *', prefixIcon: Icon(Icons.groups, size: 20)),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('সকল শিক্ষার্থী (All Semesters)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                    DropdownMenuItem(value: 'sem3', child: Text('শুধুমাত্র সেমিস্টার ৩ শিক্ষার্থী', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                    DropdownMenuItem(value: 'sem4', child: Text('শুধুমাত্র সেমিস্টার ৪ শিক্ষার্থী', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedAudience = val);
                  },
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _titleController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(labelText: 'নোটিফিকেশন শিরোনাম *', hintText: 'যেমন: নতুন মক টেস্ট বা সাজেস্টিভ নোটস প্রকাশ!'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'শিরোনাম আবশ্যক' : null,
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _bodyController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(labelText: 'বার্তার বিবরণ *', hintText: 'শিক্ষার্থীদের জন্য বিস্তারিত নোটিশ...'),
                  maxLines: 3,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'বার্তার বিবরণ আবশ্যক' : null,
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _imageUrlController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(labelText: 'ব্যানার / ছবির লিংক (ঐচ্ছিক)', hintText: 'https://images.unsplash.com/...', prefixIcon: Icon(Icons.image, size: 20)),
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _actionUrlController,
                  decoration: const InputDecoration(labelText: 'অ্যাকশন লিংক (ঐচ্ছিক)', hintText: 'https://... বা অ্যাপের ভেতরের স্ক্রিন লিংক', prefixIcon: Icon(Icons.link, size: 20)),
                ),
                const SizedBox(height: 18),

                // Live Phone Notification Preview
                const Text('লাইভ মোবাইল প্রিভিউ:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(6)),
                            child: const Icon(Icons.notifications, color: Colors.white, size: 12),
                          ),
                          const SizedBox(width: 6),
                          const Text('Es Bangla • এখনই', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _titleController.text.trim().isNotEmpty ? _titleController.text.trim() : 'সেমিস্টার ৩ এর নতুন সাজেস্টিভ নোটস প্রকাশ!',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _bodyController.text.trim().isNotEmpty ? _bodyController.text.trim() : 'অধ্যায়ভিত্তিক সমস্ত সাজেস্টিভ নোটস ও প্র্যাকটিস সেট অ্যাপে যুক্ত হয়েছে...',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      if (_imageUrlController.text.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: _imageUrlController.text.trim(),
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => const SizedBox.shrink(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Broadcast Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isSending ? null : _send,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    child: _isSending
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.send_rounded, size: 18),
                              SizedBox(width: 8),
                              Text('ব্রডকাস্ট করুন', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                            ],
                          ),
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
