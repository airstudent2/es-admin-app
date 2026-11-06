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
      ApiClient.getDocument(AppConfig.colSettings, 'subject_locks'),
      ApiClient.getDocument(AppConfig.colSettings, 'library_locks'),
    ]);

    if (mounted) {
      final subLocks = (results[1] as Map<String, dynamic>?) ?? {};
      final libLocks = (results[2] as Map<String, dynamic>?) ?? {};
      final mergedLocks = <String, dynamic>{}..addAll(libLocks)..addAll(subLocks);

      setState(() {
        _videosList = (results[0] as List<Map<String, dynamic>>)
          ..sort((a, b) => ((a['order'] ?? 1) as int).compareTo((b['order'] ?? 1) as int));
        _locks = mergedLocks;
        _isLoading = false;
      });
    }
  }

  bool _isSubjectLocked(String subId) {
    return _locks['sem${_activeSemester}_${subId}_locked'] == true;
  }

  Future<void> _toggleSubjectLock(String subId, bool currentLocked) async {
    final key = 'sem${_activeSemester}_${subId}_locked';
    final updated = Map<String, dynamic>.from(_locks);
    updated[key] = !currentLocked;

    final s1 = await ApiClient.setDocument(AppConfig.colSettings, 'subject_locks', updated);
    final s2 = await ApiClient.setDocument(AppConfig.colSettings, 'library_locks', updated);
    final success = s1 || s2;

    if (success) {
      setState(() => _locks = updated);
      if (mounted) {
        final subName = subId == 'bengali' ? 'বাংলা' : 'English';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(!currentLocked ? '$subName বিষয় সফলভাবে লকড (VIP) করা হয়েছে' : '$subName বিষয় সবার জন্য উন্মুক্ত করা হয়েছে'),
            backgroundColor: !currentLocked ? const Color(0xFFD97706) : AppColors.success,
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(!currentFree ? 'ক্লাসটি ফ্রি করা হয়েছে' : 'ক্লাসটি ভিআইপি লক করা হয়েছে'),
            backgroundColor: !currentFree ? AppColors.success : const Color(0xFFD97706),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }
  }

  Future<void> _deleteVideo(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('ভিডিও ক্লাস মুছে ফেলবেন?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: const Text('আপনি কি নিশ্চিত যে এই ক্লাসটি সম্পূর্ণ মুছে ফেলতে চান?'),
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
    AddEditVideoDialog.show(
      context,
      initialData: item,
      defaultSemester: _activeSemester,
      defaultSubjectId: _activeSubjectId,
      onSaved: loadData,
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
        elevation: 3,
        icon: const Icon(Icons.video_call_rounded, color: Colors.white, size: 20),
        label: const Text('নতুন ক্লাস', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5)),
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
                        ButtonSegment(value: 3, label: Text('সেমিস্টার ৩', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                        ButtonSegment(value: 4, label: Text('সেমিস্টার ৪', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
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

            // Subject Selector & Global Lock Switch Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Colors.white,
              child: Column(
                children: [
                  // Subject Selector Tabs
                  Row(
                    children: [
                      _buildSubjectTab('বাংলা (Bengali)', 'bengali', Icons.menu_book_rounded),
                      const SizedBox(width: 10),
                      _buildSubjectTab('English', 'english', Icons.language_rounded),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Global Lock Status Card (Mobile Overflow Safe)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isCurSubLocked ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isCurSubLocked ? const Color(0xFFFECACA) : const Color(0xFFBBF7D0)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isCurSubLocked ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isCurSubLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
                            color: isCurSubLocked ? AppColors.danger : AppColors.success,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_activeSubjectId == 'bengali' ? 'বাংলা' : 'English'} বিষয় গ্লোবাল স্ট্যাটাস:',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                isCurSubLocked ? 'লকড (VIP শিক্ষার্থীরা ক্লাস দেখতে পারবে)' : 'উন্মুক্ত (সকলের জন্য ফ্রি ক্লাস)',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isCurSubLocked ? AppColors.danger : const Color(0xFF15803D),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
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
                  : filteredVideos.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.video_library_outlined, size: 52, color: AppColors.textMuted),
                                    const SizedBox(height: 12),
                                    Text('সেমিস্টার $_activeSemester ${_activeSubjectId == 'bengali' ? "বাংলা" : "English"} বিষয়ে কোনো ক্লাস নেই', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                                    const SizedBox(height: 14),
                                    ElevatedButton.icon(
                                      onPressed: () => _openAddEditModal(),
                                      icon: const Icon(Icons.add, size: 18),
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
                                final topic = (v['topicName'] ?? v['topic'] ?? '').toString();

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
                                                color: const Color(0xFFF1F5F9),
                                                child: const Icon(Icons.play_circle_outline_rounded, size: 48, color: AppColors.textMuted),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            top: 8,
                                            right: 8,
                                            child: InkWell(
                                              onTap: () => _toggleVideoFree(v['id'], isFree),
                                              borderRadius: BorderRadius.circular(6),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: isFree ? const Color(0xFF10B981) : const Color(0xFFD97706),
                                                  borderRadius: BorderRadius.circular(6),
                                                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(isFree ? Icons.lock_open_rounded : Icons.lock_rounded, size: 12, color: Colors.white),
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
                                            Text(v['title'] ?? 'শিরোনামহীন', style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
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
                                          color: Color(0xFFF8FAFC),
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
                                                  icon: const Icon(Icons.edit_rounded, size: 14, color: AppColors.primary),
                                                  label: const Text('এডিট', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                                ),
                                                TextButton.icon(
                                                  onPressed: () => _deleteVideo(v['id']),
                                                  icon: const Icon(Icons.delete_outline_rounded, size: 14, color: AppColors.danger),
                                                  label: const Text('মুছুন', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.danger)),
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
            color: isSelected ? AppColors.primaryLight : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? AppColors.primary : AppColors.border, width: isSelected ? 1.5 : 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? AppColors.primary : AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
