import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/meter_data_model.dart';

/// Firebase Realtime Database se live meter data padhta hai.
/// DummyDataService ki jagah use hoga jab real hardware/ESP32 connected ho.
///
/// Setup: pubspec.yaml mein 'http: ^1.2.0' dependency add karein.
class FirebaseMeterService {
  // Firebase console se mila hua Database URL yahan dalein (aakhir slash NA lagayein)
  static const String _dbUrl =
      'https://finalyearproject-2034b-default-rtdb.asia-southeast1.firebasedatabase.app';

  /// Kitne phases abhi connected hain (testing ke dauran 1, poore setup mein 3)
  final int connectedPhases;

  FirebaseMeterService({this.connectedPhases = 1});

  /// Ek dafa turant reading le kar aata hai (app shuru hote hi use hota hai)
  Future<MeterData> fetchOnce() async {
    try {
      final response = await http
          .get(Uri.parse('$_dbUrl/latest.json'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200 && response.body != 'null') {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return _fromJson(data);
      }
    } catch (e) {
      // Network error, Firebase abhi khaali hai, waghera — empty data wapas karein
    }
    return MeterData.empty();
  }

  /// Har 2 second baad Firebase se naya reading laata rehta hai
  Stream<MeterData> get meterStream async* {
    while (true) {
      await Future.delayed(const Duration(seconds: 2));
      yield await fetchOnce();
    }
  }

  MeterData _fromJson(Map<String, dynamic> m) {
    final voltage = (m['voltage'] as num?)?.toDouble() ?? 0;
    final current = (m['current'] as num?)?.toDouble() ?? 0;
    final power = (m['power'] as num?)?.toDouble() ?? 0;

    // Firebase ka apna server timestamp use karte hain (ESP32 ke bheje hue
    // waqt se), taake pata chal sake ke ye reading kitni purani hai —
    // isi se "Meter Offline" detect hoga agar naya data aana ruk jaye.
    final tsMillis = (m['timestamp'] as num?)?.toInt();
    final timestamp = tsMillis != null
        ? DateTime.fromMillisecondsSinceEpoch(tsMillis)
        : DateTime.now();

    // Abhi sirf L1 (single-phase) se data aa raha hai, isliye L1 mein daal rahe hain
    // aur L2/L3 ko 0 chhod rahe hain — connectedPhases field UI ko batata hai
    // ke L2/L3 "not connected" hain, "0 reading" nahi.
    return MeterData(
      activePower: power / 1000, // W se kW
      voltageL1: voltage,
      voltageL2: 0,
      voltageL3: 0,
      currentL1: current,
      currentL2: 0,
      currentL3: 0,
      powerFactor: (m['powerFactor'] as num?)?.toDouble() ?? 0,
      frequency: (m['frequency'] as num?)?.toDouble() ?? 0,
      totalEnergy:
          0, // Baad mein energy register bhi Firebase mein add kar sakte hain
      timestamp: timestamp,
      connectedPhases: connectedPhases,
    );
  }
}
