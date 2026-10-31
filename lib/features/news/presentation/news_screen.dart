import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/config/app_config.dart';
import 'add_edit_news_dialog.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => NewsScreenState();
}

class NewsScreenState extends State<NewsScreen> {
  List<Map<String, dynamic>> _newsList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    loadNews();
  }

  Future<void> loadNews() async {
    setState(() => _isLoading = true);
    final list = await ApiClient.getCollection(AppConfig.colNews);
    list.sort((a, b) => ((a['order'] ?? 1) as int).compareTo((b['order'] ?? 1) as int));
    if (mounted) {
      setState(() {
        _newsList = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleActive(String id, bool currentStatus) async {
    final success = await ApiClient.updateDocument(AppConfig.colNews, id, {
      'isActive': !currentStatus,
    });
    if (success) {
      loadNews();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(!currentStatus ? 'ব্যানার সক্রিয় করা হয়েছে' : 'ব্যানার নিষ্ক্রিয় করা হয়েছে'),
          backgroundColor: !currentStatus ? AppColors.success : AppColors.warning,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _deleteItem(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ব্যানার মুছে ফেলবেন?'),
        content: const Text('আপনি কি নিশ্চিত যে এই ব্যানারটি সম্পূর্ণ মুছে ফেলতে চান?'),
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
      final success = await ApiClient.deleteDocument(AppConfig.colNews, id);
      if (success) {
        loadNews();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ব্যানার সফলভাবে মুছে ফেলা হয়েছে'), backgroundColor: AppColors.success),
          );
        }
      }
    }
  }

  void _openAddEditModal([Map<String, dynamic>? item]) {
    showDialog(
      context: context,
      builder: (_) => AddEditNewsDialog(
        initialData: item,
        onSaved: loadNews,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddEditModal(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('নতুন ব্যানার', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: loadNews,
        color: AppColors.primary,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _newsList.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.newspaper, size: 64, color: AppColors.textMuted),
                          const SizedBox(height: 12),
                          const Text('কোনো ব্যানার স্লাইডার পাওয়া যায়নি', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => _openAddEditModal(),
                            icon: const Icon(Icons.add),
                            label: const Text('প্রথম ব্যানার যুক্ত করুন'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 90),
                    itemCount: _newsList.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final item = _newsList[index];
                      final isActive = item['isActive'] != false;
                      final tag = item['tag'] ?? 'LATEST';
                      final sem = item['targetSemester'] ?? 0;
                      final semLabel = sem == 0 ? 'সমস্ত সেমিস্টার' : 'সেমিস্টার $sem';

                      return Card(
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Banner Image Header
                            Stack(
                              children: [
                                AspectRatio(
                                  aspectRatio: 16 / 9,
                                  child: CachedNetworkImage(
                                    imageUrl: item['imageUrl'] ?? '',
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => Container(color: Colors.black12, child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
                                    errorWidget: (_, __, ___) => Container(
                                      color: Colors.grey.shade300,
                                      child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                                    ),
                                  ),
                                ),
                                // Badges
                                Positioned(
                                  top: 10,
                                  left: 10,
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: tag == 'LATEST NEWS' ? Colors.red.shade600 : AppColors.primary,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(tag, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.7),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(semLabel, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                ),
                                // Toggle active button
                                Positioned(
                                  top: 10,
                                  right: 10,
                                  child: InkWell(
                                    onTap: () => _toggleActive(item['id'], isActive),
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: isActive ? AppColors.success : Colors.black54,
                                        shape: BoxShape.circle,
                                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                                      ),
                                      child: const Icon(Icons.power_settings_new, color: Colors.white, size: 16),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // Content
                            Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['title'] ?? 'শিরোনামহীন',
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if ((item['subtitle'] ?? '').toString().isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      item['subtitle'] ?? '',
                                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            // Bottom actions bar
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF1F5F9),
                                border: Border(top: BorderSide(color: AppColors.border)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('ক্রমিক: #${item['order'] ?? 1}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                                  Row(
                                    children: [
                                      TextButton.icon(
                                        onPressed: () => _openAddEditModal(item),
                                        icon: const Icon(Icons.edit, size: 14, color: AppColors.primary),
                                        label: const Text('এডিট', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                                      ),
                                      TextButton.icon(
                                        onPressed: () => _deleteItem(item['id']),
                                        icon: const Icon(Icons.delete, size: 14, color: AppColors.danger),
                                        label: const Text('মুছুন', style: TextStyle(color: AppColors.danger, fontSize: 12, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
