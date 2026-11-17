import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/school_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../data/models/finance_model.dart';

class ContractQuickActions {
  /// Opens print / PDF preview for contract
  static Future<void> openContractPrint(BuildContext context, int contractId) async {
    try {
      final printUrl = await SchoolApiService.instance.fetchContractPrintUrl(contractId);
      if (printUrl != null && printUrl.isNotEmpty) {
        final uri = Uri.parse(printUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return;
        }
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Çap linki açıla bilmədi.'), backgroundColor: AppColors.rose),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xəta: $e'), backgroundColor: AppColors.rose),
        );
      }
    }
  }

  /// Show quick update amount modal
  static Future<void> showUpdateAmountDialog(
    BuildContext context,
    StudentInvoice inv, {
    required VoidCallback onSuccess,
  }) async {
    final contractId = inv.contractId;
    if (contractId == null) return;

    final amountCtrl = TextEditingController(text: inv.totalAmount.toStringAsFixed(2));
    final reasonCtrl = TextEditingController();
    bool isSubmitting = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final palette = AppPalette.of(ctx);
          final currentTotal = double.tryParse(amountCtrl.text.trim()) ?? inv.totalAmount;
          final newFinal = (currentTotal - inv.discountAmount).clamp(0.0, double.infinity);

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: palette.surface1,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(color: palette.borderHairline),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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
                    Text(
                      'Müqavilə məbləğini dəyiş',
                      style: TextStyle(color: palette.textPrimary, fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      '${inv.code} • ${inv.studentName}',
                      style: TextStyle(color: palette.brandAzure, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setModalState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Yeni ümumi məbləğ (AZN)',
                        border: const OutlineInputBorder(),
                        suffixText: '₼',
                        helperText: 'Cari məbləğ: ${inv.totalAmount.toStringAsFixed(2)} ₼',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: palette.surface2,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Yenilənmiş yekun məbləğ:', style: TextStyle(color: palette.textSecondary, fontSize: 13)),
                          Text(
                            '${newFinal.toStringAsFixed(2)} ₼',
                            style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w800, fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: reasonCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Dəyişiklik səbəbi (İxtiyari)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: palette.brandRoyal,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: isSubmitting
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.save_rounded),
                      label: Text(isSubmitting ? 'Saxlanılır...' : 'Məbləği yenilə', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final newAmt = double.tryParse(amountCtrl.text.trim());
                              if (newAmt == null || newAmt < 0) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(content: Text('Düzgün məbləğ daxil edin.')),
                                );
                                return;
                              }

                              setModalState(() => isSubmitting = true);
                              final res = await SchoolApiService.instance.updateContractAmount(
                                contractId,
                                totalAmount: newAmt,
                                reason: reasonCtrl.text.trim().isNotEmpty ? reasonCtrl.text.trim() : null,
                              );
                              setModalState(() => isSubmitting = false);

                              if (res != null && res['success'] == true) {
                                if (ctx.mounted) Navigator.pop(ctx);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(res['message']?.toString() ?? 'Məbləğ yeniləndi.'), backgroundColor: AppColors.emerald),
                                  );
                                }
                                onSuccess();
                              } else {
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(content: Text(res?['message']?.toString() ?? 'Xəta baş verdi.'), backgroundColor: AppColors.rose),
                                  );
                                }
                              }
                            },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Show quick apply discount modal
  static Future<void> showDiscountDialog(
    BuildContext context,
    StudentInvoice inv, {
    required VoidCallback onSuccess,
  }) async {
    final contractId = inv.contractId;
    if (contractId == null) return;

    String discountType = inv.discountPercentage > 0 ? 'percent' : 'amount';
    final discountValCtrl = TextEditingController(
      text: discountType == 'percent'
          ? (inv.discountPercentage > 0 ? inv.discountPercentage.toStringAsFixed(0) : '')
          : (inv.discountAmount > 0 ? inv.discountAmount.toStringAsFixed(2) : ''),
    );
    bool isSubmitting = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final palette = AppPalette.of(ctx);
          final rawVal = double.tryParse(discountValCtrl.text.trim()) ?? 0.0;
          double calculatedDiscountAmount = 0.0;
          if (discountType == 'percent') {
            calculatedDiscountAmount = (inv.totalAmount * (rawVal / 100)).clamp(0.0, inv.totalAmount);
          } else {
            calculatedDiscountAmount = rawVal.clamp(0.0, inv.totalAmount);
          }
          final newFinal = (inv.totalAmount - calculatedDiscountAmount).clamp(0.0, double.infinity);

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: palette.surface1,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(color: palette.borderHairline),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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
                    Text(
                      'Güzəşt tətbiq et',
                      style: TextStyle(color: palette.textPrimary, fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      '${inv.code} • ${inv.studentName} (Cəmi: ${inv.totalAmount.toStringAsFixed(2)} ₼)',
                      style: TextStyle(color: palette.brandAzure, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),
                    // Toggle Percent vs Amount
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Məbləğlə (AZN)')),
                            selected: discountType == 'amount',
                            onSelected: (val) {
                              if (val) setModalState(() => discountType = 'amount');
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Faizlə (%)')),
                            selected: discountType == 'percent',
                            onSelected: (val) {
                              if (val) setModalState(() => discountType = 'percent');
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: discountValCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setModalState(() {}),
                      decoration: InputDecoration(
                        labelText: discountType == 'percent' ? 'Güzəşt faizi (%)' : 'Güzəşt məbləği (AZN)',
                        border: const OutlineInputBorder(),
                        suffixText: discountType == 'percent' ? '%' : '₼',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: palette.surface2,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Tətbiq edilən güzəşt:', style: TextStyle(color: palette.textSecondary, fontSize: 13)),
                              Text(
                                '-${calculatedDiscountAmount.toStringAsFixed(2)} ₼',
                                style: const TextStyle(color: AppColors.emerald, fontWeight: FontWeight.w800, fontSize: 14),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Yeni yekun məbləğ:', style: TextStyle(color: palette.textSecondary, fontSize: 13)),
                              Text(
                                '${newFinal.toStringAsFixed(2)} ₼',
                                style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w800, fontSize: 15),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.emerald,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: isSubmitting
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.check_circle_rounded),
                      label: Text(isSubmitting ? 'Tətbiq olunur...' : 'Güzəşti təsdiqlə', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final val = double.tryParse(discountValCtrl.text.trim());
                              if (val == null || val < 0) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(content: Text('Düzgün dəyər daxil edin.')),
                                );
                                return;
                              }
                              if (discountType == 'percent' && val > 100) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(content: Text('Faiz 100-dən çox ola bilməz.')),
                                );
                                return;
                              }

                              setModalState(() => isSubmitting = true);
                              final res = await SchoolApiService.instance.applyContractDiscount(
                                contractId,
                                discountType: discountType,
                                discountValue: val,
                              );
                              setModalState(() => isSubmitting = false);

                              if (res != null && res['success'] == true) {
                                if (ctx.mounted) Navigator.pop(ctx);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(res['message']?.toString() ?? 'Güzəşt tətbiq edildi.'), backgroundColor: AppColors.emerald),
                                  );
                                }
                                onSuccess();
                              } else {
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(content: Text(res?['message']?.toString() ?? 'Xəta baş verdi.'), backgroundColor: AppColors.rose),
                                  );
                                }
                              }
                            },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
