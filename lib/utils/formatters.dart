import 'package:intl/intl.dart';

String money(num value) =>
    'N${NumberFormat.currency(locale: 'en_IN', symbol: 'Rs ', decimalDigits: 0).format(value)}';
String initials(String name) => name.trim().isEmpty
    ? '?'
    : name
          .trim()
          .split(RegExp(r'\s+'))
          .take(2)
          .map((part) => part[0])
          .join()
          .toUpperCase();
DateTime day(DateTime date) => DateTime(date.year, date.month, date.day);
