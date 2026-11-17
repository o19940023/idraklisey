// Email Otomatik Oluşturma Sistemi
// GoPanel Veb və MariaDB standartlarına 100% uyğunlaşdırılmışdır:
// Şagird: name.surname@student.idrak.edu.az
// Valideyn / Əməkdaş: name.surname@idrak.edu.az

class EmailGenerator {
  /// Azərbaycan simvollarını Latın hərflərinə çevirir
  static String _convertAzerbaijaniToLatin(String text) {
    final Map<String, String> charMap = {
      'ə': 'e', 'Ə': 'e',
      'ı': 'i', 'I': 'i', 'İ': 'i',
      'ö': 'o', 'Ö': 'o',
      'ü': 'u', 'Ü': 'u',
      'ç': 'c', 'Ç': 'c',
      'ş': 's', 'Ş': 's',
      'ğ': 'g', 'Ğ': 'g',
    };

    String result = text;
    charMap.forEach((az, latin) {
      result = result.replaceAll(az, latin);
    });
    return result;
  }

  /// Ad Soyad-dan təmiz istifadəçi adı (slug) yaradır
  /// Nümunə: "Zəhra Mövsümova" → "zehra.movsumova"
  static String _generateUsername(String fullName) {
    final cleanName = _convertAzerbaijaniToLatin(fullName)
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z\s]'), '') // Xüsusi simvolları sil
        .replaceAll(RegExp(r'\s+'), '.'); // Boşluqları nöqtə et
    
    return cleanName;
  }

  /// Əməkdaş (Staff) üçün email yaradır
  /// Format: firstname.lastname@idrak.edu.az
  /// Təkrar olduqda: firstname.lastname2@idrak.edu.az
  static String generateStaffEmail(String fullName, {List<String> existingEmails = const []}) {
    final username = _generateUsername(fullName);
    String email = '$username@idrak.edu.az';
    
    if (existingEmails.contains(email)) {
      int counter = 2;
      while (existingEmails.contains('$username$counter@idrak.edu.az')) {
        counter++;
      }
      email = '$username$counter@idrak.edu.az';
    }
    
    return email;
  }

  /// Şagird (Student) üçün rəsmi email yaradır (PC GoPanel və MariaDB ilə 1:1 eyni)
  /// Format: firstname.lastname@student.idrak.edu.az
  /// Təkrar olduqda: firstname.lastname2@student.idrak.edu.az
  /// Nümunə: "Zəhra Mövsümova" → "zehra.movsumova@student.idrak.edu.az"
  static String generateStudentEmail(
    String fullName,
    int year, {
    List<String> existingEmails = const [],
  }) {
    final username = _generateUsername(fullName);
    String email = '$username@student.idrak.edu.az';
    
    // Təkrarlanma yoxlaması
    if (existingEmails.contains(email)) {
      int counter = 2;
      while (existingEmails.contains('$username$counter@student.idrak.edu.az')) {
        counter++;
      }
      email = '$username$counter@student.idrak.edu.az';
    }
    
    return email;
  }

  /// FIN kodundan ili çıxarır
  static int getYearFromFIN(String finCode) {
    if (finCode.length >= 7) {
      final firstChar = finCode[0];
      int century = 2000;
      
      if (firstChar == '5' || firstChar == '6') {
        century = 2000; // 2000-2099
      } else if (firstChar == '3' || firstChar == '4') {
        century = 1900; // 1900-1999
      }
      
      final birthYearLastTwo = finCode.substring(4, 6);
      final parsedYear = int.tryParse(birthYearLastTwo) ?? 15;
      final birthYear = century + parsedYear;
      
      return birthYear + 6;
    }
    
    return DateTime.now().year;
  }

  /// FIN kodundan doğum tarixini oxuyur
  static DateTime? parseBirthDateFromFIN(String finCode) {
    if (finCode.length != 7) return null;
    
    try {
      final firstChar = finCode[0];
      int century = 2000;
      
      if (firstChar == '5' || firstChar == '6') {
        century = 2000;
      } else if (firstChar == '3' || firstChar == '4') {
        century = 1900;
      }
      
      final birthYearLastTwo = finCode.substring(4, 6);
      final yearLastTwo = int.tryParse(birthYearLastTwo);
      if (yearLastTwo == null) return null;
      final year = century + yearLastTwo;
      
      return DateTime(year, 1, 1);
    } catch (e) {
      return null;
    }
  }

  /// Valideyn (Parent) üçün rəsmi email yaradır (PC GoPanel və MariaDB ilə 1:1 eyni)
  /// Format: firstname.lastname@idrak.edu.az
  /// Təkrar olduqda: firstname.lastname2@idrak.edu.az
  /// Nümunə: "Sevil Hacıyeva" → "sevil.haciyeva@idrak.edu.az"
  static String generateParentEmail(String fullName, {List<String> existingEmails = const []}) {
    final username = _generateUsername(fullName);
    String email = '$username@idrak.edu.az';
    
    // Təkrarlanma yoxlaması
    if (existingEmails.contains(email)) {
      int counter = 2;
      while (existingEmails.contains('$username$counter@idrak.edu.az')) {
        counter++;
      }
      email = '$username$counter@idrak.edu.az';
    }
    
    return email;
  }

  /// Email-dən ad soyad çıxarır
  static String extractNameFromEmail(String email) {
    final username = email.split('@').first;
    final parts = username.split('.');
    
    final nameParts = parts.where((part) => 
      !part.startsWith('s') && 
      part != 'parent'
    ).toList();
    
    final capitalizedParts = nameParts.map((part) {
      if (part.isEmpty) return part;
      return part[0].toUpperCase() + part.substring(1);
    }).toList();
    
    return capitalizedParts.join(' ');
  }

  /// Email-in İdrak formatında olub-olmadığını yoxlayır
  static bool isValidIdrakEmail(String email) {
    final regex = RegExp(
      r'^[a-z0-9\._%+-]+@(student\.)?idrak\.edu\.az$',
      caseSensitive: false,
    );
    return regex.hasMatch(email);
  }

  /// Email tipini müəyyən edir
  static EmailType getEmailType(String email) {
    final lower = email.toLowerCase().trim();
    if (lower.contains('@student.idrak.edu.az') || lower.contains('.s')) return EmailType.student;
    if (lower.contains('.parent@')) return EmailType.parent;
    if (lower.contains('@idrak.edu.az')) return EmailType.staff;
    return EmailType.unknown;
  }
}

enum EmailType {
  staff,    // firstname.lastname@idrak.edu.az
  student,  // firstname.lastname@student.idrak.edu.az
  parent,   // firstname.lastname@idrak.edu.az
  unknown,
}
