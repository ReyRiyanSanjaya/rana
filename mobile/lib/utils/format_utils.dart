import 'package:intl/intl.dart';

class FormatUtils {
  static String formatCurrency(double value) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(value);
  }
}
