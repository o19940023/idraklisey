import 'package:flutter/material.dart';
import '../../../core/network/api_page.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/app_search_bar.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../services/network/api_client.dart';
import 'create_ticket_screen.dart';
import 'ticket_detail_screen.dart';

class TicketsListView extends StatefulWidget {
  final bool isStaff;

  const TicketsListView({
    super.key,
    this.isStaff = false,
  });

  @override
  State<TicketsListView> createState() => _TicketsListViewState();
}

class _TicketsListViewState extends State<TicketsListView> {
  final _client = ApiClient.instance;
  final _searchCtrl = TextEditingController();

  List<Map<String, dynamic>> _tickets = [];
  bool _loading = true;
  String? _error;

  String _scope = 'all'; // 'all', 'my'
  String _statusFilter = 'all'; // 'all', 'open', 'in_progress', 'resolved', 'closed'

  final List<(String, String)> _statusOptions = [
    ('all', 'Hamısı'),
    ('open', 'Gözləmədə'),
    ('in_progress', 'İcrada'),
    ('resolved', 'Həll edilib'),
    ('closed', 'Bağlanıb'),
  ];

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTickets() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final queryParams = <String, dynamic>{
        'per_page': 50,
        if (_scope == 'my') 'scope': 'my',
        if (_statusFilter != 'all') 'status': _statusFilter,
        if (_searchCtrl.text.trim().isNotEmpty) 'q': _searchCtrl.text.trim(),
      };

      final res = await _client.get('common/tickets', query: queryParams);
      final page = parsePage(res);
      setState(() {
        _tickets = page.items;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Biletlər yüklənərkən xəta: $e';
        _loading = false;
      });
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return const Color(0xFF2563EB);
      case 'in_progress':
        return const Color(0xFFD97706);
      case 'resolved':
        return AppColors.emerald;
      case 'closed':
        return const Color(0xFF475569);
      case 'canceled':
        return AppColors.danger;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return 'Gözləmədə';
      case 'in_progress':
        return 'İcrada';
      case 'resolved':
        return 'Həll edilib';
      case 'closed':
        return 'Bağlanıb';
      case 'canceled':
        return 'Ləğv edildi';
      default:
        return status;
    }
  }

  Color _priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return AppColors.danger;
      case 'high':
        return const Color(0xFFEA580C);
      case 'medium':
      case 'normal':
        return const Color(0xFF0284C7);
      case 'low':
      default:
        return const Color(0xFF10B981);
    }
  }

  String _priorityLabel(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return 'Təcili';
      case 'high':
        return 'Yüksək';
      case 'medium':
      case 'normal':
        return 'Normal';
      case 'low':
        return 'Aşağı';
      default:
        return priority;
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: palette.brandRoyal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_comment_rounded, size: 18),
        label: const Text('Yeni Bilet', style: TextStyle(fontWeight: FontWeight.w800)),
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const CreateTicketScreen()),
          );
          if (created == true) _loadTickets();
        },
      ),
      body: Column(
        children: [
          // Staff Scope Switcher (Biletlərim vs Departamentə gələnlər)
          if (widget.isStaff) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: Container(
                decoration: BoxDecoration(
                  color: palette.surface1,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: palette.borderHairline),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          if (_scope != 'all') {
                            setState(() => _scope = 'all');
                            _loadTickets();
                          }
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _scope == 'all' ? palette.brandRoyal : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Departamentə Gələnlər',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: _scope == 'all' ? FontWeight.w800 : FontWeight.w600,
                              color: _scope == 'all' ? Colors.white : palette.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          if (_scope != 'my') {
                            setState(() => _scope = 'my');
                            _loadTickets();
                          }
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _scope == 'my' ? palette.brandRoyal : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Mənim Biletlərim',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: _scope == 'my' ? FontWeight.w800 : FontWeight.w600,
                              color: _scope == 'my' ? Colors.white : palette.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: AppSearchBar(
              controller: _searchCtrl,
              hintText: 'Bilet kodu, mövzu və ya təsvir ilə axtar...',
              onChanged: (_) => _loadTickets(),
              onClear: () {
                _searchCtrl.clear();
                _loadTickets();
              },
            ),
          ),

          // Status filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: _statusOptions.map((opt) {
                final isSelected = _statusFilter == opt.$1;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(opt.$2),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) {
                        setState(() => _statusFilter = opt.$1);
                        _loadTickets();
                      }
                    },
                    selectedColor: palette.brandRoyal,
                    labelStyle: TextStyle(
                      fontSize: 11.5,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? Colors.white : palette.textPrimary,
                    ),
                    backgroundColor: palette.surface1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: isSelected ? palette.brandRoyal : palette.borderHairline),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Tickets List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadTickets,
              child: _loading && _tickets.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null && _tickets.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.danger),
                              const SizedBox(height: 12),
                              Text(_error!, style: TextStyle(color: palette.textSecondary)),
                              const SizedBox(height: 12),
                              FilledButton(onPressed: _loadTickets, child: const Text('Yenidən yoxla')),
                            ],
                          ),
                        )
                      : _tickets.isEmpty
                          ? EmptyStateWidget(
                              icon: Icons.confirmation_number_outlined,
                              title: 'Bilet Tapılmadı',
                              message: 'Bu kateqoriyada heç bir dəstək bileti qeydə alınmayıb.',
                              actionLabel: 'Yeni Bilet Yarat',
                              onAction: () async {
                                final created = await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute(builder: (_) => const CreateTicketScreen()),
                                );
                                if (created == true) _loadTickets();
                              },
                            )
                          : ListView.separated(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                              itemCount: _tickets.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 10),
                              itemBuilder: (ctx, i) {
                                final t = _tickets[i];
                                final id = t['id'] as int? ?? 0;
                                final code = t['code']?.toString() ?? '#TCK-$id';
                                final subject = t['subject']?.toString() ?? 'Mövzu yoxdur';
                                final desc = t['description']?.toString() ?? '';
                                final status = t['status']?.toString() ?? 'open';
                                final priority = t['priority']?.toString() ?? 'normal';
                                final category = t['category_title']?.toString();
                                final dept = t['department_name']?.toString();
                                final responsesCount = t['responses_count'] as int? ?? 0;
                                final claimedEmp = t['claimed_by_employee_name']?.toString();
                                final isSub = t['is_sub_ticket'] == true;

                                return InkWell(
                                  onTap: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => TicketDetailScreen(
                                          ticketId: id,
                                          initialCode: code,
                                          initialSubject: subject,
                                        ),
                                      ),
                                    );
                                    _loadTickets();
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: palette.surface1,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: palette.borderHairline),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Header Row: Code, Priority, Status
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: palette.brandRoyal.withValues(alpha: 0.08),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                code,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w800,
                                                  color: palette.brandRoyal,
                                                ),
                                              ),
                                            ),
                                            if (isSub) ...[
                                              const SizedBox(width: 4),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: const Text('Alt bilet', style: TextStyle(fontSize: 9.5, color: Color(0xFF0284C7), fontWeight: FontWeight.bold)),
                                              ),
                                            ],
                                            const SizedBox(width: 6),
                                            // Priority tag
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: _priorityColor(priority).withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                _priorityLabel(priority),
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                  color: _priorityColor(priority),
                                                ),
                                              ),
                                            ),
                                            const Spacer(),
                                            // Status badge
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: _statusColor(status).withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: _statusColor(status).withValues(alpha: 0.3)),
                                              ),
                                              child: Text(
                                                _statusLabel(status),
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w800,
                                                  color: _statusColor(status),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),

                                        // Subject
                                        Text(
                                          subject,
                                          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (desc.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            desc,
                                            style: TextStyle(fontSize: 12, color: palette.textSecondary, height: 1.3),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                        const SizedBox(height: 10),

                                        // Footer Row: Responsible Department & Message Count
                                        Row(
                                          children: [
                                            if (dept != null || category != null) ...[
                                              const Icon(Icons.apartment_rounded, size: 13, color: Color(0xFF0F766E)),
                                              const SizedBox(width: 4),
                                              Flexible(
                                                child: Text(
                                                  dept ?? category ?? '',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF0F766E),
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                            if (claimedEmp != null) ...[
                                              const SizedBox(width: 8),
                                              const Text('•', style: TextStyle(color: Colors.grey)),
                                              const SizedBox(width: 8),
                                              Flexible(
                                                child: Text(
                                                  claimedEmp,
                                                  style: TextStyle(fontSize: 11, color: palette.textTertiary),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                            const Spacer(),
                                            if (responsesCount > 0) ...[
                                              const Icon(Icons.forum_outlined, size: 13, color: Colors.grey),
                                              const SizedBox(width: 4),
                                              Text(
                                                '$responsesCount',
                                                style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w700),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ),
        ],
      ),
    );
  }
}
