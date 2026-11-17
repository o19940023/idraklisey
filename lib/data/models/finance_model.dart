/// Models for school financial management: student invoices, payroll, and ledger.

class ContractInstallmentItem {
  final int index;
  final String month;
  final String date;
  final double amount;
  final bool isPaid;

  const ContractInstallmentItem({
    required this.index,
    required this.month,
    required this.date,
    required this.amount,
    required this.isPaid,
  });

  factory ContractInstallmentItem.fromJson(Map<String, dynamic> json) => ContractInstallmentItem(
    index: (json['index'] as num?)?.toInt() ?? 0,
    month: json['month']?.toString() ?? '',
    date: json['date']?.toString() ?? '',
    amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
    isPaid: json['is_paid'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'index': index,
    'month': month,
    'date': date,
    'amount': amount,
    'is_paid': isPaid,
  };
}

class StudentContractSummary {
  final int totalContracts;
  final double totalAmount;
  final double totalPaid;
  final double totalRemaining;
  final int approvedCount;
  final int pendingApprovalCount;
  final int rejectedApprovalCount;

  const StudentContractSummary({
    this.totalContracts = 0,
    this.totalAmount = 0.0,
    this.totalPaid = 0.0,
    this.totalRemaining = 0.0,
    this.approvedCount = 0,
    this.pendingApprovalCount = 0,
    this.rejectedApprovalCount = 0,
  });

  factory StudentContractSummary.fromJson(Map<String, dynamic> json) => StudentContractSummary(
    totalContracts: (json['total_contracts'] as num?)?.toInt() ?? 0,
    totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
    totalPaid: (json['total_paid'] as num?)?.toDouble() ?? 0.0,
    totalRemaining: (json['total_remaining'] as num?)?.toDouble() ?? 0.0,
    approvedCount: (json['approved_count'] as num?)?.toInt() ?? 0,
    pendingApprovalCount: (json['pending_approval_count'] as num?)?.toInt() ?? 0,
    rejectedApprovalCount: (json['rejected_approval_count'] as num?)?.toInt() ?? 0,
  );
}

class StudentInvoice {
  final String id;
  final int? contractId;
  final String code;
  final String invoiceNumber;
  final String contractType;
  final String contractTypeLabel;
  final String? clubTitle;
  final String studentId;
  final String studentName;
  final String? studentAvatar;
  final String parentName;
  final String? parentPhone;
  final String className;
  final int? academicYearId;
  final String? academicYearTitle;
  final double totalAmount;
  final double discountAmount;
  final double discountPercentage;
  final double finalAmount;
  final double amount;
  final double paidAmount;
  final double remainingDebt;
  final int numberOfInstallments;
  final DateTime dueDate;
  final DateTime? paidDate;
  final String status;
  final String statusLabel;
  final String statusColor;
  final String directorApprovalStatus;
  final String directorApprovalLabel;
  final String? directorApprovedAt;
  final String? directorRejectionReason;
  final String? startDate;
  final String? endDate;
  final String? cancellationDate;
  final String invoiceType;
  final String notes;
  final List<ContractInstallmentItem> paymentSchedule;
  final bool canApprove;
  final bool canReject;
  final bool canTerminate;
  final bool canRecordPayment;

  const StudentInvoice({
    required this.id,
    this.contractId,
    this.code = '',
    required this.invoiceNumber,
    this.contractType = 'education',
    this.contractTypeLabel = 'Təhsil haqqı',
    this.clubTitle,
    required this.studentId,
    required this.studentName,
    this.studentAvatar,
    required this.parentName,
    this.parentPhone,
    required this.className,
    this.academicYearId,
    this.academicYearTitle,
    this.totalAmount = 0.0,
    this.discountAmount = 0.0,
    this.discountPercentage = 0.0,
    this.finalAmount = 0.0,
    required this.amount,
    this.paidAmount = 0.0,
    this.remainingDebt = 0.0,
    this.numberOfInstallments = 1,
    required this.dueDate,
    this.paidDate,
    this.status = 'pending',
    this.statusLabel = 'Gözləmədə',
    this.statusColor = '#3B82F6',
    this.directorApprovalStatus = 'pending',
    this.directorApprovalLabel = 'Gözləmədə',
    this.directorApprovedAt,
    this.directorRejectionReason,
    this.startDate,
    this.endDate,
    this.cancellationDate,
    this.invoiceType = 'Təhsil haqqı',
    this.notes = '',
    this.paymentSchedule = const [],
    this.canApprove = false,
    this.canReject = false,
    this.canTerminate = false,
    this.canRecordPayment = false,
  });

  double get balance => remainingDebt > 0 ? remainingDebt : (amount - paidAmount);
  bool get isPaid => status == 'paid' || balance <= 0;
  bool get isOverdue => !isPaid && DateTime.now().isAfter(dueDate);

  StudentInvoice copyWith({
    String? id,
    int? contractId,
    String? code,
    String? invoiceNumber,
    String? contractType,
    String? contractTypeLabel,
    String? clubTitle,
    String? studentId,
    String? studentName,
    String? studentAvatar,
    String? parentName,
    String? parentPhone,
    String? className,
    int? academicYearId,
    String? academicYearTitle,
    double? totalAmount,
    double? discountAmount,
    double? discountPercentage,
    double? finalAmount,
    double? amount,
    double? paidAmount,
    double? remainingDebt,
    int? numberOfInstallments,
    DateTime? dueDate,
    DateTime? paidDate,
    String? status,
    String? statusLabel,
    String? statusColor,
    String? directorApprovalStatus,
    String? directorApprovalLabel,
    String? directorApprovedAt,
    String? directorRejectionReason,
    String? startDate,
    String? endDate,
    String? cancellationDate,
    String? invoiceType,
    String? notes,
    List<ContractInstallmentItem>? paymentSchedule,
    bool? canApprove,
    bool? canReject,
    bool? canTerminate,
    bool? canRecordPayment,
  }) {
    return StudentInvoice(
      id: id ?? this.id,
      contractId: contractId ?? this.contractId,
      code: code ?? this.code,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      contractType: contractType ?? this.contractType,
      contractTypeLabel: contractTypeLabel ?? this.contractTypeLabel,
      clubTitle: clubTitle ?? this.clubTitle,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      studentAvatar: studentAvatar ?? this.studentAvatar,
      parentName: parentName ?? this.parentName,
      parentPhone: parentPhone ?? this.parentPhone,
      className: className ?? this.className,
      academicYearId: academicYearId ?? this.academicYearId,
      academicYearTitle: academicYearTitle ?? this.academicYearTitle,
      totalAmount: totalAmount ?? this.totalAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      finalAmount: finalAmount ?? this.finalAmount,
      amount: amount ?? this.amount,
      paidAmount: paidAmount ?? this.paidAmount,
      remainingDebt: remainingDebt ?? this.remainingDebt,
      numberOfInstallments: numberOfInstallments ?? this.numberOfInstallments,
      dueDate: dueDate ?? this.dueDate,
      paidDate: paidDate ?? this.paidDate,
      status: status ?? this.status,
      statusLabel: statusLabel ?? this.statusLabel,
      statusColor: statusColor ?? this.statusColor,
      directorApprovalStatus: directorApprovalStatus ?? this.directorApprovalStatus,
      directorApprovalLabel: directorApprovalLabel ?? this.directorApprovalLabel,
      directorApprovedAt: directorApprovedAt ?? this.directorApprovedAt,
      directorRejectionReason: directorRejectionReason ?? this.directorRejectionReason,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      cancellationDate: cancellationDate ?? this.cancellationDate,
      invoiceType: invoiceType ?? this.invoiceType,
      notes: notes ?? this.notes,
      paymentSchedule: paymentSchedule ?? this.paymentSchedule,
      canApprove: canApprove ?? this.canApprove,
      canReject: canReject ?? this.canReject,
      canTerminate: canTerminate ?? this.canTerminate,
      canRecordPayment: canRecordPayment ?? this.canRecordPayment,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'contract_id': contractId,
    'code': code,
    'invoice_number': invoiceNumber,
    'contract_type': contractType,
    'contract_type_label': contractTypeLabel,
    'club_title': clubTitle,
    'student_id': studentId,
    'student_name': studentName,
    'student_avatar': studentAvatar,
    'parent_name': parentName,
    'parent_phone': parentPhone,
    'class_name': className,
    'academic_year_id': academicYearId,
    'academic_year_title': academicYearTitle,
    'total_amount': totalAmount,
    'discount_amount': discountAmount,
    'discount_percentage': discountPercentage,
    'final_amount': finalAmount,
    'amount': amount,
    'paid_amount': paidAmount,
    'remaining_debt': remainingDebt,
    'number_of_installments': numberOfInstallments,
    'due_date': dueDate.toIso8601String(),
    'paid_date': paidDate?.toIso8601String(),
    'status': status,
    'status_label': statusLabel,
    'status_color': statusColor,
    'director_approval_status': directorApprovalStatus,
    'director_approval_label': directorApprovalLabel,
    'director_approved_at': directorApprovedAt,
    'director_rejection_reason': directorRejectionReason,
    'start_date': startDate,
    'end_date': endDate,
    'cancellation_date': cancellationDate,
    'invoice_type': invoiceType,
    'notes': notes,
    'payment_schedule': paymentSchedule.map((s) => s.toJson()).toList(),
    'can_approve': canApprove,
    'can_reject': canReject,
    'can_terminate': canTerminate,
    'can_record_payment': canRecordPayment,
  };

  factory StudentInvoice.fromJson(Map<String, dynamic> json) {
    final schedRaw = json['paymentSchedule'] ?? json['payment_schedule'];
    List<ContractInstallmentItem> schedule = [];
    if (schedRaw is List) {
      schedule = schedRaw.map((e) {
        if (e is Map<String, dynamic>) {
          return ContractInstallmentItem.fromJson(e);
        }
        return const ContractInstallmentItem(index: 0, month: '', date: '', amount: 0, isPaid: false);
      }).toList();
    }

    final totalAmt = (json['finalAmount'] ?? json['final_amount'] ?? json['amount'] ?? json['totalAmount'] ?? json['total_amount'] as num?)?.toDouble() ?? 0.0;
    final paidAmt = (json['paidAmount'] ?? json['paid_amount'] as num?)?.toDouble() ?? 0.0;
    final remDebt = (json['remainingDebt'] ?? json['remaining_debt'] as num?)?.toDouble() ?? (totalAmt - paidAmt);
    final invNum = json['code']?.toString() ?? json['invoiceNumber']?.toString() ?? json['invoice_number']?.toString() ?? '';

    return StudentInvoice(
      id: json['id']?.toString() ?? '',
      contractId: (json['contractId'] ?? json['contract_id']) is num
          ? ((json['contractId'] ?? json['contract_id']) as num).toInt()
          : int.tryParse((json['contractId'] ?? json['contract_id'] ?? json['id'])?.toString() ?? ''),
      code: invNum,
      invoiceNumber: invNum,
      contractType: json['contractType']?.toString() ?? json['contract_type']?.toString() ?? 'education',
      contractTypeLabel: json['contractTypeLabel']?.toString() ?? json['contract_type_label']?.toString() ?? json['invoiceType']?.toString() ?? json['invoice_type']?.toString() ?? 'Təhsil haqqı',
      clubTitle: json['clubTitle']?.toString() ?? json['club_title']?.toString(),
      studentId: json['studentId']?.toString() ?? json['student_id']?.toString() ?? '',
      studentName: json['studentName']?.toString() ?? json['student_name']?.toString() ?? '',
      studentAvatar: json['studentAvatar']?.toString() ?? json['student_avatar']?.toString(),
      parentName: json['parentName']?.toString() ?? json['parent_name']?.toString() ?? '',
      parentPhone: json['parentPhone']?.toString() ?? json['parent_phone']?.toString(),
      className: json['className']?.toString() ?? json['class_name']?.toString() ?? '',
      academicYearId: (json['academicYearId'] ?? json['academic_year_id'] as num?)?.toInt(),
      academicYearTitle: json['academicYearTitle']?.toString() ?? json['academic_year_title']?.toString(),
      totalAmount: (json['totalAmount'] ?? json['total_amount'] as num?)?.toDouble() ?? totalAmt,
      discountAmount: (json['discountAmount'] ?? json['discount_amount'] as num?)?.toDouble() ?? 0.0,
      discountPercentage: (json['discountPercentage'] ?? json['discount_percentage'] as num?)?.toDouble() ?? 0.0,
      finalAmount: (json['finalAmount'] ?? json['final_amount'] as num?)?.toDouble() ?? totalAmt,
      amount: totalAmt,
      paidAmount: paidAmt,
      remainingDebt: remDebt,
      numberOfInstallments: (json['numberOfInstallments'] ?? json['number_of_installments'] as num?)?.toInt() ?? 1,
      dueDate: json['dueDate'] != null || json['due_date'] != null
          ? DateTime.tryParse((json['dueDate'] ?? json['due_date']).toString()) ?? DateTime.now()
          : DateTime.now(),
      paidDate: json['paidDate'] != null || json['paid_date'] != null
          ? DateTime.tryParse((json['paidDate'] ?? json['paid_date']).toString())
          : null,
      status: json['status']?.toString() ?? 'pending',
      statusLabel: json['statusLabel']?.toString() ?? json['status_label']?.toString() ?? (json['status']?.toString() ?? 'Gözləmədə'),
      statusColor: json['statusColor']?.toString() ?? json['status_color']?.toString() ?? '#3B82F6',
      directorApprovalStatus: json['directorApprovalStatus']?.toString() ?? json['director_approval_status']?.toString() ?? 'pending',
      directorApprovalLabel: json['directorApprovalLabel']?.toString() ?? json['director_approval_label']?.toString() ?? 'Gözləmədə',
      directorApprovedAt: json['directorApprovedAt']?.toString() ?? json['director_approved_at']?.toString(),
      directorRejectionReason: json['directorRejectionReason']?.toString() ?? json['director_rejection_reason']?.toString(),
      startDate: json['startDate']?.toString() ?? json['start_date']?.toString(),
      endDate: json['endDate']?.toString() ?? json['end_date']?.toString(),
      cancellationDate: json['cancellationDate']?.toString() ?? json['cancellation_date']?.toString(),
      invoiceType: json['contractTypeLabel']?.toString() ?? json['contract_type_label']?.toString() ?? json['invoice_type']?.toString() ?? 'Təhsil haqqı',
      notes: json['notes']?.toString() ?? '',
      paymentSchedule: schedule,
      canApprove: json['canApprove'] as bool? ?? false,
      canReject: json['canReject'] as bool? ?? false,
      canTerminate: json['canTerminate'] as bool? ?? false,
      canRecordPayment: json['canRecordPayment'] as bool? ?? false,
    );
  }
}

class PayrollItem {
  final String id;
  final String employeeId;
  final String employeeName;
  final String position;
  final String month; // e.g. "Oktyabr 2026"
  final double grossSalary;
  final double netSalary;
  final double taxAmount;
  final double dsmfAmount;
  final double insuranceAmount;
  final double bonusAmount;
  final String status; // 'paid', 'pending'
  final DateTime? paidDate;

  const PayrollItem({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.position,
    required this.month,
    required this.grossSalary,
    required this.netSalary,
    this.taxAmount = 0.0,
    this.dsmfAmount = 0.0,
    this.insuranceAmount = 0.0,
    this.bonusAmount = 0.0,
    this.status = 'paid',
    this.paidDate,
  });

  bool get isPaid => status == 'paid';

  Map<String, dynamic> toJson() => {
        'id': id,
        'employee_id': employeeId,
        'employee_name': employeeName,
        'position': position,
        'month': month,
        'gross_salary': grossSalary,
        'net_salary': netSalary,
        'tax_amount': taxAmount,
        'dsmf_amount': dsmfAmount,
        'insurance_amount': insuranceAmount,
        'bonus_amount': bonusAmount,
        'status': status,
        'paid_date': paidDate?.toIso8601String(),
      };

  factory PayrollItem.fromJson(Map<String, dynamic> json) => PayrollItem(
        id: json['id']?.toString() ?? '',
        employeeId: json['employee_id']?.toString() ?? '',
        employeeName: json['employee_name']?.toString() ?? '',
        position: json['position']?.toString() ?? '',
        month: json['month']?.toString() ?? '',
        grossSalary: (json['gross_salary'] as num?)?.toDouble() ?? 0.0,
        netSalary: (json['net_salary'] as num?)?.toDouble() ?? 0.0,
        taxAmount: (json['tax_amount'] as num?)?.toDouble() ?? 0.0,
        dsmfAmount: (json['dsmf_amount'] as num?)?.toDouble() ?? 0.0,
        insuranceAmount: (json['insurance_amount'] as num?)?.toDouble() ?? 0.0,
        bonusAmount: (json['bonus_amount'] as num?)?.toDouble() ?? 0.0,
        status: json['status']?.toString() ?? 'pending',
        paidDate: json['paid_date'] != null
            ? DateTime.tryParse(json['paid_date'].toString())
            : null,
      );
}

/// General ledger income/expense entry.
class FinanceLedgerItem {
  final String id;
  final String transactionNumber;
  final String type; // 'income' (Mədaxil), 'expense' (Məxaric)
  final String category;
  final String title;
  final double amount;
  final DateTime date;
  final String paymentMethod; // 'Bank köçürməsi', 'Nağd', 'Onlayn Kart'
  final String counterparty;
  final String description;

  const FinanceLedgerItem({
    required this.id,
    required this.transactionNumber,
    required this.type,
    required this.category,
    required this.title,
    required this.amount,
    required this.date,
    this.paymentMethod = 'Bank köçürməsi',
    this.counterparty = '',
    this.description = '',
  });

  bool get isIncome => type == 'income';

  Map<String, dynamic> toJson() => {
        'id': id,
        'transaction_number': transactionNumber,
        'type': type,
        'category': category,
        'title': title,
        'amount': amount,
        'date': date.toIso8601String(),
        'payment_method': paymentMethod,
        'counterparty': counterparty,
        'description': description,
      };

  factory FinanceLedgerItem.fromJson(Map<String, dynamic> json) => FinanceLedgerItem(
        id: json['id']?.toString() ?? '',
        transactionNumber: json['transaction_number']?.toString() ?? '',
        type: json['type']?.toString() ?? 'income',
        category: json['category']?.toString() ?? 'Ümumi',
        title: json['title']?.toString() ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
        date: json['date'] != null
            ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now()
            : DateTime.now(),
        paymentMethod: json['payment_method']?.toString() ?? 'Bank köçürməsi',
        counterparty: json['counterparty']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
      );
}

/// Finance category dictionary item.
class FinanceCategory {
  final String id;
  final String name;
  final String type; // 'income', 'expense'
  final String code;
  final String description;
  final bool isActive;

  const FinanceCategory({
    required this.id,
    required this.name,
    required this.type,
    required this.code,
    this.description = '',
    this.isActive = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'code': code,
        'description': description,
        'is_active': isActive,
      };

  factory FinanceCategory.fromJson(Map<String, dynamic> json) => FinanceCategory(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        type: json['type']?.toString() ?? 'income',
        code: json['code']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        isActive: json['is_active'] as bool? ?? true,
      );
}
