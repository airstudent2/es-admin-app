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

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _currentIndex = 0;
  bool _isRefreshing = false;

  final GlobalKey<NewsScreenState> _newsKey = GlobalKey();
  final GlobalKey<VipStudentsScreenState> _vipKey = GlobalKey();
  final GlobalKey<LibraryScreenState> _libraryKey = GlobalKey();
  final GlobalKey<NotificationsScreenState> _notificationsKey = GlobalKey();

  Future<void> _handleGlobalRefresh() async {
    setState(() => _isRefreshing = true);
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
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2)),
                ],
              ),
              child: const Icon(Icons.school, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Es Bangla Admin',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary, height: 1.2),
                ),
                Text(
                  'অফিশিয়াল কন্ট্রোল প্যানেল',
                  style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary, fontWeight: FontWeight.normal),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Cloud Synced Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.successLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.success.withOpacity(0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(radius: 3, backgroundColor: AppColors.success),
                SizedBox(width: 4),
                Text('ক্লাউড সিঙ্কড', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.success)),
              ],
            ),
          ),
          const SizedBox(width: 6),
          // Refresh Button
          IconButton(
            onPressed: _isRefreshing ? null : _handleGlobalRefresh,
            icon: _isRefreshing
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                : const Icon(Icons.refresh, size: 22, color: AppColors.textSecondary),
            tooltip: 'রিফ্রেশ',
          ),
          const SizedBox(width: 6),
        ],
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
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          backgroundColor: Colors.white,
          elevation: 0,
          indicatorColor: AppColors.primaryLight,
          onDestinationSelected: (index) {
            setState(() => _currentIndex = index);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.newspaper_outlined),
              selectedIcon: Icon(Icons.newspaper, color: AppColors.primary),
              label: 'নিউজ স্লাইডার',
            ),
            NavigationDestination(
              icon: Icon(Icons.workspace_premium_outlined),
              selectedIcon: Icon(Icons.workspace_premium, color: AppColors.warning),
              label: 'ভিআইপি ও ইউজার',
            ),
            NavigationDestination(
              icon: Icon(Icons.video_library_outlined),
              selectedIcon: Icon(Icons.video_library, color: AppColors.primary),
              label: 'ভিডিও লাইব্রেরি',
            ),
            NavigationDestination(
              icon: Icon(Icons.campaign_outlined),
              selectedIcon: Icon(Icons.campaign, color: AppColors.primary),
              label: 'নোটিফিকেশন',
            ),
          ],
        ),
      ),
    );
  }
}
