import 'package:flutter/services.dart';

/// FIN Kod daxil edilərkən kiçik hərfləri avtomatik BÖYÜK hərfə çevirən formatter.
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

/// Bütün FİN kod sahələri üçün standart input formatter siyahısı (7 simvol, rəqəm və böyük hərflər)
List<TextInputFormatter> finCodeInputFormatters() {
  return [
    UpperCaseTextFormatter(),
    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
    LengthLimitingTextInputFormatter(7),
  ];
}

/// FİN Kod üçün universal validator
String? validateFinCode(String? value, {bool required = true}) {
  final val = (value ?? '').trim().toUpperCase();
  if (val.isEmpty) {
    if (required) return 'FİN kod tələb olunur';
    return null;
  }
  if (!RegExp(r'^[A-Z0-9]{7}$').hasMatch(val)) {
    return 'FİN kod 7 simvol (rəqəm və böyük hərf) olmalıdır';
  }
  return null;
}
