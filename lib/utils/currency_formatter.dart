import 'package:intl/intl.dart';

String formatCurrency(double amount) {
  final formatter = NumberFormat('#,##0.00', 'en_US');
  return 'Rs. ${formatter.format(amount)}';
}

String formatCurrencyCompact(double amount) {
  if (amount >= 1000000) {
    return 'Rs. ${(amount / 1000000).toStringAsFixed(1)}M';
  } else if (amount >= 1000) {
    return 'Rs. ${(amount / 1000).toStringAsFixed(1)}K';
  }
  return formatCurrency(amount);
} 