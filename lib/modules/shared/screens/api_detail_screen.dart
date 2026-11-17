import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';

/// Renders an API object with human friendly labels.
class ApiDetailScreen extends StatelessWidget {
  const ApiDetailScreen({super.key, required this.title, required this.data});

  final String title;
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), centerTitle: false),
      body: ApiDetailBody(data: data),
    );
  }
}

/// Shared body used by detail and aggregate screens.
class ApiDetailBody extends StatelessWidget {
  const ApiDetailBody({super.key, required this.data});

  final Map<String, dynamic> data;

  static const _labels = <String, String>{
    'id': 'ID',
    'code': 'Kod',
    'name': 'Ad',
    'full_name': 'Ad Soyad',
    'surname': 'Soyad',
    'father_name': 'Ata adı',
    'fin_code': 'FİN kod',
    'email': 'E-poçt',
    'phone': 'Telefon',
    'class_name': 'Sinif',
    'grade_level': 'Sinif səviyyəsi',
    'grade_language': 'Təhsil dili',
    'position': 'Vəzifə',
    'structure': 'Struktur',
    'status': 'Status',
    'status_key': 'Status açarı',
    'category': 'Kateqoriya',
    'author': 'Müəllif',
    'title': 'Başlıq',
    'subject': 'Fənn/Mövzu',
    'teacher': 'Müəllim',
    'student': 'Şagird',
    'student_name': 'Şagird',
    'amount': 'Məbləğ',
    'total_amount': 'Ümumi məbləğ',
    'final_amount': 'Yekun məbləğ',
    'paid_amount': 'Ödənilib',
    'remaining_amount': 'Qalıq',
    'start_date': 'Başlama tarixi',
    'end_date': 'Bitmə tarixi',
    'due_date': 'Son tarix',
    'created_at': 'Yaradılma',
    'updated_at': 'Yenilənmə',
    'is_active': 'Aktiv',
    'book_title': 'Kitab',
    'inventory_code': 'İnventar kodu',
    'quantity': 'Miqdar',
    'price': 'Qiymət',
    'priority': 'Prioritet',
    'message': 'Mesaj',
    'description': 'Təsvir',
    'note': 'Qeyd',
    'notes': 'Qeydlər',
    'students': 'Şagirdlər',
    'employees': 'Əməkdaşlar',
    'classes': 'Siniflər',
    'books': 'Kitablar',
    'days': 'Günlər',
    'items': 'Siyahı',
    'breakdown': 'Bölgü',
    'overloaded_count': 'Həddindən artıq yüklənən',
    'overload_threshold': 'Həftəlik limit',
    'payments_total': 'Ödənişlər cəmi',
    'debt_total': 'Borc',
    'contracts_total': 'Müqavilələr cəmi',
    'active': 'Aktiv',
    'total': 'Cəmi',
    'present': 'İştirak edib',
    'absent': 'İştirak etməyib',
    'late': 'Gecikib',
    'excused': 'Üzrlü',
    'from': 'Başlanğıc',
    'to': 'Son',
    'year': 'İl',
    'month': 'Ay',
    'label': 'Ad',
    'new_students': 'Yeni şagirdlər',
    'payments': 'Ödənişlər',
  };

  static const _hiddenKeys = {
    'password',
    'remember_token',
    'deleted_at',
    'photo_url',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = data.entries
        .where((e) => !_hiddenKeys.contains(e.key) && e.value != null && e.value.toString().isNotEmpty)
        .toList();

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: entries.length,
      separatorBuilder: (_, __) => Divider(color: theme.colorScheme.outlineVariant.withAlpha(80)),
      itemBuilder: (context, index) {
        final entry = entries[index];
        final label = _labels[entry.key] ?? _humanize(entry.key);
        final value = entry.value;

        if (value is Map) {
          return _section(label, Map<String, dynamic>.from(value));
        }
        if (value is List) {
          return _listSection(label, value);
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 145,
                child: Text(label, style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
              ),
              Expanded(
                child: GestureDetector(
                  onLongPress: () {
                    Clipboard.setData(ClipboardData(text: value.toString()));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Kopyalandı'), duration: Duration(seconds: 1)),
                    );
                  },
                  child: Text(
                    _displayValue(entry.key, value),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _section(String label, Map<String, dynamic> map) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 6),
          ...map.entries
              .where((e) => e.value != null && e.value.toString().isNotEmpty)
              .map((e) => Padding(
                    padding: const EdgeInsets.only(left: 8, top: 4),
                    child: Text(
                      '${_labels[e.key] ?? _humanize(e.key)}: ${_displayValue(e.key, e.value)}',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 12.5),
                    ),
                  )),
        ],
      ),
    );
  }

  Widget _listSection(String label, List<dynamic> list) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label (${list.length})', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 6),
          ...list.take(40).map((item) {
            final text = item is Map
                ? item.entries
                    .where((e) => e.value != null && e.value.toString().isNotEmpty)
                    .map((e) => '${_labels[e.key] ?? _humanize(e.key)}: ${e.value}')
                    .join(' · ')
                : item.toString();
            return Padding(
              padding: const EdgeInsets.only(left: 8, top: 4),
              child: Text(text, style: TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
            );
          }),
        ],
      ),
    );
  }

  String _displayValue(String key, dynamic value) {
    final text = value.toString();
    if (key == 'is_active' || key == 'is_super' || key == 'is_available') {
      return (value == true || text == '1' || text.toLowerCase() == 'true') ? 'Bəli' : 'Xeyr';
    }
    if (value is num) {
      final isMoney = key.contains('amount') || key.contains('price') || key == 'debt_total';
      if (isMoney) {
        return '${value.toStringAsFixed(2)} ₼';
      }
    }
    return text;
  }

  String _humanize(String key) {
    final text = key.replaceAll('_', ' ');
    return text.isEmpty ? key : text[0].toUpperCase() + text.substring(1);
  }
}
