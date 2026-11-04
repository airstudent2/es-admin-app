import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_theme.dart';
import 'features/news/presentation/news_screen.dart';
import 'features/vip/presentation/vip_students_screen.dart';
import 'features/library/presentation/library_screen.dart';
import 'features/notifications/presentation/notifications_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const EsAdminApp());
}

class EsAdminApp extends StatelessWidget {
  const EsAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Es Bangla Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('bn', 'BD'),
        Locale('en', 'US'),
      ],
      home: const AdminHomeScreen(),
    );
  }
}

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  bool _isRefreshing = false;
  late AnimationController _rotateController;

  final GlobalKey<NewsScreenState> _newsKey = GlobalKey();
  final GlobalKey<VipStudentsScreenState> _vipKey = GlobalKey();
  final GlobalKey<LibraryScreenState> _libraryKey = GlobalKey();
  final GlobalKey<NotificationsScreenState> _notificationsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }

  @override
  void dispose() {
    _rotateController.dispose();
    super.dispose();
  }

  Future<void> _handleGlobalRefresh() async {
    setState(() => _isRefreshing = true);
    _rotateController.repeat();
    try {
      if (_currentIndex == 0) {
        await _newsKey.currentState?.loadNews();
      } else if (_currentIndex == 1) {
        await _vipKey.currentState?.loadUsers();
      } else if (_currentIndex == 2) {
        await _libraryKey.currentState?.loadData();
      } else if (_currentIndex == 3) {
        await _notificationsKey.currentState?.loadNotifications();
      }
    } finally {
      if (mounted) {
        _rotateController.stop();
        _rotateController.reset();
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // Official Es Bangla App Icon
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.border,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.12),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      'assets/icons/app_logo.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Brand Text
                  const Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Es Bangla Admin',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.3,
                            height: 1.15,
                          ),
                        ),
                        Text(
                          'অফিশিয়াল কন্ট্রোল প্যানেল • v1.0.4',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Cloud Synced Status Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.success.withOpacity(0.35)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.success,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          'সিঙ্কড',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF047857),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Refresh Button with smooth rotation
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isRefreshing ? null : _handleGlobalRefresh,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: RotationTransition(
                          turns: _rotateController,
                          child: const Icon(
                            Icons.refresh_rounded,
                            size: 19,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          NewsScreen(key: _newsKey),
          VipStudentsScreen(key: _vipKey),
          LibraryScreen(key: _libraryKey),
          NotificationsScreen(key: _notificationsKey),
        ],
      ),
      // Custom Sleek Navigation Bar with SafeArea for Android Gesture Bar
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
          boxShadow: [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 10,
              offset: Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 60,
            child: Row(
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.newspaper_outlined,
                  activeIcon: Icons.newspaper_rounded,
                  label: 'নিউজ ব্যানার',
                  activeColor: AppColors.primary,
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.workspace_premium_outlined,
                  activeIcon: Icons.workspace_premium_rounded,
                  label: 'ভিআইপি ও ইউজার',
                  activeColor: AppColors.warning,
                ),
                _buildNavItem(
                  index: 2,
                  icon: Icons.video_library_outlined,
                  activeIcon: Icons.video_library_rounded,
                  label: 'ভিডিও লাইব্রেরি',
                  activeColor: AppColors.primary,
                ),
                _buildNavItem(
                  index: 3,
                  icon: Icons.campaign_outlined,
                  activeIcon: Icons.campaign_rounded,
                  label: 'নোটিফিকেশন',
                  activeColor: AppColors.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required Color activeColor,
  }) {
    final isSelected = _currentIndex == index;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _currentIndex = index),
          splashColor: activeColor.withOpacity(0.08),
          highlightColor: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(
                  horizontal: isSelected ? 14 : 0,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? activeColor.withOpacity(0.12) : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  isSelected ? activeIcon : icon,
                  size: 20,
                  color: isSelected ? activeColor : AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  color: isSelected ? activeColor : AppColors.textSecondary,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
