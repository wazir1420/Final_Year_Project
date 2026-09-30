import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/meter_data_model.dart';

/// Firebase mein ESP32 ne jo readings save ki hain unse real usage nikalta hai:
/// - /meters/{id}/history/{YYYY-MM-DD} = har din ka cumulative kWh (daily chart)
/// - /meters/{id}/hourly/{YYYY-MM-DD}/{HH} = har ghante ka cumulative kWh
///   (power trend + peak hours heatmap) — ESP32 code se add hua.
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

  /// ESP32 jahan hourly history likhta hai: /meters/{meterId}/hourly
  String get _hourlyUrl =>
      '$_dbUrl/meters/${Uri.encodeComponent(meterId)}/hourly.json';

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

  /// Ghante ke cumulative readings se per-hour kWh nikalta hai.
  /// Raw nodes: {"2026-09-30": {"h21": 0.21, "h22": 0.35}, ...}
  Future<List<HourlyUsage>> fetchHourlyUsage() async {
    try {
      final response = await http
          .get(Uri.parse(_hourlyUrl))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode != 200 || response.body == 'null') {
        return const [];
      }
      final raw = jsonDecode(response.body);
      if (raw is! Map<String, dynamic>) return const [];
      return parseHourlyUsage(raw);
    } catch (e) {
      return const [];
    }
  }

  /// {"2026-09-30": {"h21": 0.21, ...}, ...} → sorted [HourlyUsage]
  /// Firebase numeric keys (0,1,2...) ko array bana deta hai, is liye
  /// dono formats handle karte hain:
  /// - Map:  {"23": 0.21} ya {"h23": 0.21}  ("h" prefix ESP32 se)
  /// - List: [0.22, 0.23]  (index hi hour hota hai; null gaps skip)
  static List<HourlyUsage> parseHourlyUsage(Map<String, dynamic> raw) {
    final entries = <MapEntry<DateTime, double>>[];
    for (final dayEntry in raw.entries) {
      DateTime day;
      try {
        day = DateTime.parse(dayEntry.key);
      } on FormatException {
        continue;
      }
      final hours = <int, double>{};
      final value = dayEntry.value;
      if (value is Map) {
        for (final h in value.entries) {
          final digits = h.key.toString().replaceAll(RegExp('[^0-9]'), '');
          final hourOfDay = int.tryParse(digits);
          final v = h.value;
          if (hourOfDay == null || hourOfDay < 0 || hourOfDay > 23) continue;
          if (v is! num) continue;
          hours[hourOfDay] = v.toDouble();
        }
      } else if (value is List) {
        for (int i = 0; i < value.length && i <= 23; i++) {
          final v = value[i];
          if (v is! num) continue;
          hours[i] = v.toDouble();
        }
      }
      for (final h in hours.entries) {
        entries.add(
          MapEntry(day.add(Duration(hours: h.key)), h.value),
        );
      }
    }
    if (entries.length < 2) return const [];

    // Cumulative → per-hour kWh (meter reset ho to delta 0 rakhte hain).
    entries.sort((a, b) => a.key.compareTo(b.key));
    final hourly = <HourlyUsage>[];
    for (int i = 1; i < entries.length; i++) {
      final delta = entries[i].value - entries[i - 1].value;
      hourly.add(
        HourlyUsage(hourStart: entries[i].key, kwh: delta < 0 ? 0.0 : delta),
      );
    }
    return hourly;
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
