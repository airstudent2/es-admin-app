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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('ব্যানার মুছে ফেলবেন?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: const Text('আপনি কি নিশ্চিত যে এই ব্যানার স্লাইডারটি মুছে ফেলতে চান?'),
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
    final activeCount = _newsList.where((n) => n['isActive'] != false).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddEditModal(),
        backgroundColor: AppColors.primary,
        elevation: 3,
        icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
        label: const Text('নতুন ব্যানার', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5)),
      ),
      body: RefreshIndicator(
        onRefresh: loadNews,
        color: AppColors.primary,
        child: Column(
          children: [
            // Sub-header Summary Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.view_carousel_rounded, size: 18, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        'হোমস্ক্রিন ব্যানার তালিকা (${_newsList.length})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.success.withOpacity(0.3)),
                    ),
                    child: Text(
                      'সক্রিয়: $activeCount টি',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _newsList.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.newspaper_rounded, size: 60, color: AppColors.textMuted),
                                const SizedBox(height: 12),
                                const Text('কোনো ব্যানার স্লাইডার পাওয়া যায়নি', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                                const SizedBox(height: 6),
                                const Text('অ্যাপের হোমপেজে শিক্ষার্থীদের জন্য নতুন ব্যানার ও অফার প্রদর্শন করতে যোগ করুন।', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () => _openAddEditModal(),
                                  icon: const Icon(Icons.add, size: 18),
                                  label: const Text('প্রথম ব্যানার যুক্ত করুন'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.only(left: 16, right: 16, top: 14, bottom: 90),
                          itemCount: _newsList.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final item = _newsList[index];
                            final isActive = item['isActive'] != false;
                            final tag = (item['tag'] ?? 'LATEST').toString();
                            final sem = item['targetSemester'] ?? 0;
                            final semLabel = sem == 0 ? 'সকল সেমিস্টার' : 'সেমিস্টার $sem';

                            Color tagColor = AppColors.primary;
                            if (tag == 'LATEST NEWS') tagColor = const Color(0xFFDC2626);
                            if (tag == 'NOTICE') tagColor = const Color(0xFFD97706);
                            if (tag == 'EXAM') tagColor = const Color(0xFF7C3AED);
                            if (tag == 'UPDATE') tagColor = const Color(0xFF2563EB);

                            return Card(
                              clipBehavior: Clip.antiAlias,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: isActive ? AppColors.border : AppColors.border.withOpacity(0.5),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Banner Image with Badges
                                  Stack(
                                    children: [
                                      AspectRatio(
                                        aspectRatio: 16 / 9,
                                        child: CachedNetworkImage(
                                          imageUrl: item['imageUrl'] ?? '',
                                          fit: BoxFit.cover,
                                          placeholder: (_, __) => Container(
                                            color: Colors.black12,
                                            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                          ),
                                          errorWidget: (_, __, ___) => Container(
                                            color: const Color(0xFFF1F5F9),
                                            child: const Center(
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.image_outlined, size: 36, color: AppColors.textMuted),
                                                  SizedBox(height: 4),
                                                  Text('ছবি লোড হয়নি', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Top Badges
                                      Positioned(
                                        top: 10,
                                        left: 10,
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                              decoration: BoxDecoration(
                                                color: tagColor,
                                                borderRadius: BorderRadius.circular(6),
                                                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                                              ),
                                              child: Text(
                                                tag,
                                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.3),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withOpacity(0.75),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                semLabel,
                                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Active/Inactive Quick Switch Pill
                                      Positioned(
                                        top: 10,
                                        right: 10,
                                        child: InkWell(
                                          onTap: () => _toggleActive(item['id'], isActive),
                                          borderRadius: BorderRadius.circular(20),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: isActive ? const Color(0xFF10B981) : Colors.black87,
                                              borderRadius: BorderRadius.circular(20),
                                              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  isActive ? Icons.check_circle_rounded : Icons.pause_circle_rounded,
                                                  size: 13,
                                                  color: Colors.white,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  isActive ? 'সক্রিয়' : 'বন্ধ',
                                                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.white),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Title & Subtitle
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['title'] ?? 'শিরোনামহীন',
                                          style: const TextStyle(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                            height: 1.25,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if ((item['subtitle'] ?? '').toString().isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            item['subtitle'] ?? '',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textSecondary,
                                              height: 1.3,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),

                                  // Bottom Bar with Action Buttons
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFF8FAFC),
                                      border: Border(top: BorderSide(color: AppColors.border)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: AppColors.border),
                                          ),
                                          child: Text(
                                            'সিরিয়াল: #${item['order'] ?? 1}',
                                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            TextButton.icon(
                                              onPressed: () => _openAddEditModal(item),
                                              icon: const Icon(Icons.edit_rounded, size: 14, color: AppColors.primary),
                                              label: const Text('এডিট', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                                            ),
                                            const SizedBox(width: 4),
                                            TextButton.icon(
                                              onPressed: () => _deleteItem(item['id']),
                                              icon: const Icon(Icons.delete_outline_rounded, size: 14, color: AppColors.danger),
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
          ],
        ),
      ),
    );
  }
}
