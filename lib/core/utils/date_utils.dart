import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AppDateUtils {
  static String formatTimestamp(Timestamp timestamp, {String format = 'd/MM/yyyy HH:mm'}) {
    return DateFormat(format).format(timestamp.toDate());
  }

  static String formatDate(DateTime date, {String format = 'd/MM/yyyy'}) {
    return DateFormat(format).format(date);
  }

  static String getRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);
    
    if (difference.isNegative) {
      return 'Vencida';
    } else if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} min';
      }
      return '${difference.inHours} hrs';
    } else if (difference.inDays == 1) {
      return 'Mañana';
    }
    return '${difference.inDays} días';
  }
}
