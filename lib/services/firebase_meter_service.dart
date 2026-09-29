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

  /// ESP32 code mein jo METER_ID diya hai, wahi yahan match hona chahiye
  final String meterId;

  /// Meters List screen se jo naam mila (sirf reference ke liye rakha hai)
  final String meterName;

  /// Kitne phases abhi connected hain (testing ke dauran 1, poore setup mein 3)
  final int connectedPhases;

  FirebaseMeterService({
    this.meterId = 'meter1',
    this.meterName = '',
    this.connectedPhases = 1,
  });

  /// ESP32 jahan latest reading likhta hai: /meters/{meterId}/latest
  String get _latestUrl => '$_dbUrl/meters/$meterId/latest.json';

  /// Ek dafa turant reading le kar aata hai (app shuru hote hi use hota hai).
  /// Agar fetch fail ho jaye (chhota network glitch, timeout waghera), 'null'
  /// wapas karta hai — is se caller ko pata chalta hai ke reading nahi mili,
  /// aur woh purani (last known good) value ko wahi rakh sakta hai, use
  /// zeros se overwrite karne ki bajaye.
  Future<MeterData?> fetchOnce() async {
    try {
      final response = await http
          .get(Uri.parse(_latestUrl))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200 && response.body != 'null') {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return _fromJson(data);
      }
    } catch (e) {
      // Network error, timeout, waghera — 'null' wapas karte hain taake
      // caller purani value ko na badle.
    }
    return null;
  }

  /// Har 2 second baad Firebase se naya reading laata rehta hai.
  /// Jab fetch fail ho, kuch bhi 'yield' nahi karta (stream chup chap agla
  /// try karega) — is se UI mein achanak zeros nahi dikhte.
  Stream<MeterData> get meterStream async* {
    while (true) {
      await Future.delayed(const Duration(seconds: 2));
      final reading = await fetchOnce();
      if (reading != null) {
        yield reading;
      }
      // reading null ho to kuch yield nahi karte — purani value UI mein
      // wahi rehti hai jab tak agli kamyaab reading na aa jaye.
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
        : DateTime.fromMillisecondsSinceEpoch(0);

    // Abhi sirf L1 (single-phase) se data aa raha hai, isliye L1 mein daal rahe hain
    // aur L2/L3 ko 0 chhod rahe hain — connectedPhases field UI ko batata hai
    // ke L2/L3 "not connected" hain, "0 reading" nahi.
    return MeterData(
      meterId: meterId,
      meterName: meterName,
      activePower: power / 1000, // W se kW
      voltageL1: voltage,
      voltageL2: 0,
      voltageL3: 0,
      currentL1: current,
      currentL2: 0,
      currentL3: 0,
      powerFactor: (m['powerFactor'] as num?)?.toDouble() ?? 0,
      frequency: (m['frequency'] as num?)?.toDouble() ?? 0,
      totalEnergy: (m['energy'] as num?)?.toDouble() ?? 0,
      timestamp: timestamp,
      connectedPhases: connectedPhases,
    );
  }
}
