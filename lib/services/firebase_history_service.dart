import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/meter_data_model.dart';

/// Firebase mein ESP32 ne jo '/history/YYYY-MM-DD' entries save ki hain
/// (har din ka cumulative meter energy reading), unse real daily consumption
/// aur is mahine ki total consumption nikalta hai.
class FirebaseHistoryService {
  static const String _dbUrl =
      'https://finalyearproject-2034b-default-rtdb.asia-southeast1.firebasedatabase.app';

  Future<MonthlyData> fetchMonthlyData() async {
    try {
      final response = await http
          .get(Uri.parse('$_dbUrl/history.json'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200 || response.body == 'null') {
        return const MonthlyData(totalKwh: 0, daily: []);
      }

      final raw = jsonDecode(response.body) as Map<String, dynamic>;

      // Saari dates ko sort karein (chronological order mein), taake
      // "aaj ki reading - kal ki reading" wala hisaab sahi ho.
      final entries =
          raw.entries
              .map(
                (e) => MapEntry(
                  DateTime.parse(e.key),
                  (e.value as num).toDouble(),
                ),
              )
              .toList()
            ..sort((a, b) => a.key.compareTo(b.key));

      if (entries.isEmpty) return const MonthlyData(totalKwh: 0, daily: []);

      final now = DateTime.now();
      final List<DailyUsage> daily = [];
      double monthTotal = 0;

      for (int i = 1; i < entries.length; i++) {
        final today = entries[i].key;
        final delta = entries[i].value - entries[i - 1].value;
        final kwh = delta < 0
            ? 0.0
            : delta; // meter reset ho jaye to negative na aaye

        // Sirf isi mahine/saal ke din chart aur total mein ginte hain
        if (today.year == now.year && today.month == now.month) {
          daily.add(DailyUsage(day: today.day, kwh: kwh));
          monthTotal += kwh;
        }
      }

      return MonthlyData(totalKwh: monthTotal, daily: daily);
    } catch (e) {
      // Network error waghera — khaali data wapas karein, UI crash na ho
      return const MonthlyData(totalKwh: 0, daily: []);
    }
  }
}
