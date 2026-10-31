import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/config/app_config.dart';
import 'add_edit_video_dialog.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => LibraryScreenState();
}

class LibraryScreenState extends State<LibraryScreen> {
  int _activeSemester = 3;
  String _activeSubjectId = 'bengali'; // 'bengali' or 'english'

  List<Map<String, dynamic>> _videosList = [];
  Map<String, dynamic> _locks = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      ApiClient.getCollection(AppConfig.colVideos),
      ApiClient.getDocument(AppConfig.colSettings, 'library_locks'),
    ]);

    if (mounted) {
      setState(() {
        _videosList = (results[0] as List<Map<String, dynamic>>)
          ..sort((a, b) => ((a['order'] ?? 1) as int).compareTo((b['order'] ?? 1) as int));
        _locks = (results[1] as Map<String, dynamic>?) ?? {};
        _isLoading = false;
      });
    }
  }

  bool _isSubjectLocked(String subId) {
    if (subId == 'bengali') return _locks['sem3_bengali_locked'] == true;
    if (subId == 'english') return _locks['sem3_english_locked'] == true;
    return false;
  }

  Future<void> _toggleSubjectLock(String subId, bool currentLocked) async {
    final key = subId == 'bengali' ? 'sem3_bengali_locked' : 'sem3_english_locked';
    final updated = Map<String, dynamic>.from(_locks);
    updated[key] = !currentLocked;

    final success = await ApiClient.setDocument(AppConfig.colSettings, 'library_locks', updated);
    if (success) {
      setState(() => _locks = updated);
      if (mounted) {
        final subName = subId == 'bengali' ? 'বাংলা' : 'English';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(!currentLocked ? '$subName বিষয় সফলভাবে লকড (PRO) করা হয়েছে' : '$subName বিষয় সবার জন্য উন্মুক্ত করা হয়েছে'),
            backgroundColor: !currentLocked ? AppColors.warning : AppColors.success,
          ),
        );
      }
    }
  }

  Future<void> _toggleVideoFree(String id, bool currentFree) async {
    final success = await ApiClient.updateDocument(AppConfig.colVideos, id, {
      'isFree': !currentFree,
    });
    if (success) {
      loadData();
    }
  }

  Future<void> _deleteVideo(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ভিডিও ক্লাস মুছে ফেলবেন?'),
        content: const Text('আপনি কি নিশ্চিত যে এই ক্লাসটি সম্পূর্ণ মুছে ফেলতে চান?'),
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
      final success = await ApiClient.deleteDocument(AppConfig.colVideos, id);
      if (success) {
        loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ক্লাসটি মুছে ফেলা হয়েছে'), backgroundColor: AppColors.success),
          );
        }
      }
    }
  }

  void _openAddEditModal([Map<String, dynamic>? item]) {
    showDialog(
      context: context,
      builder: (_) => AddEditVideoDialog(
        initialData: item,
        defaultSemester: _activeSemester,
        defaultSubjectId: _activeSubjectId,
        onSaved: loadData,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredVideos = _videosList.where((v) {
      final s = int.tryParse(v['semester']?.toString() ?? '0') ?? 0;
      final semMatches = s == _activeSemester;
      final sub = (v['subjectId'] ?? '').toString().toLowerCase();
      final subMatches = sub == _activeSubjectId ||
          (_activeSubjectId == 'bengali' && sub.contains('beng')) ||
          (_activeSubjectId == 'english' && sub.contains('eng'));
      return semMatches && subMatches;
    }).toList();

    final isCurSubLocked = _isSubjectLocked(_activeSubjectId);

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddEditModal(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.video_call, color: Colors.white),
        label: const Text('নতুন ক্লাস যুক্ত করুন', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: loadData,
        color: AppColors.primary,
        child: Column(
          children: [
            // Semester Switcher Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 3, label: Text('সেমিস্টার ৩', style: TextStyle(fontWeight: FontWeight.bold))),
                        ButtonSegment(value: 4, label: Text('সেমিস্টার ৪', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      selected: {_activeSemester},
                      onSelectionChanged: (set) => setState(() => _activeSemester = set.first),
                      style: SegmentedButton.styleFrom(
                        selectedBackgroundColor: AppColors.primary,
                        selectedForegroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),

            // Subject Tabs & Global Lock Switch Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Colors.white,
              child: Column(
                children: [
                  // Subject Selector Tabs
                  Row(
                    children: [
                      _buildSubjectTab('বাংলা', 'bengali', Icons.menu_book),
                      const SizedBox(width: 10),
                      _buildSubjectTab('English', 'english', Icons.language),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Global Subject Lock Card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isCurSubLocked ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isCurSubLocked ? const Color(0xFFFECACA) : const Color(0xFFBBF7D0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isCurSubLocked ? Icons.lock : Icons.lock_open,
                              color: isCurSubLocked ? AppColors.danger : AppColors.success,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_activeSubjectId == 'bengali' ? 'বাংলা' : 'English'} বিষয় গ্লোবাল স্ট্যাটাস:',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                                ),
                                Text(
                                  isCurSubLocked ? '🔒 লকড (শুধুমাত্র VIP শিক্ষার্থীরা দেখতে পারবে)' : '🔓 উন্মুক্ত (সকল শিক্ষার্থীর জন্য ফ্রি)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isCurSubLocked ? AppColors.danger : AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Switch(
                          value: isCurSubLocked,
                          activeColor: AppColors.danger,
                          inactiveThumbColor: AppColors.success,
                          onChanged: (val) => _toggleSubjectLock(_activeSubjectId, isCurSubLocked),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),

            // Video Classes List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _activeSemester == 4
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.hourglass_top, size: 56, color: AppColors.warning),
                                const SizedBox(height: 12),
                                const Text('সেমিস্টার ৪ প্রস্তুতিমূলক', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                const SizedBox(height: 6),
                                const Text('ইউজার অ্যাপে সেমিস্টার ৪ এখনও কামিং সুন রয়েছে। সেমিস্টার ৩ এর ভিডিও ক্লাস সক্রিয় রয়েছে।', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                        )
                      : filteredVideos.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.video_library_outlined, size: 56, color: AppColors.textMuted),
                                    const SizedBox(height: 12),
                                    Text('সেমিস্টার ৩ ${_activeSubjectId == 'bengali' ? "বাংলা" : "English"} বিষয়ে কোনো ক্লাস যুক্ত নেই', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                                    const SizedBox(height: 14),
                                    ElevatedButton.icon(
                                      onPressed: () => _openAddEditModal(),
                                      icon: const Icon(Icons.add),
                                      label: const Text('প্রথম ক্লাস যুক্ত করুন'),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 90),
                              itemCount: filteredVideos.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final v = filteredVideos[index];
                                final isFree = v['isFree'] == true;
                                final thumb = v['thumbnailUrl'] ?? '';
                                final topic = v['topicName'] ?? v['topic'] ?? '';

                                return Card(
                                  clipBehavior: Clip.antiAlias,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Stack(
                                        children: [
                                          AspectRatio(
                                            aspectRatio: 16 / 9,
                                            child: CachedNetworkImage(
                                              imageUrl: thumb,
                                              fit: BoxFit.cover,
                                              placeholder: (_, __) => Container(color: Colors.black12, child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
                                              errorWidget: (_, __, ___) => Container(
                                                color: Colors.grey.shade300,
                                                child: const Icon(Icons.play_circle_outline, size: 48, color: Colors.grey),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            top: 8,
                                            right: 8,
                                            child: InkWell(
                                              onTap: () => _toggleVideoFree(v['id'], isFree),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: isFree ? AppColors.success : AppColors.warning,
                                                  borderRadius: BorderRadius.circular(6),
                                                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(isFree ? Icons.lock_open : Icons.lock, size: 12, color: Colors.white),
                                                    const SizedBox(width: 4),
                                                    Text(isFree ? 'FREE' : 'VIP ONLY', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(v['title'] ?? 'শিরোনামহীন', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                            if (topic.isNotEmpty) ...[
                                              const SizedBox(height: 3),
                                              Text('অধ্যায়: $topic', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                            ],
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFF1F5F9),
                                          border: Border(top: BorderSide(color: AppColors.border)),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text('ক্রমিক: #${v['order'] ?? 1}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                                            Row(
                                              children: [
                                                TextButton.icon(
                                                  onPressed: () => _openAddEditModal(v),
                                                  icon: const Icon(Icons.edit, size: 14, color: AppColors.primary),
                                                  label: const Text('এডিট', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                                ),
                                                TextButton.icon(
                                                  onPressed: () => _deleteVideo(v['id']),
                                                  icon: const Icon(Icons.delete, size: 14, color: AppColors.danger),
                                                  label: const Text('মুছুন', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.danger)),
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

  Widget _buildSubjectTab(String label, String id, IconData icon) {
    final isSelected = _activeSubjectId == id;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _activeSubjectId = id),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? Colors.white : AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
