import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../services/network/api_client.dart';

class CreateTicketScreen extends StatefulWidget {
  final int? parentId;
  final String? parentCode;

  const CreateTicketScreen({
    super.key,
    this.parentId,
    this.parentCode,
  });

  @override
  State<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends State<CreateTicketScreen> {
  final _client = ApiClient.instance;
  final _subjectCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  List<Map<String, dynamic>> _categories = [];
  bool _loadingCategories = true;
  int? _selectedCategoryId;
  String _selectedPriority = 'normal';
  bool _submitting = false;

  final List<(String, String, Color)> _priorities = [
    ('low', 'Aşağı', Color(0xFF10B981)),
    ('normal', 'Normal', Color(0xFF0284C7)),
    ('high', 'Yüksək', Color(0xFFEA580C)),
    ('urgent', 'Təcili', AppColors.danger),
  ];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final res = await _client.get('common/tickets/categories');
      if (res != null) {
        final data = res is Map<String, dynamic> && res.containsKey('data')
            ? res['data']
            : res;
        if (data is List) {
          setState(() {
            _categories = data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
            if (_categories.isNotEmpty) {
              _selectedCategoryId = _categories[0]['id'] as int?;
            }
            _loadingCategories = false;
          });
          return;
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _loadingCategories = false);
    }
  }

  Map<String, dynamic>? get _currentCategory {
    if (_selectedCategoryId == null) return null;
    return _categories.firstWhere(
      (c) => c['id'] == _selectedCategoryId,
      orElse: () => {},
    );
  }

  Future<void> _submit() async {
    final subject = _subjectCtrl.text.trim();
    final desc = _descCtrl.text.trim();

    if (subject.isEmpty) {
      _snack('Mövzu daxil edilməlidir', isError: true);
      return;
    }
    if (desc.isEmpty) {
      _snack('Təsvir daxil edilməlidir', isError: true);
      return;
    }

    setState(() => _submitting = true);

    try {
      final payload = {
        'subject': subject,
        'description': desc,
        'priority': _selectedPriority,
        if (_selectedCategoryId != null) 'ticket_category_id': _selectedCategoryId,
        if (widget.parentId != null) 'parent_id': widget.parentId,
      };

      final res = await _client.post('common/tickets', data: payload);
      if (res != null) {
        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        _snack('Xəta baş verdi', isError: true);
      }
    } catch (e) {
      _snack('Bilet göndərilərkən xəta: $e', isError: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _snack(String text, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: isError ? AppColors.danger : AppColors.emerald,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final currentCat = _currentCategory;
    final catStructures = (currentCat?['structures'] as List<dynamic>? ?? []).join(', ');

    return Scaffold(
      backgroundColor: palette.bgBase,
      appBar: AppBar(
        title: Text(
          widget.parentId != null ? 'Alt Bilet Yarat (#${widget.parentCode})' : 'Yeni Dəstək Bileti',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16.5),
        ),
        backgroundColor: AppColors.primary,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Parent ticket banner if sub-ticket
            if (widget.parentId != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.subdirectory_arrow_right_rounded, color: Color(0xFF0284C7)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Bu bilet #${widget.parentCode} nömrəli əsas biletə bağlı alt tapşırıq kimi yaradılacaq.',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0284C7)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Subject field
            Text('Mövzu *', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: palette.textPrimary)),
            const SizedBox(height: 6),
            TextField(
              controller: _subjectCtrl,
              decoration: InputDecoration(
                hintText: 'Məsələn: Sinifdəki proyektor işləmir...',
                filled: true,
                fillColor: palette.surface1,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: palette.borderHairline)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: palette.borderHairline)),
              ),
            ),
            const SizedBox(height: 14),

            // Category Picker
            Text('Bilet Kateqoriyası *', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: palette.textPrimary)),
            const SizedBox(height: 6),
            if (_loadingCategories)
              const LinearProgressIndicator()
            else
              DropdownButtonFormField<int>(
                value: _selectedCategoryId,
                isExpanded: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: palette.surface1,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: palette.borderHairline)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: palette.borderHairline)),
                ),
                items: _categories.map((c) {
                  return DropdownMenuItem<int>(
                    value: c['id'] as int?,
                    child: Text(c['title']?.toString() ?? '', overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedCategoryId = val),
              ),

            // Auto-assigned Department Routing Banner
            if (catStructures.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F766E).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF0F766E).withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.apartment_rounded, size: 16, color: Color(0xFF0F766E)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Bu bilet avtomatik olaraq "$catStructures" departamentinə yönləndiriləcək.',
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF0F766E)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),

            // Priority Selector
            Text('Prioritet / Təcililik', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: palette.textPrimary)),
            const SizedBox(height: 6),
            Row(
              children: _priorities.map((p) {
                final isSelected = _selectedPriority == p.$1;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: InkWell(
                      onTap: () => setState(() => _selectedPriority = p.$1),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? p.$3.withValues(alpha: 0.15) : palette.surface1,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? p.$3 : palette.borderHairline,
                            width: isSelected ? 1.8 : 1.0,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          p.$2,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? p.$3 : palette.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Description
            Text('Ətraflı Təsvir *', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: palette.textPrimary)),
            const SizedBox(height: 6),
            TextField(
              controller: _descCtrl,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: 'Məsələni ətraflı şəkildə izah edin...',
                filled: true,
                fillColor: palette.surface1,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: palette.borderHairline)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: palette.borderHairline)),
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: palette.brandRoyal,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.send_rounded, size: 18),
              label: Text(
                _submitting ? 'Göndərilir...' : 'Bileti Göndər',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
