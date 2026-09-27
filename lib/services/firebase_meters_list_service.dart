import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/meter_summary_model.dart';

/// Sab meters ki summary list Firebase Realtime Database se laata hai.
class FirebaseMetersListService {
  static const String _dbUrl =
      'https://finalyearproject-2034b-default-rtdb.asia-southeast1.firebasedatabase.app';

  Future<List<MeterSummary>> fetchOnce() async {
    try {
      final response = await http
          .get(Uri.parse('$_dbUrl/meters.json'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200 && response.body != 'null') {
        final raw = jsonDecode(response.body) as Map<String, dynamic>;
        return raw.entries
            .map(
              (e) => MeterSummary.fromJson(
                e.key,
                (e.value as Map).cast<String, dynamic>(),
              ),
            )
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));
      }
    } catch (e) {
      // network error, Firebase khaali, waghera
    }
    return [];
  }

  Stream<List<MeterSummary>> get metersStream async* {
    while (true) {
      await Future.delayed(const Duration(seconds: 2));
      yield await fetchOnce();
    }
  }
}
