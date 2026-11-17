import 'package:flutter/material.dart';
import '../../../core/services/school_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../data/models/finance_model.dart';

class ContractHistoryDialog extends StatelessWidget {
  final StudentInvoice invoice;

  const ContractHistoryDialog({super.key, required this.invoice});

  static Future<void> show(BuildContext context, StudentInvoice invoice) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ContractHistoryDialog(invoice: invoice),
    );
  }

  @override
  Widget build(BuildContext context) {
    final contractId = invoice.contractId;
    final palette = AppPalette.of(context);

    if (contractId == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: palette.surface1,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: const Text('Müqavilə identifikatoru tapılmadı.'),
      );
    }

    return FutureBuilder<Map<String, dynamic>?>(
      future: SchoolApiService.instance.fetchContractHistory(contractId),
      builder: (context, snapshot) {
        final loading = snapshot.connectionState == ConnectionState.waiting;
        final data = snapshot.data?['data'] as Map<String, dynamic>? ?? snapshot.data;
        final payments = (data?['payments'] as List?) ?? [];

        final totalAmount = (data?['total_amount'] as num?)?.toDouble() ?? invoice.finalAmount;
        final paidAmount = (data?['paid_amount'] as num?)?.toDouble() ?? invoice.paidAmount;
        final remainingDebt = (data?['remaining_amount'] as num?)?.toDouble() ?? invoice.balance;

        return Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: palette.surface1,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: palette.borderHairline),
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: palette.textTertiary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${invoice.code} • Ödəniş Tarixçəsi',
                            style: TextStyle(color: palette.brandAzure, fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            invoice.studentName,
                            style: TextStyle(color: palette.textPrimary, fontSize: 18, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: palette.surface2,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _stat('Cəmi Məbləğ', '${totalAmount.toStringAsFixed(2)} ₼', palette.textPrimary),
                      _stat('Ödənilib', '${paidAmount.toStringAsFixed(2)} ₼', AppColors.emerald),
                      _stat('Qalıq Borc', '${remainingDebt.toStringAsFixed(2)} ₼', remainingDebt > 0 ? AppColors.rose : AppColors.emerald),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: loading
                      ? const Center(child: CircularProgressIndicator())
                      : snapshot.hasError
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.error_outline_rounded, size: 44, color: AppColors.rose),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Ödəniş tarixçəsi yüklənərkən xəta baş verdi.',
                                    style: TextStyle(color: palette.textSecondary, fontSize: 13),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          : payments.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.receipt_long_outlined, size: 48, color: palette.textSecondary.withValues(alpha: 0.4)),
                                      const SizedBox(height: 10),
                                      Text(
                                        'Bu müqavilə üzrə heç bir ödəniş qeydə alınmayıb.',
                                        style: TextStyle(color: palette.textSecondary, fontSize: 14),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                )
                          : ListView.separated(
                              itemCount: payments.length,
                              separatorBuilder: (_, _) => const Divider(height: 1),
                              itemBuilder: (context, idx) {
                                final p = payments[idx] as Map<String, dynamic>;
                                final code = p['code']?.toString() ?? 'Ödəniş';
                                final amount = (p['amount'] as num?)?.toDouble() ?? 0.0;
                                final date = p['payment_date']?.toString() ?? p['created_at']?.toString() ?? '';
                                final method = p['payment_method_label']?.toString() ?? p['payment_method']?.toString() ?? 'Nağd';
                                final bank = p['bank_account']?.toString();
                                final notes = p['notes']?.toString();

                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors.emerald.withValues(alpha: 0.15),
                                    child: const Icon(Icons.arrow_downward_rounded, color: AppColors.emerald, size: 20),
                                  ),
                                  title: Row(
                                    children: [
                                      Text(
                                        code,
                                        style: TextStyle(fontWeight: FontWeight.w700, color: palette.textPrimary, fontSize: 14),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: palette.brandAzure.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          method,
                                          style: TextStyle(color: palette.brandAzure, fontSize: 11, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 3),
                                      Text(
                                        'Tarix: $date${bank != null && bank.isNotEmpty ? " • $bank" : ""}',
                                        style: TextStyle(color: palette.textSecondary, fontSize: 12),
                                      ),
                                      if (notes != null && notes.isNotEmpty)
                                        Text(
                                          'Qeyd: $notes',
                                          style: TextStyle(color: palette.textTertiary, fontSize: 11, fontStyle: FontStyle.italic),
                                        ),
                                    ],
                                  ),
                                  trailing: Text(
                                    '+${amount.toStringAsFixed(2)} ₼',
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.emerald),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
      ],
    );
  }
}
