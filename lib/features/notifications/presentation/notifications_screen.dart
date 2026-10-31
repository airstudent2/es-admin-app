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
        title: const Text('নোটিফিকেশন মুছে ফেলবেন?'),
        content: const Text('আপনি কি নিশ্চিত যে এই নোটিফিকেশন রেকর্ডটি সম্পূর্ণ মুছে ফেলতে চান?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('না')),
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
            const SnackBar(content: Text('নোটিফিকেশন মুছে ফেলা হয়েছে'), backgroundColor: AppColors.success),
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
        icon: const Icon(Icons.campaign, color: Colors.white),
        label: const Text('নোটিফিকেশন পাঠান', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: loadNotifications,
        color: AppColors.primary,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _notifications.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.notifications_none, size: 64, color: AppColors.textMuted),
                          const SizedBox(height: 12),
                          const Text('এখনও কোনো নোটিফিকেশন পাঠানো হয়নি', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                          const SizedBox(height: 14),
                          ElevatedButton.icon(
                            onPressed: _openSendDialog,
                            icon: const Icon(Icons.campaign),
                            label: const Text('প্রথম নোটিফিকেশন পাঠান'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 90),
                    itemCount: _notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = _notifications[index];
                      final aud = item['audience'] ?? 'all';
                      final audLabel = aud == 'all' ? 'সকল শিক্ষার্থী' : (aud == 'sem3' ? 'সেমিস্টার ৩' : 'সেমিস্টার ৪');
                      final dateStr = _formatDate(item['createdAt']);
                      final imgUrl = item['imageUrl'] as String?;

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
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.warningLight,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                                    ),
                                    child: Text(audLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF92400E))),
                                  ),
                                  Row(
                                    children: [
                                      Text(dateStr, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                      const SizedBox(width: 4),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.textMuted),
                                        onPressed: () => _deleteNotification(item['id']),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(item['title'] ?? 'শিরোনামহীন', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                              const SizedBox(height: 4),
                              Text(item['body'] ?? item['message'] ?? '', style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.4)),
                              if (imgUrl != null && imgUrl.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: CachedNetworkImage(
                                    imageUrl: imgUrl,
                                    height: 140,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
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
    );
  }
}
