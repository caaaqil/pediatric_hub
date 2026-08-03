import 'package:intl/intl.dart';

/// Date/number formatting shared by every screen.
class Fmt {
  const Fmt._();

  static final DateFormat _date = DateFormat('d MMM yyyy');
  static final DateFormat _dateShort = DateFormat('d MMM');
  static final DateFormat _dateTime = DateFormat('d MMM yyyy · HH:mm');
  static final DateFormat _time = DateFormat('HH:mm');
  static final DateFormat _weekday = DateFormat('EEEE, d MMMM');
  static final DateFormat _iso = DateFormat('yyyy-MM-dd');

  static String date(DateTime? value) =>
      value == null ? '—' : _date.format(value.toLocal());

  static String dateShort(DateTime? value) =>
      value == null ? '—' : _dateShort.format(value.toLocal());

  static String dateTime(DateTime? value) =>
      value == null ? '—' : _dateTime.format(value.toLocal());

  static String time(DateTime? value) =>
      value == null ? '—' : _time.format(value.toLocal());

  static String weekday(DateTime? value) =>
      value == null ? '—' : _weekday.format(value.toLocal());

  static String isoDate(DateTime value) => _iso.format(value);

  static String money(double amount, {String currency = 'USD'}) {
    final NumberFormat f = NumberFormat.currency(
      symbol: currency == 'USD' ? r'$' : '$currency ',
      decimalDigits: 2,
    );
    return f.format(amount);
  }

  static String metric(double? value, String unit) {
    if (value == null) return '—';
    final String text = value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
    return '$text $unit';
  }

  /// "3 days ago" / "in 2 weeks" — used on notification and vaccine rows.
  static String relative(DateTime? value) {
    if (value == null) return '—';
    final DateTime now = DateTime.now();
    final Duration diff = value.toLocal().difference(now);
    final bool past = diff.isNegative;
    final Duration abs = diff.abs();

    String phrase;
    if (abs.inMinutes < 1) {
      return 'just now';
    } else if (abs.inMinutes < 60) {
      phrase = '${abs.inMinutes} min';
    } else if (abs.inHours < 24) {
      phrase = '${abs.inHours} hour${abs.inHours == 1 ? '' : 's'}';
    } else if (abs.inDays < 7) {
      phrase = '${abs.inDays} day${abs.inDays == 1 ? '' : 's'}';
    } else if (abs.inDays < 30) {
      final int weeks = abs.inDays ~/ 7;
      phrase = '$weeks week${weeks == 1 ? '' : 's'}';
    } else if (abs.inDays < 365) {
      final int months = abs.inDays ~/ 30;
      phrase = '$months month${months == 1 ? '' : 's'}';
    } else {
      final int years = abs.inDays ~/ 365;
      phrase = '$years year${years == 1 ? '' : 's'}';
    }

    return past ? '$phrase ago' : 'in $phrase';
  }

  /// Turns SCREAMING_SNAKE into "Screaming snake" for audit actions etc.
  static String humanize(String value) {
    if (value.isEmpty) return value;
    final String spaced = value.replaceAll('_', ' ').toLowerCase();
    return spaced[0].toUpperCase() + spaced.substring(1);
  }
}
