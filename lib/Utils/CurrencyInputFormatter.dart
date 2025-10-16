import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat('#,###'); // sin decimales

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {

    String newTextRaw = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (newTextRaw.isEmpty) return newValue.copyWith(text: '');

    int? number = int.tryParse(newTextRaw);
    if (number == null) return oldValue;

    String formatted = _formatter.format(number);

    int baseOffset = newValue.selection.baseOffset;
    int diff = formatted.length - newValue.text.length;

    int newCursorPos;
    if (oldValue.text.isEmpty) {
      newCursorPos = formatted.length;
    } else {
      newCursorPos = (baseOffset + diff).clamp(0, formatted.length);
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: newCursorPos),
    );
  }
}
