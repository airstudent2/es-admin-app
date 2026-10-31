import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/config/app_config.dart';
import 'send_notification_dialog.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => NotificationsScreenState();
}

class NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    setState(() => _isLoading = true);
    final list = await ApiClient.getCollection(AppConfig.colNotifications);
    list.sort((a, b) => (b['createdAt'] ?? '').toString().compareTo((a['createdAt'] ?? '').toString()));
    if (mounted) {
      setState(() {
        _notifications = list;
        _isLoading = false;
      });
    }
  }

  String _formatDate(dynamic dateIso) {
    if (dateIso == null) return '—';
    try {
      final d = DateTime.parse(dateIso.toString());
      return DateFormat('dd MMM yyyy, hh:mm a').format(d);
    } catch (_) {
      return '—';
    }
  }

  Future<void> _deleteNotification(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('নোটিফিকেশন মুছে ফেলবেন?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: const Text('আপনি কি নিশ্চিত যে এই নোটিফিকেশন রেকর্ডটি সম্পূর্ণ মুছে ফেলতে চান?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('না, রাখুন', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('হ্যাঁ, মুছুন'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ApiClient.deleteDocument(AppConfig.colNotifications, id);
      if (success) {
        loadNotifications();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('নোটিফিকেশন সফলভাবে মুছে ফেলা হয়েছে'), backgroundColor: AppColors.success),
          );
        }
      }
    }
  }

  void _openSendDialog() {
    showDialog(
      context: context,
      builder: (_) => SendNotificationDialog(onSent: loadNotifications),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openSendDialog,
        backgroundColor: AppColors.primary,
        elevation: 3,
        icon: const Icon(Icons.campaign_rounded, color: Colors.white, size: 20),
        label: const Text('নোটিফিকেশন পাঠান', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5)),
      ),
      body: RefreshIndicator(
        onRefresh: loadNotifications,
        color: AppColors.primary,
        child: Column(
          children: [
            // Top Summary Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.notifications_active_rounded, size: 18, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        'পুশ নোটিফিকেশন ব্রডকাস্ট হিস্ট্রি (${_notifications.length})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),

            // Content List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _notifications.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.notifications_none_rounded, size: 56, color: AppColors.textMuted),
                                const SizedBox(height: 12),
                                const Text('এখনও কোনো নোটিফিকেশন পাঠানো হয়নি', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                                const SizedBox(height: 4),
                                const Text('শিক্ষার্থীদের কাছে যেকোনো জরুরি নোটিশ বা আপডেট পাঠাতে নিচের বাটনে ট্যাপ করুন।', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: _openSendDialog,
                                  icon: const Icon(Icons.campaign_rounded, size: 18),
                                  label: const Text('প্রথম নোটিফিকেশন পাঠান'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.only(left: 16, right: 16, top: 14, bottom: 90),
                          itemCount: _notifications.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = _notifications[index];
                            final aud = (item['audience'] ?? 'all').toString();
                            final audLabel = aud == 'all' ? 'সকল শিক্ষার্থী' : (aud == 'sem3' ? 'সেমিস্টার ৩' : 'সেমিস্টার ৪');
                            final dateStr = _formatDate(item['createdAt']);
                            final imgUrl = item['imageUrl'] as String?;

                            Color audBg = const Color(0xFFEFF6FF);
                            Color audText = const Color(0xFF1D4ED8);
                            Color audBorder = const Color(0xFFBFDBFE);
                            if (aud == 'sem3') {
                              audBg = const Color(0xFFFAF5FF);
                              audText = const Color(0xFF7E22CE);
                              audBorder = const Color(0xFFE9D5FF);
                            } else if (aud == 'sem4') {
                              audBg = const Color(0xFFEEF2FF);
                              audText = const Color(0xFF3730A3);
                              audBorder = const Color(0xFFC7D2FE);
                            }

                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                          decoration: BoxDecoration(
                                            color: audBg,
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: audBorder),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.groups_rounded, size: 12, color: audText),
                                              const SizedBox(width: 4),
                                              Text(audLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: audText)),
                                            ],
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Text(dateStr, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                            const SizedBox(width: 4),
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.textMuted),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                              tooltip: 'মুছুন',
                                              onPressed: () => _deleteNotification(item['id']),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      item['title'] ?? 'শিরোনামহীন',
                                      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary, height: 1.25),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item['body'] ?? item['message'] ?? '',
                                      style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.4),
                                    ),
                                    if (imgUrl != null && imgUrl.isNotEmpty) ...[
                                      const SizedBox(height: 10),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: CachedNetworkImage(
                                          imageUrl: imgUrl,
                                          height: 140,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          placeholder: (_, __) => Container(color: Colors.black12, height: 140),
                                          errorWidget: (_, __, ___) => const SizedBox.shrink(),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
