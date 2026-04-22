import 'package:intl/intl.dart';

class Formatters {
  const Formatters._();

  static final _dateTimeFormatter = DateFormat('yyyy-MM-dd HH:mm');
  static final _dateFormatter = DateFormat('yyyy-MM-dd');

  static String dateTime(DateTime? value) {
    if (value == null) {
      return '--';
    }
    return _dateTimeFormatter.format(value.toLocal());
  }

  static String date(DateTime? value) {
    if (value == null) {
      return '--';
    }
    return _dateFormatter.format(value.toLocal());
  }

  static String friendlyCount(num? value) {
    if (value == null) {
      return '--';
    }
    return NumberFormat.compact().format(value);
  }
}
