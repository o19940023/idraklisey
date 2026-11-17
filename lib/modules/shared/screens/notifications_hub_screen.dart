import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/network/api_page.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/navigation_utils.dart';
import '../../../providers/app_state.dart';
import '../../../services/network/api_client.dart';
import '../../tickets/screens/tickets_list_view.dart';

class NotificationsHubScreen extends StatefulWidget {
  final int initialTabIndex;

  const NotificationsHubScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  State<NotificationsHubScreen> createState() => _NotificationsHubScreenState();
}

class _NotificationsHubScreenState extends State<NotificationsHubScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _client = ApiClient.instance;

  List<Map<String, dynamic>> _notifications = [];
  bool _loadingNotifs = true;
  String? _notifError;
  String _notifFilter = 'all'; // all, unread

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTabIndex);
    _loadNotifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _syncUnreadCountToAppState() {
    if (!mounted) return;
    final unread = _notifications.where((n) => n['is_read'] != true).length;
    context.read<AppState>().setApiUnreadNotificationCount(unread);
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _loadingNotifs = true;
      _notifError = null;
    });

    try {
      final res = await _client.get('common/notifications', query: {'per_page': 50});
      final page = parsePage(res);
      if (!mounted) return;
      setState(() {
        _notifications = page.items;
        _loadingNotifs = false;
      });
      _syncUnreadCountToAppState();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _notifError = 'Bildirişlər yüklənərkən xəta: $e';
        _loadingNotifs = false;
      });
    }
  }

  Future<void> _markRead(int id) async {
    try {
      await _client.post('common/notifications/$id/read');
      if (!mounted) return;
      setState(() {
        final idx = _notifications.indexWhere((n) => n['id'] == id);
        if (idx >= 0) {
          _notifications[idx] = {..._notifications[idx], 'is_read': true};
        }
      });
      _syncUnreadCountToAppState();
    } catch (_) {}
  }

  Future<void> _markAllRead() async {
    try {
      await _client.post('common/notifications/read-all');
      if (!mounted) return;
      setState(() {
        _notifications = _notifications.map((n) => {...n, 'is_read': true}).toList();
      });
      _syncUnreadCountToAppState();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bütün bildirişlər oxundu'), duration: Duration(seconds: 1)),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final session = context.watch<SessionController>();
    final isStaff = session.profile?.isStaff == true;
    final unreadCount = _notifications.where((n) => n['is_read'] != true).length;

    return Scaffold(
      backgroundColor: palette.bgBase,
      appBar: AppBar(
        title: const Text(
          'Bildirişlər və Dəstək',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
        ),
        backgroundColor: AppColors.primary,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          if (unreadCount > 0)
            TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.goldLight,
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              icon: const Icon(Icons.done_all_rounded, size: 16),
              label: const Text('Hamısını Oxu', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
              onPressed: _markAllRead,
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.goldLight,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.notifications_none_rounded, size: 18),
                  const SizedBox(width: 6),
                  const Text('Bildirişlər'),
                  if (unreadCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
                      child: Text(
                        '$unreadCount',
                        style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.support_agent_rounded, size: 18),
                  SizedBox(width: 6),
                  Text('Dəstək Biletləri'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── Tab 1: Bildirişlər ──
          _buildNotificationsTab(palette),

          // ── Tab 2: Dəstək Biletləri ──
          TicketsListView(isStaff: isStaff),
        ],
      ),
    );
  }

  Widget _buildNotificationsTab(AppPalette palette) {
    final filtered = _notifications.where((n) {
      if (_notifFilter == 'unread') return n['is_read'] != true;
      return true;
    }).toList();

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: Column(
        children: [
          // Filter Row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: Row(
              children: [
                ChoiceChip(
                  label: Text('Hamısı (${_notifications.length})'),
                  selected: _notifFilter == 'all',
                  onSelected: (val) {
                    if (val) setState(() => _notifFilter = 'all');
                  },
                  selectedColor: palette.brandRoyal,
                  labelStyle: TextStyle(
                    fontSize: 11.5,
                    fontWeight: _notifFilter == 'all' ? FontWeight.w800 : FontWeight.w600,
                    color: _notifFilter == 'all' ? Colors.white : palette.textPrimary,
                  ),
                  backgroundColor: palette.surface1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: palette.borderHairline)),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text('Oxunmamış (${_notifications.where((n) => n['is_read'] != true).length})'),
                  selected: _notifFilter == 'unread',
                  onSelected: (val) {
                    if (val) setState(() => _notifFilter = 'unread');
                  },
                  selectedColor: palette.brandRoyal,
                  labelStyle: TextStyle(
                    fontSize: 11.5,
                    fontWeight: _notifFilter == 'unread' ? FontWeight.w800 : FontWeight.w600,
                    color: _notifFilter == 'unread' ? Colors.white : palette.textPrimary,
                  ),
                  backgroundColor: palette.surface1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: palette.borderHairline)),
                ),
              ],
            ),
          ),

          // Notifications List
          Expanded(
            child: _loadingNotifs && _notifications.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _notifError != null && _notifications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.danger),
                            const SizedBox(height: 12),
                            Text(_notifError!, style: TextStyle(color: palette.textSecondary)),
                            const SizedBox(height: 12),
                            FilledButton(onPressed: _loadNotifications, child: const Text('Yenidən yoxla')),
                          ],
                        ),
                      )
                    : filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.notifications_off_outlined, size: 54, color: palette.textTertiary.withValues(alpha: 0.5)),
                                const SizedBox(height: 12),
                                Text('Bildiriş tapılmadı', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: palette.textSecondary)),
                              ],
                            ),
                          )
                        : ListView.separated(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 6, 16, 40),
                            itemCount: filtered.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 8),
                            itemBuilder: (ctx, i) {
                              final n = filtered[i];
                              final id = n['id'] as int? ?? 0;
                              final title = n['title']?.toString() ?? 'Bildiriş';
                              final body = (n['message'] ?? n['body'] ?? '').toString();
                              final time = n['created_at']?.toString() ?? '';
                              final isRead = n['is_read'] == true;

                              return InkWell(
                                onTap: () {
                                  if (!isRead) _markRead(id);
                                },
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isRead ? palette.surface1 : palette.surface2,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isRead ? palette.borderHairline : palette.brandRoyal.withValues(alpha: 0.35),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: isRead
                                              ? palette.surface3
                                              : palette.brandRoyal.withValues(alpha: 0.12),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          isRead ? Icons.notifications_none_rounded : Icons.notifications_active_rounded,
                                          size: 18,
                                          color: isRead ? palette.textTertiary : palette.brandRoyal,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    title,
                                                    style: TextStyle(
                                                      fontSize: 13.5,
                                                      fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                                                      color: palette.textPrimary,
                                                    ),
                                                  ),
                                                ),
                                                if (!isRead)
                                                  Container(
                                                    width: 7,
                                                    height: 7,
                                                    decoration: const BoxDecoration(
                                                      color: AppColors.danger,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            if (body.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                body,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: palette.textSecondary,
                                                  height: 1.3,
                                                ),
                                              ),
                                            ],
                                            const SizedBox(height: 6),
                                            Text(
                                              time,
                                              style: TextStyle(fontSize: 10, color: palette.textTertiary),
                                            ),
                                          ],
                                        ),
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
    );
  }
}
