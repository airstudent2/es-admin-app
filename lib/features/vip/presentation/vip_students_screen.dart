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
        title: const Text('ভিআইপি সাবস্ক্রিপশন বাতিল করবেন?'),
        content: Text('$name-এর সমস্ত ভিআইপি ও প্রিমিয়াম অ্যাক্সেস বাতিল হয়ে সাধারণ ফ্রি অ্যাকাউন্টে রূপান্তর হবে।'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('না')),
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
    showDialog(
      context: context,
      builder: (_) => GrantVipDialog(
        student: student,
        onSaved: loadUsers,
      ),
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
        backgroundColor: AppColors.warning,
        icon: const Icon(Icons.workspace_premium, color: Colors.white),
        label: const Text('সরাসরি ভিআইপি দিন', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                  _buildMetricTile('মোট শিক্ষার্থী', _allUsers.length, AppColors.primary),
                  const SizedBox(width: 8),
                  _buildMetricTile('ভিআইপি ইউজার', vipUsers.length, AppColors.warning),
                  const SizedBox(width: 8),
                  _buildMetricTile('ফ্রি ইউজার', freeUsers.length, AppColors.textSecondary),
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
                      hintText: 'নাম, ইমেইল বা UID দিয়ে খুঁজুন...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () => setState(() => _searchQuery = ''),
                            )
                          : null,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildFilterChip('সমস্ত (${_allUsers.length})', 'all'),
                      const SizedBox(width: 8),
                      _buildFilterChip('ভিআইপি (${vipUsers.length})', 'vip'),
                      const SizedBox(width: 8),
                      _buildFilterChip('ফ্রি (${freeUsers.length})', 'free'),
                    ],
                  ),
                ],
              ),
            ),

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
                                const Icon(Icons.people_outline, size: 64, color: AppColors.textMuted),
                                const SizedBox(height: 12),
                                const Text('কোনো শিক্ষার্থী পাওয়া যায়নি', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  onPressed: () => _openGrantDialog(),
                                  icon: const Icon(Icons.workspace_premium),
                                  label: const Text('নতুন ভিআইপি যুক্ত করুন'),
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
                            final email = user['email'] ?? 'ইমেইল নেই';
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
                                        // Avatar
                                        CircleAvatar(
                                          radius: 20,
                                          backgroundColor: isVip ? AppColors.warningLight : AppColors.primaryLight,
                                          child: Text(
                                            name.isNotEmpty ? name[0].toUpperCase() : 'S',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: isVip ? AppColors.warning : AppColors.primary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        // Name & Email
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
                                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                    decoration: BoxDecoration(
                                                      color: isVip ? AppColors.warningLight : const Color(0xFFF1F5F9),
                                                      borderRadius: BorderRadius.circular(6),
                                                      border: Border.all(color: isVip ? AppColors.warning : AppColors.border),
                                                    ),
                                                    child: Text(
                                                      isVip ? '👑 VIP' : 'FREE',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.bold,
                                                        color: isVip ? const Color(0xFFB45309) : AppColors.textSecondary,
                                                      ),
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

                                    // UID Copy Bar
                                    InkWell(
                                      onTap: () {
                                        Clipboard.setData(ClipboardData(text: uid));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('UID ক্লিপবোর্ডে কপি হয়েছে!'), duration: Duration(seconds: 1)),
                                        );
                                      },
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
                                            const Icon(Icons.key, size: 12, color: AppColors.textMuted),
                                            const SizedBox(width: 4),
                                            Text('UID: ${uid.length > 20 ? "${uid.substring(0, 18)}..." : uid}', style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.textSecondary)),
                                            const SizedBox(width: 6),
                                            const Icon(Icons.copy, size: 11, color: AppColors.primary),
                                          ],
                                        ),
                                      ),
                                    ),

                                    // Entitlements and Expiry if VIP
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
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(Icons.schedule, size: 13, color: AppColors.warning),
                                          const SizedBox(width: 4),
                                          Text('বাকি: $daysLeft দিন • মেয়াদ শেষ: $expiryDateStr', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFFB45309))),
                                        ],
                                      ),
                                    ],

                                    const SizedBox(height: 12),
                                    // Actions Bar
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        if (isVip)
                                          OutlinedButton.icon(
                                            onPressed: () => _revokeVip(user),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: AppColors.danger,
                                              side: const BorderSide(color: AppColors.danger),
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              visualDensity: VisualDensity.compact,
                                            ),
                                            icon: const Icon(Icons.cancel_outlined, size: 14),
                                            label: const Text('ভিআইপি বাতিল', style: TextStyle(fontSize: 12)),
                                          ),
                                        const SizedBox(width: 8),
                                        ElevatedButton.icon(
                                          onPressed: () => _openGrantDialog(user),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: isVip ? AppColors.primary : AppColors.warning,
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            visualDensity: VisualDensity.compact,
                                          ),
                                          icon: Icon(isVip ? Icons.update : Icons.add_moderator, size: 14),
                                          label: Text(isVip ? 'মেয়াদ বাড়ান' : 'ভিআইপি দিন', style: const TextStyle(fontSize: 12)),
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

  Widget _buildMetricTile(String title, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text('$count', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.white : AppColors.textPrimary)),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border)),
      onSelected: (sel) {
        if (sel) setState(() => _selectedFilter = value);
      },
    );
  }
}
