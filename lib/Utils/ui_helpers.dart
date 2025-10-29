import 'package:intl/intl.dart';

  String getMonthName(int month) {
    switch (month) {
      case 1: return 'Enero';
      case 2: return 'Febrero';
      case 3: return 'Marzo';
      case 4: return 'Abril';
      case 5: return 'Mayo';
      case 6: return 'Junio';
      case 7: return 'Julio';
      case 8: return 'Agosto';
      case 9: return 'Septiembre';
      case 10: return 'Octubre';
      case 11: return 'Noviembre';
      case 12: return 'Diciembre';
      default: return '';
    }
  }

  String formatNumber(num value) {
    final formatter = NumberFormat('#,###');
    return formatter.format(value);
  }

  String formatCurrency(num value) {
    final formatter = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
    return formatter.format(value);
  }

String formatShortDate(String isoString) {
  final date = DateTime.parse(isoString);
  return DateFormat('dd/MM/yyyy').format(date);
}
