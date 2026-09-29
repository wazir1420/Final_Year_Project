import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/meter_summary_model.dart';

/// Sab meters ki summary list Firebase Realtime Database se laata hai.
class FirebaseMetersListService {
  static const String _dbUrl =
      'https://finalyearproject-2034b-default-rtdb.asia-southeast1.firebasedatabase.app';

  Future<MeterSummary?> fetchMeter(String meterId) async {
    try {
      final response = await http
          .get(Uri.parse('$_dbUrl/meters/${Uri.encodeComponent(meterId)}.json'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200 || response.body == 'null') return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return MeterSummary.fromJson(meterId, data);
    } catch (e) {
      // network error, Firebase khaali, waghera
      return null;
    }
  }

  Future<List<MeterSummary>> fetchOnce(List<String> meterIds) async {
    final results = await Future.wait(meterIds.toSet().map(fetchMeter));
    return results.whereType<MeterSummary>().toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  Stream<List<MeterSummary>> metersStream(List<String> meterIds) async* {
    while (true) {
      await Future.delayed(const Duration(seconds: 2));
      yield await fetchOnce(meterIds);
    }
  }
}
