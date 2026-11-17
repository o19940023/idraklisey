import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/app_search_bar.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../services/network/api_client.dart';

class TicketCategoriesScreen extends StatefulWidget {
  const TicketCategoriesScreen({super.key});

  @override
  State<TicketCategoriesScreen> createState() => _TicketCategoriesScreenState();
}

class _TicketCategoriesScreenState extends State<TicketCategoriesScreen> {
  final _client = ApiClient.instance;
  final _searchCtrl = TextEditingController();

  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _allStructures = [];
  List<Map<String, dynamic>> _allPositions = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _client.get('common/tickets/categories'),
        _client.get('common/tickets/categories/meta'),
      ]);

      final catRes = results[0];
      final metaRes = results[1];

      final catData = catRes is Map && catRes.containsKey('data') ? catRes['data'] : catRes;
      final metaData = metaRes is Map && metaRes.containsKey('data') ? metaRes['data'] : metaRes;

      if (mounted) {
        setState(() {
          if (catData is List) {
            _categories = catData.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          }
          if (metaData is Map) {
            if (metaData['structures'] is List) {
              _allStructures = (metaData['structures'] as List)
                  .map((e) => Map<String, dynamic>.from(e as Map))
                  .toList();
            }
            if (metaData['positions'] is List) {
              _allPositions = (metaData['positions'] as List)
                  .map((e) => Map<String, dynamic>.from(e as Map))
                  .toList();
            }
          }
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Kateqoriyalar yüklənərkən xəta: $e';
          _loading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get _filteredCategories {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return _categories;
    return _categories.where((c) {
      final title = (c['title'] ?? '').toString().toLowerCase();
      final structures = (c['structures'] as List? ?? []).join(' ').toLowerCase();
      final positions = (c['positions'] as List? ?? []).join(' ').toLowerCase();
      return title.contains(q) || structures.contains(q) || positions.contains(q);
    }).toList();
  }

  Future<void> _showCategoryForm({Map<String, dynamic>? existing}) async {
    final palette = AppPalette.of(context);
    final isEdit = existing != null;
    final titleCtrl = TextEditingController(text: existing?['title']?.toString() ?? '');
    final selectedStructures = <int>{
      ...(existing?['structure_ids'] as List? ?? [])
          .map((e) => int.tryParse(e.toString()) ?? 0)
          .where((id) => id > 0),
    };
    final selectedPositions = <int>{
      ...(existing?['position_ids'] as List? ?? [])
          .map((e) => int.tryParse(e.toString()) ?? 0)
          .where((id) => id > 0),
    };
    bool saving = false;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          return Container(
            height: MediaQuery.of(ctx).size.height * 0.86,
            padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.viewInsetsOf(ctx).bottom + 20),
            decoration: BoxDecoration(
              color: palette.surface1,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: palette.textTertiary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF9333EA).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.category_rounded, color: Color(0xFF9333EA), size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isEdit ? 'Kateqoriyanı Redaktə Et' : 'Yeni Bilet Kateqoriyası',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx, false),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Kateqoriya Adı *', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: palette.textPrimary)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: titleCtrl,
                          decoration: InputDecoration(
                            hintText: 'Məsələn: İT və Texniki Dəstək',
                            filled: true,
                            fillColor: palette.surface2,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: palette.borderHairline)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Təyin Edilmiş Strukturlar (Departamentlər) (${selectedStructures.length} seçilib)',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: palette.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Bu kateqoriyada açılan biletlər seçilmiş strukturlara və onların alt bölmələrinə yönləndiriləcək.',
                          style: TextStyle(fontSize: 11.5, color: palette.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _allStructures.map((s) {
                            final id = s['id'] as int? ?? 0;
                            final title = s['title']?.toString() ?? '';
                            final isSelected = selectedStructures.contains(id);
                            return FilterChip(
                              label: Text(title),
                              selected: isSelected,
                              onSelected: (val) {
                                setSheet(() {
                                  if (val) {
                                    selectedStructures.add(id);
                                  } else {
                                    selectedStructures.remove(id);
                                  }
                                });
                              },
                              selectedColor: const Color(0xFF0F766E).withValues(alpha: 0.18),
                              checkmarkColor: const Color(0xFF0F766E),
                              labelStyle: TextStyle(
                                fontSize: 11.5,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                color: isSelected ? const Color(0xFF0F766E) : palette.textPrimary,
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Məsul Rəhbər Vəzifələr (${selectedPositions.length} seçilib)',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: palette.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Seçilmiş strukturlarda bu vəzifəni daşıyan rəhbər əməkdaşlara bilet avtomatik təyin ediləcək.',
                          style: TextStyle(fontSize: 11.5, color: palette.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _allPositions.map((p) {
                            final id = p['id'] as int? ?? 0;
                            final title = p['title']?.toString() ?? '';
                            final isSelected = selectedPositions.contains(id);
                            return FilterChip(
                              label: Text(title),
                              selected: isSelected,
                              onSelected: (val) {
                                setSheet(() {
                                  if (val) {
                                    selectedPositions.add(id);
                                  } else {
                                    selectedPositions.remove(id);
                                  }
                                });
                              },
                              selectedColor: palette.brandRoyal.withValues(alpha: 0.16),
                              checkmarkColor: palette.brandRoyal,
                              labelStyle: TextStyle(
                                fontSize: 11.5,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                color: isSelected ? palette.brandRoyal : palette.textPrimary,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF9333EA),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: saving
                      ? null
                      : () async {
                          final title = titleCtrl.text.trim();
                          if (title.isEmpty) return;
                          setSheet(() => saving = true);
                          try {
                            final payload = {
                              'title': title,
                              'structure_ids': selectedStructures.toList(),
                              'lead_position_ids': selectedPositions.toList(),
                            };
                            if (isEdit) {
                              await _client.put('common/tickets/categories/${existing['id']}', data: payload);
                            } else {
                              await _client.post('common/tickets/categories', data: payload);
                            }
                            if (ctx.mounted) Navigator.pop(ctx, true);
                          } catch (e) {
                            setSheet(() => saving = false);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Xəta: $e'), backgroundColor: AppColors.danger),
                              );
                            }
                          }
                        },
                  icon: saving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.save_rounded, size: 18),
                  label: Text(isEdit ? 'Yadda Saxla' : 'Kateqoriya Yarat', style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          );
        },
      ),
    );

    if (saved == true) {
      _loadData();
    }
  }

  Future<void> _deleteCategory(Map<String, dynamic> cat) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kateqoriyanı sil'),
        content: Text('"${cat['title']}" kateqoriyasını silmək istədiyinizə əminsiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Ləğv et')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _client.delete('common/tickets/categories/${cat['id']}');
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Silinmə xətası: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final session = context.watch<SessionController>();
    final canManage = session.profile?.isSuper == true ||
        session.can('gopanel.tickets.categories.create') ||
        session.can('gopanel.tickets.categories.update');

    final items = _filteredCategories;

    return Scaffold(
      backgroundColor: palette.bgBase,
      appBar: AppBar(
        title: const Text(
          'Bilet Kateqoriyaları və Strukturlar',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16.5),
        ),
        backgroundColor: AppColors.primary,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
            tooltip: 'Yenilə',
          ),
        ],
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              backgroundColor: const Color(0xFF9333EA),
              foregroundColor: Colors.white,
              onPressed: () => _showCategoryForm(),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Yeni Kateqoriya', style: TextStyle(fontWeight: FontWeight.w800)),
            )
          : null,
      body: Column(
        children: [
          // Top Info Banner
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF9333EA).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF9333EA).withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_tree_rounded, color: Color(0xFF9333EA), size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Hər bir bilet kateqoriyası müvafiq departament (struktur) və rəhbər vəzifələrə bağlanır. Yeni bilet yaradıldıqda sistem avtomatik olaraq həmin struktura və rəhbərə yönləndirir.',
                    style: TextStyle(fontSize: 11.5, color: palette.textPrimary, height: 1.3),
                  ),
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: AppSearchBar(
              controller: _searchCtrl,
              hintText: 'Kateqoriya, struktur və ya vəzifə axtar...',
              onChanged: (_) => setState(() {}),
              onClear: () {
                _searchCtrl.clear();
                setState(() {});
              },
            ),
          ),

          // List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              child: _loading && _categories.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null && _categories.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.danger),
                              const SizedBox(height: 10),
                              Text(_error!, style: TextStyle(color: palette.textSecondary)),
                              const SizedBox(height: 10),
                              FilledButton(onPressed: _loadData, child: const Text('Yenidən yoxla')),
                            ],
                          ),
                        )
                      : items.isEmpty
                          ? EmptyStateWidget(
                              icon: Icons.category_outlined,
                              title: 'Kateqoriya Tapılmadı',
                              message: 'Heç bir bilet kateqoriyası tapılmadı.',
                              actionLabel: canManage ? 'Yeni Kateqoriya' : null,
                              onAction: canManage ? () => _showCategoryForm() : null,
                            )
                          : ListView.separated(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                              itemCount: items.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 10),
                              itemBuilder: (ctx, i) {
                                final cat = items[i];
                                final title = cat['title']?.toString() ?? 'Kateqoriya';
                                final ticketsCount = cat['tickets_count'] as int? ?? 0;
                                final structures = (cat['structures'] as List? ?? []).map((e) => e.toString()).toList();
                                final positions = (cat['positions'] as List? ?? []).map((e) => e.toString()).toList();
                                final leadEmployees = (cat['lead_employees'] as List? ?? [])
                                    .map((e) => Map<String, dynamic>.from(e as Map))
                                    .toList();

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
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF9333EA).withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: const Icon(Icons.category_rounded, color: Color(0xFF9333EA), size: 18),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  title,
                                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                                                ),
                                                Text(
                                                  'ID: #${cat['id']}  •  $ticketsCount müraciət',
                                                  style: TextStyle(fontSize: 11.5, color: palette.textSecondary),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (canManage) ...[
                                            IconButton(
                                              icon: Icon(Icons.edit_outlined, size: 19, color: palette.brandRoyal),
                                              onPressed: () => _showCategoryForm(existing: cat),
                                              tooltip: 'Redaktə et',
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline_rounded, size: 19, color: AppColors.danger),
                                              onPressed: () => _deleteCategory(cat),
                                              tooltip: 'Sil',
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      // Assigned Structures
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Icon(Icons.apartment_rounded, size: 15, color: Color(0xFF0F766E)),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              structures.isNotEmpty
                                                  ? 'Struktur: ${structures.join(", ")}'
                                                  : 'Struktur təyin edilməyib',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: structures.isNotEmpty ? const Color(0xFF0F766E) : palette.textTertiary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (positions.isNotEmpty) ...[
                                        const SizedBox(height: 5),
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Icon(Icons.badge_outlined, size: 15, color: palette.brandRoyal),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                'Məsul vəzifə: ${positions.join(", ")}',
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w600,
                                                  color: palette.brandRoyal,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                      if (leadEmployees.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: leadEmployees.map((emp) {
                                            final empName = emp['name']?.toString() ?? '';
                                            final empPos = emp['position']?.toString() ?? '';
                                            return Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: palette.surface2,
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: palette.borderHairline),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.person_pin_rounded, size: 13, color: Color(0xFF7C3AED)),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    empPos.isNotEmpty ? '$empName ($empPos)' : empName,
                                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: palette.textPrimary),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ],
                                    ],
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
