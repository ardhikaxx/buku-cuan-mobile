import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _rupiahFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static final NumberFormat _numberFormat = NumberFormat('#,###', 'id_ID');

  static String formatRupiah(double amount) {
    return _rupiahFormat.format(amount);
  }

  static String formatNumber(double amount) {
    if (amount == 0) return '0';
    return _numberFormat.format(amount);
  }

  static String formatRupiahShort(double amount) {
    if (amount >= 1000000000) {
      return 'Rp ${(amount / 1000000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000000) {
      return 'Rp ${(amount / 1000000).toStringAsFixed(1)}jt';
    } else if (amount >= 1000) {
      return 'Rp ${(amount / 1000).toStringAsFixed(0)}rb';
    }
    return formatRupiah(amount);
  }

  static double parseRupiah(String value) {
    String cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
    return double.tryParse(cleaned) ?? 0;
  }
}

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    String cleanText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanText.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    double value = double.tryParse(cleanText) ?? 0;
    final formatted = NumberFormat('#,###', 'id_ID').format(value);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class DateFormatter {
  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy', 'id_ID').format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('dd MMM yyyy HH:mm', 'id_ID').format(date);
  }

  static String formatMonthYear(DateTime date) {
    return DateFormat('MMMM yyyy', 'id_ID').format(date);
  }

  static String formatDayMonth(DateTime date) {
    return DateFormat('dd MMM', 'id_ID').format(date);
  }

  static String formatShortDate(DateTime date) {
    return DateFormat('dd/MM/yyyy', 'id_ID').format(date);
  }
}

class TokenUtils {
  static String maskToken(String token) {
    if (token.length <= 8) return token;
    final parts = token.split('-');
    if (parts.length >= 4) {
      return '${parts[0]}-****-****-${parts.last}';
    }
    return '${token.substring(0, 4)}****${token.substring(token.length - 4)}';
  }
}
