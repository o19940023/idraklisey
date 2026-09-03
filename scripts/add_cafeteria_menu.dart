import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../lib/firebase_options.dart';

// Bu skript Lisey Yemekxana menyusunu JSON faylından oxuyub Firebase'e əlavə edir
void main() async {
  print('🍽️  Lisey Yemekxana Menyusu Firebase\'e əlavə edilir...\n');

  try {
    // Firebase initialize
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    final db = FirebaseFirestore.instance;

    // JSON faylını oxu
    final jsonFile = File('scripts/menu_data.json');
    if (!await jsonFile.exists()) {
      print('❌ menu_data.json faylı tapılmadı!');
      exit(1);
    }

    final jsonString = await jsonFile.readAsString();
    final jsonData = json.decode(jsonString) as Map<String, dynamic>;
    final menuList = jsonData['menu_items'] as List<dynamic>;

    print('📊 ${menuList.length} menyu yüklənir...\n');

    // Batch yazımı
    final batch = db.batch();
    int totalItems = 0;

    for (var menuItem in menuList) {
      final menu = menuItem as Map<String, dynamic>;
      final dayName = menu['dayName'] as String;
      final date = DateTime.parse(menu['date'] as String);
      final mealTime = menu['mealTime'] as String;
      final totalCalories = menu['totalCalories'] as int;
      final items = menu['items'] as List<dynamic>;

      // Document ID yaradırıq
      final docId = dayName.replaceAll(' ', '_').replaceAll('-', '');
      
      // Firestore document reference
      final docRef = db.collection('cafeteria_menu').doc(docId);
      
      // Məlumatları hazırlayırıq
      batch.set(docRef, {
        'dayName': dayName,
        'date': date.toIso8601String(),
        'mealTime': mealTime,
        'totalCalories': totalCalories,
        'items': items.map((item) {
          final itemMap = item as Map<String, dynamic>;
          return {
            'name': itemMap['name'],
            'category': itemMap['category'],
            'calories': itemMap['calories'],
            'weightGram': itemMap['weightGram'],
            'allergens': itemMap['allergens'] ?? [],
            'imageUrl': itemMap['imageUrl'],
          };
        }).toList(),
      });

      totalItems += items.length;
      print('✅ $dayName: $totalCalories kkal (${items.length} yemək)');
    }

    // Firebase'e yazma
    print('\n💾 Firebase\'e yazılır...');
    await batch.commit();

    print('\n🎉 Uğurlu! ${menuList.length} menyu və $totalItems yemək Firebase\'e əlavə edildi.');
    print('📱 Tətbiqdən yemekxana menyusunu yoxlaya bilərsiniz.\n');

    exit(0);
  } catch (e, stackTrace) {
    print('❌ Xəta baş verdi: $e');
    print('Stack trace: $stackTrace');
    exit(1);
  }
}
