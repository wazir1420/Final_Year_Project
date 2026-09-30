import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/ke_tariff_model.dart';
import 'auth_service.dart';

class KETariffProfileService {
  static const String _dbUrl =
      'https://finalyearproject-2034b-default-rtdb.asia-southeast1.firebasedatabase.app';

  final AuthService _authService = AuthService();

  Future<KETariffProfile> fetch(String meterId) async {
    final uid = await _authService.getCurrentUid();
    if (uid.isEmpty) return const KETariffProfile();

    final token = await _authService.getFreshIdToken();
    final uri = Uri.parse(
      '$_dbUrl/users/${Uri.encodeComponent(uid)}/meterTariffs/${Uri.encodeComponent(meterId)}.json',
    ).replace(queryParameters: {'auth': token});
    final response = await http.get(uri).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw Exception('K-Electric tariff settings load nahi ho sake.');
    }
    if (response.body == 'null') return const KETariffProfile();

    final data = jsonDecode(response.body);
    if (data is! Map) return const KETariffProfile();
    return KETariffProfile.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> save(String meterId, KETariffProfile profile) async {
    final uid = await _authService.getCurrentUid();
    if (uid.isEmpty) {
      throw Exception('Session expire ho gayi. Dobara login karein.');
    }

    final token = await _authService.getFreshIdToken();
    final uri = Uri.parse(
      '$_dbUrl/users/${Uri.encodeComponent(uid)}/meterTariffs/${Uri.encodeComponent(meterId)}.json',
    ).replace(queryParameters: {'auth': token});
    final response = await http
        .put(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(profile.toJson()),
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('K-Electric tariff settings save nahi ho sakin.');
    }
  }
}
