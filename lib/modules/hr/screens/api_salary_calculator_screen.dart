import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/network/api_client.dart';

class ApiSalaryCalculatorScreen extends StatefulWidget {
  const ApiSalaryCalculatorScreen({super.key});

  @override
  State<ApiSalaryCalculatorScreen> createState() => _ApiSalaryCalculatorScreenState();
}

class _ApiSalaryCalculatorScreenState extends State<ApiSalaryCalculatorScreen> {
  final _client = ApiClient.instance;
  final _grossController = TextEditingController(text: '1000');

  String _companyType = 'PRIVATE_NO';
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _result;

  static const _companyTypes = {
    'PRIVATE_NO': 'Özəl (neft-qaz xaric)',
    'PRIVATE': 'Özəl',
    'SERVICE_CO': 'Xidməti müqavilə',
  };

  @override
  void dispose() {
    _grossController.dispose();
    super.dispose();
  }

  Future<void> _calculate() async {
    final gross = double.tryParse(_grossController.text.replaceAll(',', '.'));
    if (gross == null || gross < 0) {
      setState(() => _error = 'Düzgün brüt məbləğ daxil edin.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });

    try {
      final response = await _client.post('hr/salary/calculate', data: {
        'gross_salary': gross,
        'company_type': _companyType,
      });
      final data = response is Map ? response['data'] : null;
      setState(() {
        _result = data is Map ? Map<String, dynamic>.from(data) : null;
        _loading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Əməkhaqqı kalkulyatoru')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Brüt əməkhaqqıdan net məbləğin hesablanması (AR Vergi Məcəlləsi)',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12.5),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _grossController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
            decoration: InputDecoration(
              labelText: 'Brüt əməkhaqqı (₼)',
              prefixIcon: const Icon(Icons.payments_rounded),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _companyType,
            decoration: InputDecoration(
              labelText: 'Şirkət növü',
              prefixIcon: const Icon(Icons.business_rounded),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
            items: _companyTypes.entries
                .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                .toList(),
            onChanged: (value) => setState(() => _companyType = value ?? 'PRIVATE_NO'),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 50,
            child: FilledButton.icon(
              onPressed: _loading ? null : _calculate,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: _loading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.calculate_rounded),
              label: const Text('Hesabla'),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 14),
            Text(_error!, style: const TextStyle(color: AppColors.danger)),
          ],
          if (_result != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Net əməkhaqqı', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 6),
                  Text(
                    '${(_result!['net_salary'] as num?)?.toStringAsFixed(2) ?? '0.00'} ₼',
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Brüt: ${(_result!['gross_salary'] as num?)?.toStringAsFixed(2) ?? '0.00'} ₼',
                    style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _breakdown(theme),
          ],
        ],
      ),
    );
  }

  Widget _breakdown(ThemeData theme) {
    final breakdown = _result!['tax_breakdown'];
    if (breakdown is! Map) return const SizedBox.shrink();

    const labels = {
      'dsmf': 'DSMF (sosial sığorta)',
      'unemployment_insurance': 'İşsizlikdən sığorta',
      'health_insurance': 'İcbari tibbi sığorta',
      'income_tax': 'Gəlir vergisi',
      'tax_relief': 'Vergi güzəşti',
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tutulmalar', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 10),
          ...breakdown.entries.map((entry) {
            final value = entry.value;
            final amount = value is num ? value.toStringAsFixed(2) : value.toString();
            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    labels[entry.key] ?? entry.key.toString(),
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                  Text('$amount ₼', style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
