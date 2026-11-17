import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../services/network/api_client.dart';

class TicketDetailScreen extends StatefulWidget {
  final int ticketId;
  final String? initialCode;
  final String? initialSubject;

  const TicketDetailScreen({
    super.key,
    required this.ticketId,
    this.initialCode,
    this.initialSubject,
  });

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  final _client = ApiClient.instance;
  final _responseController = TextEditingController();
  final _scrollController = ScrollController();

  Map<String, dynamic>? _ticket;
  bool _loading = true;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTicket();
  }

  @override
  void dispose() {
    _responseController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadTicket() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await _client.get('common/tickets/${widget.ticketId}');
      if (res != null) {
        final data = res is Map<String, dynamic> && res.containsKey('data')
            ? res['data']
            : res;
        setState(() {
          _ticket = Map<String, dynamic>.from(data);
          _loading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      setState(() {
        _error = 'Məlumat yüklənərkən xəta: $e';
        _loading = false;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendResponse() async {
    final text = _responseController.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    try {
      final res = await _client.post(
        'common/tickets/${widget.ticketId}/respond',
        data: {'message': text},
      );
      _responseController.clear();
      if (res != null) {
        final data = res is Map<String, dynamic> && res.containsKey('data')
            ? res['data']
            : res;
        setState(() {
          _ticket = Map<String, dynamic>.from(data);
          _sending = false;
        });
        _scrollToBottom();
      } else {
        await _loadTicket();
        setState(() => _sending = false);
      }
    } catch (e) {
      setState(() => _sending = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Xəta baş verdi: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _claimTicket() async {
    try {
      final res = await _client.post('common/tickets/${widget.ticketId}/claim');
      if (res != null) {
        final data = res is Map<String, dynamic> && res.containsKey('data')
            ? res['data']
            : res;
        setState(() => _ticket = Map<String, dynamic>.from(data));
      } else {
        await _loadTicket();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bilet uğurla icraya götürüldü'),
            backgroundColor: AppColors.emerald,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xəta: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Future<void> _changeStatus(String newStatus) async {
    try {
      final res = await _client.post(
        'common/tickets/${widget.ticketId}/status',
        data: {'status': newStatus},
      );
      if (res != null) {
        final data = res is Map<String, dynamic> && res.containsKey('data')
            ? res['data']
            : res;
        setState(() => _ticket = Map<String, dynamic>.from(data));
      } else {
        await _loadTicket();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Status yeniləndi'),
            backgroundColor: AppColors.emerald,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xəta: $e'), backgroundColor: AppColors.danger),
        );
      }
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
        return 'Həll edildi';
      case 'closed':
        return 'Bağlandı';
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
    final code = _ticket?['code'] ?? widget.initialCode ?? '#TCK-${widget.ticketId}';
    final subject = _ticket?['subject'] ?? widget.initialSubject ?? 'Bilet təfərrüatları';
    final status = (_ticket?['status'] ?? 'open').toString();
    final priority = (_ticket?['priority'] ?? 'normal').toString();
    final deptName = _ticket?['department_name']?.toString();
    final categoryTitle = _ticket?['category_title']?.toString();
    final assignedEmp = _ticket?['assigned_employee_name']?.toString();
    final claimedEmp = _ticket?['claimed_by_employee_name']?.toString();
    final canClaim = _ticket?['can_claim'] == true;
    final canChangeStatus = _ticket?['can_change_status'] == true;
    final responses = (_ticket?['responses'] as List<dynamic>? ?? []);

    return Scaffold(
      backgroundColor: palette.bgBase,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              code,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 15,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              subject,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadTicket,
            tooltip: 'Yenilə',
          ),
          if (canChangeStatus)
            PopupMenuButton<String>(
              tooltip: 'Statusu dəyiş',
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: _changeStatus,
              itemBuilder: (ctx) => [
                const PopupMenuItem(value: 'open', child: Text('Gözləmədə')),
                const PopupMenuItem(value: 'in_progress', child: Text('İcrada')),
                const PopupMenuItem(value: 'resolved', child: Text('Həll edildi')),
                const PopupMenuItem(value: 'closed', child: Text('Bağlandı')),
                const PopupMenuItem(value: 'canceled', child: Text('Ləğv et')),
              ],
            ),
        ],
      ),
      body: _loading && _ticket == null
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _ticket == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.danger),
                      const SizedBox(height: 12),
                      Text(_error!, style: TextStyle(color: palette.textSecondary)),
                      const SizedBox(height: 12),
                      FilledButton(onPressed: _loadTicket, child: const Text('Təkrar yoxla')),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Top Info Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      decoration: BoxDecoration(
                        color: palette.surface1,
                        border: Border(bottom: BorderSide(color: palette.borderHairline)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Status pill
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
                              const SizedBox(width: 6),
                              // Priority pill
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _priorityColor(priority).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: _priorityColor(priority).withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  _priorityLabel(priority),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: _priorityColor(priority),
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                _ticket?['created_at'] ?? '',
                                style: TextStyle(fontSize: 11, color: palette.textSecondary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Category & Responsible Department Banner
                          if (categoryTitle != null || deptName != null) ...[
                            Row(
                              children: [
                                if (categoryTitle != null) ...[
                                  Icon(Icons.category_outlined, size: 13, color: palette.brandRoyal),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      categoryTitle,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: palette.brandRoyal,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                                if (categoryTitle != null && deptName != null) ...[
                                  const SizedBox(width: 8),
                                  Text('•', style: TextStyle(color: palette.textTertiary)),
                                  const SizedBox(width: 8),
                                ],
                                if (deptName != null) ...[
                                  const Icon(Icons.apartment_rounded, size: 13, color: Color(0xFF0F766E)),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      deptName,
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF0F766E),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                          ],

                          // Assigned / Claimed Employee banner
                          if (claimedEmp != null || assignedEmp != null) ...[
                            Row(
                              children: [
                                const Icon(Icons.person_pin_rounded, size: 13, color: Color(0xFF7C3AED)),
                                const SizedBox(width: 4),
                                Text(
                                  claimedEmp != null
                                      ? 'İcrada: $claimedEmp'
                                      : 'Cavabdeh: $assignedEmp',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF7C3AED),
                                  ),
                                ),
                              ],
                            ),
                          ],

                          // Claim Button for Staff
                          if (canClaim) ...[
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: palette.brandRoyal,
                                  side: BorderSide(color: palette.brandRoyal),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: const Icon(Icons.touch_app_rounded, size: 16),
                                label: const Text('Bileti İcraya Götür', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                                onPressed: _claimTicket,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Chat messages area
                    Expanded(
                      child: ListView(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        children: [
                          // Root description bubble (Ticket creator's initial problem)
                          _buildRootMessage(palette),
                          const SizedBox(height: 16),

                          // Conversation divider
                          if (responses.isNotEmpty) ...[
                            Row(
                              children: [
                                Expanded(child: Divider(color: palette.borderHairline)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  child: Text(
                                    'Yazışma Tarixçəsi (${responses.length})',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: palette.textTertiary,
                                    ),
                                  ),
                                ),
                                Expanded(child: Divider(color: palette.borderHairline)),
                              ],
                            ),
                            const SizedBox(height: 14),
                          ],

                          // Responses bubbles
                          for (final resp in responses) ...[
                            _buildResponseBubble(resp, palette),
                            const SizedBox(height: 12),
                          ],
                        ],
                      ),
                    ),

                    // Reply Bottom Input Bar
                    Container(
                      padding: EdgeInsets.fromLTRB(14, 8, 14, MediaQuery.paddingOf(context).bottom + 8),
                      decoration: BoxDecoration(
                        color: palette.surface1,
                        border: Border(top: BorderSide(color: palette.borderHairline)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _responseController,
                              maxLines: 4,
                              minLines: 1,
                              decoration: InputDecoration(
                                hintText: 'Cavabınızı daxil edin...',
                                hintStyle: TextStyle(fontSize: 13, color: palette.textTertiary),
                                isDense: true,
                                filled: true,
                                fillColor: palette.surface2,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide(color: palette.borderHairline),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide(color: palette.borderHairline),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            style: IconButton.styleFrom(
                              backgroundColor: palette.brandRoyal,
                              shape: const CircleBorder(),
                            ),
                            onPressed: _sending ? null : _sendResponse,
                            icon: _sending
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Icon(Icons.send_rounded, size: 18, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildRootMessage(AppPalette palette) {
    final creatorName = _ticket?['creator_name'] ?? 'Müraciətçi';
    final creatorRole = _ticket?['creator_type'] ?? '';
    final description = _ticket?['description'] ?? 'Təsvir qeyd edilməyib.';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.borderHairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: palette.brandRoyal.withValues(alpha: 0.12),
                child: Text(
                  creatorName.isNotEmpty ? creatorName[0].toUpperCase() : 'M',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: palette.brandRoyal,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      creatorName,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                    if (creatorRole.isNotEmpty)
                      Text(
                        creatorRole,
                        style: TextStyle(fontSize: 10.5, color: palette.textSecondary),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: palette.surface2,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('Əsas Müraciət', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.4,
              color: palette.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponseBubble(Map<String, dynamic> resp, AppPalette palette) {
    final isMe = resp['is_me'] == true;
    final name = resp['creator_name'] ?? 'İstifadəçi';
    final msg = resp['message'] ?? '';
    final time = resp['created_at'] ?? '';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? palette.brandRoyal : palette.surface1,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          border: isMe ? null : Border.all(color: palette.borderHairline),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Text(
                name,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: palette.brandRoyal,
                ),
              ),
            if (!isMe) const SizedBox(height: 3),
            Text(
              msg,
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                color: isMe ? Colors.white : palette.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                fontSize: 9.5,
                color: isMe ? Colors.white70 : palette.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
