import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/admin_models.dart';

class FirebaseAdminService {
  static const String _dbUrl =
      'https://finalyearproject-2034b-default-rtdb.asia-southeast1.firebasedatabase.app';

  Future<AdminSummary> fetchSummary() async {
    try {
      final usersRes = await http
          .get(Uri.parse('$_dbUrl/users.json'))
          .timeout(const Duration(seconds: 8));
      final requestsRes = await http
          .get(Uri.parse('$_dbUrl/meterRequests.json'))
          .timeout(const Duration(seconds: 8));

      final List<CustomerSummary> customers = [];
      int totalMeters = 0;

      if (usersRes.statusCode == 200 && usersRes.body != 'null') {
        final users = jsonDecode(usersRes.body) as Map<String, dynamic>;

        for (final entry in users.entries) {
          final data = (entry.value as Map).cast<String, dynamic>();
          final role = (data['role'] ?? 'customer').toString();
          if (role == 'admin') continue; // Admins khud list mein nahi chahiye

          final metersMap =
              (data['meters'] as Map?)?.cast<String, dynamic>() ?? {};
          final meterIds = metersMap.keys.toList();
          totalMeters += meterIds.length;

          final isOnline = await _anyMeterOnline(meterIds);

          customers.add(
            CustomerSummary(
              uid: entry.key,
              name: (data['name'] ?? 'Unnamed').toString(),
              meterIds: meterIds,
              isOnline: isOnline,
            ),
          );
        }
      }

      final List<MeterRequest> requests = [];
      if (requestsRes.statusCode == 200 && requestsRes.body != 'null') {
        final raw = jsonDecode(requestsRes.body) as Map<String, dynamic>;
        for (final entry in raw.entries) {
          final data = (entry.value as Map).cast<String, dynamic>();
          if ((data['status'] ?? 'pending').toString() != 'pending') continue;
          requests.add(
            MeterRequest(
              id: entry.key,
              customerUid: (data['customerUid'] ?? '').toString(),
              customerName: (data['customerName'] ?? 'Unknown').toString(),
              message: (data['message'] ?? 'Requesting a new meter').toString(),
            ),
          );
        }
      }

      customers.sort((a, b) => a.name.compareTo(b.name));

      return AdminSummary(
        customers: customers,
        totalMeters: totalMeters,
        pendingRequests: requests,
      );
    } catch (e) {
      return AdminSummary(customers: [], totalMeters: 0, pendingRequests: []);
    }
  }

  /// Customer ke kisi bhi meter ki 'latest.timestamp' 10 sec se kam purani ho
  /// to online samjha jata hai — Dashboard wale isMeterOnline logic jaisa.
  Future<bool> _anyMeterOnline(List<String> meterIds) async {
    for (final id in meterIds) {
      try {
        final res = await http
            .get(Uri.parse('$_dbUrl/meters/$id/latest/timestamp.json'))
            .timeout(const Duration(seconds: 5));
        if (res.statusCode == 200 && res.body != 'null') {
          final ts = int.tryParse(res.body);
          if (ts != null) {
            final age = DateTime.now()
                .difference(DateTime.fromMillisecondsSinceEpoch(ts))
                .inSeconds;
            // Thoda negative age (phone ke clock skew) bhi online ginte hain.
            if (age > -60 && age < 10) return true;
          }
        }
      } catch (_) {}
    }
    return false;
  }

  /// Ek request ko "fulfilled" mark karta hai (Admin ne meter laga diya).
  Future<void> markRequestFulfilled(String requestId) async {
    try {
      await http.patch(
        Uri.parse('$_dbUrl/meterRequests/$requestId.json'),
        body: jsonEncode({'status': 'fulfilled'}),
      );
    } catch (_) {}
  }
}
