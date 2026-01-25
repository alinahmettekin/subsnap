import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String format(double amount, {String currency = 'TRY', int decimalDigits = 2}) {
    if (currency == 'TRY' || currency == '₺') {
      final formatter = NumberFormat.currency(
        locale: 'tr_TR',
        symbol: '',
        decimalDigits: decimalDigits,
      );
      return '${formatter.format(amount).trim()} TL';
    }

    try {
      return NumberFormat.simpleCurrency(name: currency, decimalDigits: decimalDigits).format(amount);
    } catch (e) {
      // Fallback for unsupported currencies
      return '${amount.toStringAsFixed(decimalDigits)} $currency';
    }
  }
}
