/// Models for physical warehouse management, canteen logistics and supply inventory.
class WarehouseInventoryItem {
  final String id;
  final String code;
  final String name;
  final String category; // 'Tədris ləvazimatı', 'Ofis avadanlığı', 'Təsərrüfat', 'Mebel'
  final double quantity;
  final String unit; // 'ədəd', 'qutu', 'dəst', 'kq'
  final double minThreshold;
  final double unitPrice;
  final String location;
  final DateTime lastAuditedDate;
  final String notes;

  const WarehouseInventoryItem({
    required this.id,
    required this.code,
    required this.name,
    required this.category,
    required this.quantity,
    this.unit = 'ədəd',
    this.minThreshold = 5.0,
    this.unitPrice = 0.0,
    required this.location,
    required this.lastAuditedDate,
    this.notes = '',
  });

  bool get isLowStock => quantity <= minThreshold;
  bool get isOutOfStock => quantity <= 0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'name': name,
        'category': category,
        'quantity': quantity,
        'unit': unit,
        'min_threshold': minThreshold,
        'unit_price': unitPrice,
        'location': location,
        'last_audited_date': lastAuditedDate.toIso8601String(),
        'notes': notes,
      };

  factory WarehouseInventoryItem.fromJson(Map<String, dynamic> json) =>
      WarehouseInventoryItem(
        id: json['id']?.toString() ?? '',
        code: json['code']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        category: json['category']?.toString() ?? 'Tədris ləvazimatı',
        quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
        unit: json['unit']?.toString() ?? 'ədəd',
        minThreshold: (json['min_threshold'] as num?)?.toDouble() ?? 5.0,
        unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0.0,
        location: json['location']?.toString() ?? 'Əsas Anbar',
        lastAuditedDate: json['last_audited_date'] != null
            ? DateTime.tryParse(json['last_audited_date'].toString()) ?? DateTime.now()
            : DateTime.now(),
        notes: json['notes']?.toString() ?? '',
      );
}

/// Food and dining supply logistics record.
class CanteenSupplyItem {
  final String id;
  final String name;
  final String category; // 'Ərzaq', 'Tərəvəz və Meyvə', 'Süd məhsulları', 'Çörək', 'İçkilər'
  final double quantity;
  final String unit; // 'kq', 'litr', 'ədəd'
  final DateTime receivedDate;
  final DateTime expiryDate;
  final String supplier;
  final double cost;

  const CanteenSupplyItem({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.receivedDate,
    required this.expiryDate,
    required this.supplier,
    this.cost = 0.0,
  });

  bool get isExpiringSoon =>
      expiryDate.difference(DateTime.now()).inDays <= 3 &&
      expiryDate.isAfter(DateTime.now());
  bool get isExpired => DateTime.now().isAfter(expiryDate);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'quantity': quantity,
        'unit': unit,
        'received_date': receivedDate.toIso8601String(),
        'expiry_date': expiryDate.toIso8601String(),
        'supplier': supplier,
        'cost': cost,
      };

  factory CanteenSupplyItem.fromJson(Map<String, dynamic> json) => CanteenSupplyItem(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        category: json['category']?.toString() ?? 'Ərzaq',
        quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
        unit: json['unit']?.toString() ?? 'kq',
        receivedDate: json['received_date'] != null
            ? DateTime.tryParse(json['received_date'].toString()) ?? DateTime.now()
            : DateTime.now(),
        expiryDate: json['expiry_date'] != null
            ? DateTime.tryParse(json['expiry_date'].toString()) ?? DateTime.now()
            : DateTime.now(),
        supplier: json['supplier']?.toString() ?? '',
        cost: (json['cost'] as num?)?.toDouble() ?? 0.0,
      );
}
