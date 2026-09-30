import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/meter_data_model.dart';

/// Firebase mein ESP32 ne jo '/meters/{meterId}/history/YYYY-MM-DD' entries
/// save ki hain (har din ka cumulative meter energy reading), unse real
/// daily consumption aur is mahine ki total consumption nikalta hai.
class FirebaseHistoryService {
  static const String _dbUrl =
      'https://finalyearproject-2034b-default-rtdb.asia-southeast1.firebasedatabase.app';

  /// ESP32 code mein jo METER_ID diya hai, wahi yahan match hona chahiye
  /// (abhi ESP32 mein "meter1" hai) — FirebaseMeterService ke meterId se
  /// bhi match hona chahiye.
  final String meterId;

  FirebaseHistoryService({this.meterId = 'meter1'});

  /// ESP32 jahan history likhta hai: /meters/{meterId}/history
  String get _historyUrl =>
      '$_dbUrl/meters/${Uri.encodeComponent(meterId)}/history.json';

  Future<List<DatedDailyUsage>> fetchDailyUsage() async {
    try {
      final response = await http
          .get(Uri.parse(_historyUrl))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200 || response.body == 'null') {
        return const [];
      }

      final raw = jsonDecode(response.body) as Map<String, dynamic>;
      return parseDailyUsage(raw);
    } catch (e) {
      return const [];
    }
  }

  static List<DatedDailyUsage> parseDailyUsage(Map<String, dynamic> raw) {
    final entries = <MapEntry<DateTime, double>>[];
    for (final entry in raw.entries) {
      final value = entry.value;
      if (value is! num) continue;
      try {
        final parsedDate = DateTime.parse(entry.key);
        entries.add(
          MapEntry(
            DateTime(parsedDate.year, parsedDate.month, parsedDate.day),
            value.toDouble(),
          ),
        );
      } on FormatException {
        continue;
      }
    }
    entries.sort((a, b) => a.key.compareTo(b.key));
    if (entries.length < 2) return const [];

    final daily = <DatedDailyUsage>[];
    for (int i = 1; i < entries.length; i++) {
      final date = entries[i].key;
      final delta = entries[i].value - entries[i - 1].value;
      final kwh = delta < 0 ? 0.0 : delta;
      daily.add(DatedDailyUsage(date: date, kwh: kwh));
    }
    return daily;
  }

  Future<MonthlyData> fetchMonthlyData() async {
    final now = DateTime.now();
    final daily = (await fetchDailyUsage())
        .where(
          (entry) =>
              entry.date.year == now.year && entry.date.month == now.month,
        )
        .toList();
    return MonthlyData(
      totalKwh: daily.fold(0.0, (total, entry) => total + entry.kwh),
      daily: daily
          .map((entry) => DailyUsage(day: entry.date.day, kwh: entry.kwh))
          .toList(),
    );
  }
}
