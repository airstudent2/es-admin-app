import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/config/app_config.dart';
import 'grant_vip_dialog.dart';

class VipStudentsScreen extends StatefulWidget {
  const VipStudentsScreen({super.key});

  @override
  State<VipStudentsScreen> createState() => VipStudentsScreenState();
}

class VipStudentsScreenState extends State<VipStudentsScreen> {
  List<Map<String, dynamic>> _allUsers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter = 'all'; // 'all', 'vip', 'free'

  final Map<String, String> _grantBadgeMap = {
    'combo_all': '🌟 অল-ইন-ওয়ান কম্বো',
    'combo_sem3': '🌟 সেম ৩ কম্বো',
    'combo_sem4': '🌟 সেম ৪ কম্বো',
    'premium_mock_all': '📝 সমস্ত মক টেস্ট',
    'premium_mock_sem3': '📝 সেম ৩ মক টেস্ট',
    'premium_mock_sem4': '📝 সেম ৪ মক টেস্ট',
    'video_library_all': '🎥 সমস্ত ভিডিও',
    'video_library_sem3': '🎥 সেম ৩ ভিডিও',
    'video_library_sem4': '🎥 সেম ৪ ভিডিও',
  };

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  Future<void> loadUsers() async {
    setState(() => _isLoading = true);
    final list = await ApiClient.getCollection(AppConfig.colUsers);
    if (mounted) {
      setState(() {
        _allUsers = list;
        _isLoading = false;
      });
    }
  }

  int _getRemainingDays(dynamic expiryIso) {
    if (expiryIso == null) return 0;
    try {
      final exp = DateTime.parse(expiryIso.toString());
      final diff = exp.difference(DateTime.now()).inDays;
      return diff > 0 ? diff : 0;
    } catch (_) {
      return 0;
    }
  }

  String _formatDate(dynamic dateIso) {
    if (dateIso == null) return '—';
    try {
      final d = DateTime.parse(dateIso.toString());
      return DateFormat('dd MMM yyyy').format(d);
    } catch (_) {
      return '—';
    }
  }

  bool _isUserVip(Map<String, dynamic> u) {
    if (u['is_vip'] == true) return true;
    final ents = u['entitlements'];
    return ents is List && ents.isNotEmpty;
  }

  Future<void> _revokeVip(Map<String, dynamic> user) async {
    final name = user['name'] ?? user['email'] ?? 'শিক্ষার্থী';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('ভিআইপি সাবস্ক্রিপশন বাতিল করবেন?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text('$name-এর সমস্ত ভিআইপি ও প্রিমিয়াম অ্যাক্সেস মুছে দিয়ে ফ্রি অ্যাকাউন্টে রূপান্তর করা হবে।'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('না, রাখুন', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('হ্যাঁ, বাতিল করুন'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final uid = user['id'];
      if (uid != null) {
        final success = await ApiClient.updateDocument(AppConfig.colUsers, uid, {
          'is_vip': false,
          'is_premium': false,
          'entitlements': [],
          'vip_expires_at': null,
          'revoked_at': DateTime.now().toIso8601String(),
        });
        if (success) {
          loadUsers();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('ভিআইপি সাবস্ক্রিপশন সফলভাবে বাতিল করা হয়েছে'), backgroundColor: AppColors.warning),
            );
          }
        }
      }
    }
  }

  void _openGrantDialog([Map<String, dynamic>? student]) {
    GrantVipDialog.show(
      context,
      student: student,
      onSaved: loadUsers,
    );
  }

  @override
  Widget build(BuildContext context) {
    final vipUsers = _allUsers.where(_isUserVip).toList();
    final freeUsers = _allUsers.where((u) => !_isUserVip(u)).toList();

    List<Map<String, dynamic>> displayList = _allUsers;
    if (_selectedFilter == 'vip') displayList = vipUsers;
    if (_selectedFilter == 'free') displayList = freeUsers;

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      displayList = displayList.where((u) {
        final n = (u['name'] ?? '').toString().toLowerCase();
        final e = (u['email'] ?? '').toString().toLowerCase();
        final id = (u['id'] ?? '').toString().toLowerCase();
        return n.contains(q) || e.contains(q) || id.contains(q);
      }).toList();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openGrantDialog(),
        backgroundColor: const Color(0xFFD97706),
        elevation: 3,
        icon: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 20),
        label: const Text('ভিআইপি দিন', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5)),
      ),
      body: RefreshIndicator(
        onRefresh: loadUsers,
        color: AppColors.primary,
        child: Column(
          children: [
            // Top Metrics Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white,
              child: Row(
                children: [
                  _buildMetricTile(
                    title: 'মোট শিক্ষার্থী',
                    count: _allUsers.length,
                    icon: Icons.people_alt_rounded,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  _buildMetricTile(
                    title: 'ভিআইপি ইউজার',
                    count: vipUsers.length,
                    icon: Icons.workspace_premium_rounded,
                    color: const Color(0xFFD97706),
                  ),
                  const SizedBox(width: 8),
                  _buildMetricTile(
                    title: 'ফ্রি ইউজার',
                    count: freeUsers.length,
                    icon: Icons.person_outline_rounded,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),

            // Search Bar & Filter Chips
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Colors.white,
              child: Column(
                children: [
                  TextField(
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    decoration: InputDecoration(
                      hintText: 'শিক্ষার্থীর নাম, ইমেইল বা UID লিখে খুঁজুন...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textSecondary),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.cancel_rounded, size: 18, color: AppColors.textMuted),
                              onPressed: () => setState(() => _searchQuery = ''),
                            )
                          : null,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('সমস্ত (${_allUsers.length})', 'all'),
                        const SizedBox(width: 8),
                        _buildFilterChip('👑 ভিআইপি (${vipUsers.length})', 'vip'),
                        const SizedBox(width: 8),
                        _buildFilterChip('ফ্রি (${freeUsers.length})', 'free'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),

            // Students List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : displayList.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.search_off_rounded, size: 56, color: AppColors.textMuted),
                                const SizedBox(height: 12),
                                const Text('কোনো শিক্ষার্থী মেলেনি', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                                const SizedBox(height: 4),
                                const Text('সার্চ কিওয়ার্ড পরিবর্তন করুন অথবা সরাসরি নতুন ভিআইপি যুক্ত করুন।', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                const SizedBox(height: 14),
                                ElevatedButton.icon(
                                  onPressed: () => _openGrantDialog(),
                                  icon: const Icon(Icons.workspace_premium_rounded, size: 18),
                                  label: const Text('সরাসরি ভিআইপি যুক্ত করুন'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 90),
                          itemCount: displayList.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final user = displayList[index];
                            final isVip = _isUserVip(user);
                            final name = user['name'] ?? 'শিক্ষার্থী';
                            final email = user['email'] ?? 'ইমেইল দেওয়া নেই';
                            final uid = user['id'] ?? '';
                            final daysLeft = _getRemainingDays(user['vip_expires_at']);
                            final expiryDateStr = _formatDate(user['vip_expires_at']);
                            final ents = user['entitlements'] as List? ?? [];

                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Initials Avatar
                                        CircleAvatar(
                                          radius: 20,
                                          backgroundColor: isVip ? const Color(0xFFFEF3C7) : AppColors.primaryLight,
                                          child: Text(
                                            name.isNotEmpty ? name[0].toUpperCase() : 'S',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: isVip ? const Color(0xFFB45309) : AppColors.primary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        // Student Info
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      name,
                                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: AppColors.textPrimary),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                    decoration: BoxDecoration(
                                                      color: isVip ? const Color(0xFFFEF3C7) : const Color(0xFFF1F5F9),
                                                      borderRadius: BorderRadius.circular(6),
                                                      border: Border.all(color: isVip ? const Color(0xFFFDE68A) : AppColors.border),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        if (isVip) ...[
                                                          const Icon(Icons.stars_rounded, size: 12, color: Color(0xFFD97706)),
                                                          const SizedBox(width: 3),
                                                        ],
                                                        Text(
                                                          isVip ? 'VIP সদস্য' : 'ফ্রি ইউজার',
                                                          style: TextStyle(
                                                            fontSize: 10.5,
                                                            fontWeight: FontWeight.bold,
                                                            color: isVip ? const Color(0xFF92400E) : AppColors.textSecondary,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              Text(email, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),

                                    // UID Copy Capsule
                                    InkWell(
                                      onTap: () {
                                        Clipboard.setData(ClipboardData(text: uid));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('UID ক্লিপবোর্ডে কপি হয়েছে!'), duration: Duration(milliseconds: 900)),
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(6),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF8FAFC),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: AppColors.border),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.fingerprint_rounded, size: 13, color: AppColors.textMuted),
                                            const SizedBox(width: 4),
                                            Text(
                                              'UID: ${uid.length > 22 ? "${uid.substring(0, 20)}..." : uid}',
                                              style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.textSecondary),
                                            ),
                                            const SizedBox(width: 6),
                                            const Icon(Icons.copy_rounded, size: 12, color: AppColors.primary),
                                          ],
                                        ),
                                      ),
                                    ),

                                    // Active Entitlements & Remaining Time
                                    if (isVip) ...[
                                      const SizedBox(height: 10),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        children: ents.map((e) {
                                          final label = _grantBadgeMap[e.toString()] ?? e.toString();
                                          return Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFEF3C7),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: const Color(0xFFFDE68A)),
                                            ),
                                            child: Text(label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF92400E))),
                                          );
                                        }).toList(),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFFBEB),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: const Color(0xFFFDE68A)),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.timer_outlined, size: 14, color: Color(0xFFD97706)),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                'বাকি: $daysLeft দিন • মেয়াদ শেষ হবে: $expiryDateStr',
                                                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],

                                    const SizedBox(height: 12),
                                    // Action Buttons
                                    Wrap(
                                      alignment: WrapAlignment.end,
                                      spacing: 8,
                                      runSpacing: 6,
                                      children: [
                                        if (isVip)
                                          OutlinedButton.icon(
                                            onPressed: () => _revokeVip(user),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: AppColors.danger,
                                              side: const BorderSide(color: Color(0xFFFCA5A5)),
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              visualDensity: VisualDensity.compact,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                            icon: const Icon(Icons.block_rounded, size: 13),
                                            label: const Text('ভিআইপি বাতিল', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                                          ),
                                        ElevatedButton.icon(
                                          onPressed: () => _openGrantDialog(user),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: isVip ? AppColors.primary : const Color(0xFFD97706),
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            visualDensity: VisualDensity.compact,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                          icon: Icon(isVip ? Icons.update_rounded : Icons.workspace_premium_rounded, size: 14),
                                          label: Text(
                                            isVip ? 'মেয়াদ বাড়ান' : 'ভিআইপি দিন',
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
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

  Widget _buildMetricTile({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 13, color: color),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              '$count',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color, height: 1.1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? Colors.white : AppColors.textPrimary,
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: const Color(0xFFF8FAFC),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
      ),
      onSelected: (sel) {
        if (sel) setState(() => _selectedFilter = value);
      },
    );
  }
}
