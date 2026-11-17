class MenuItem {
  final String name;
  final String category; // "Əsas Yemək", "Şorba", "Salat", "Şirniyyat / İçki"
  final int calories;
  final String weightGram;
  final List<String> allergens; // "Qlüten", "Süd", "Yumurta"
  final String imageUrl;

  MenuItem({
    required this.name,
    required this.category,
    required this.calories,
    required this.weightGram,
    required this.allergens,
    required this.imageUrl,
  });
}

class DailyMenu {
  final String dayName; // "Bazar ertəsi"
  final DateTime date;
  final String mealTime; // "Nahar (12:30 - 13:30)"
  final List<MenuItem> items;
  final int totalCalories;

  DailyMenu({
    required this.dayName,
    required this.date,
    required this.mealTime,
    required this.items,
    required this.totalCalories,
  });
}

class CanteenWeeklyMenu {
  final bool found;
  final int offset;
  final String weekLabel;
  final String startDate;
  final String endDate;
  final bool isApproved;
  final String? status;
  final List<CanteenDayMenu> days;

  CanteenWeeklyMenu({
    required this.found,
    required this.offset,
    required this.weekLabel,
    required this.startDate,
    required this.endDate,
    required this.isApproved,
    this.status,
    required this.days,
  });

  factory CanteenWeeklyMenu.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map ? Map<String, dynamic>.from(json['data']) : json;
    final week = data['week'] is Map ? Map<String, dynamic>.from(data['week']) : {};
    final daysList = data['days'] is List ? (data['days'] as List) : [];

    return CanteenWeeklyMenu(
      found: data['found'] == true,
      offset: (data['offset'] as num?)?.toInt() ?? 0,
      weekLabel: week['label']?.toString() ?? '',
      startDate: week['start_date']?.toString() ?? '',
      endDate: week['end_date']?.toString() ?? '',
      isApproved: week['is_approved'] == true,
      status: week['status']?.toString(),
      days: daysList.map((d) => CanteenDayMenu.fromJson(Map<String, dynamic>.from(d))).toList(),
    );
  }
}

class CanteenDayMenu {
  final String date;
  final String dayName;
  final String dateLabel;
  final Map<String, List<String>> meals;

  CanteenDayMenu({
    required this.date,
    required this.dayName,
    required this.dateLabel,
    required this.meals,
  });

  factory CanteenDayMenu.fromJson(Map<String, dynamic> json) {
    final rawMeals = json['meals'] is Map ? Map<String, dynamic>.from(json['meals']) : {};
    final mealsMap = <String, List<String>>{};
    rawMeals.forEach((key, val) {
      if (val is List) {
        mealsMap[key.toString()] = val.map((e) => e.toString()).toList();
      }
    });

    return CanteenDayMenu(
      date: json['date']?.toString() ?? '',
      dayName: json['day_name']?.toString() ?? '',
      dateLabel: json['date_label']?.toString() ?? '',
      meals: mealsMap,
    );
  }
}
