import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static final _currencyFormat = NumberFormat('#,###', 'vi_VN');
  static final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  static String price(double value) {
    if (value >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(1)}B';
    }
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return '${_currencyFormat.format(value)}đ';
    }
    return '${value.toStringAsFixed(0)}đ';
  }

  static String priceShort(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}k';
    }
    return value.toStringAsFixed(0);
  }

  static String priceFull(double value) {
    return '${_currencyFormat.format(value)}đ';
  }

  static String number(int value) {
    return _currencyFormat.format(value);
  }

  static String date(DateTime? dt) {
    if (dt == null) return '-';
    return _dateFormat.format(dt);
  }

  static String percent(double value) {
    return '${value.toStringAsFixed(0)}%';
  }
}
