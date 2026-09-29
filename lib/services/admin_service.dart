import 'dart:convert';
import 'package:http/http.dart' as http;

class AdminCustomer {
  final String uid;
  final String name;
  final String email;
  final List<String> meterIds;
  final bool isOnline; // koi bhi ek meter online ho to true

  AdminCustomer({
    required this.uid,
    required this.name,
    required this.email,
    required this.meterIds,
    required this.isOnline,
  });
}

class MeterRequest {
  final String id;
  final String customerUid;
  final String customerName;
  final String customerEmail;
  final String note;
  final String requestType;

  MeterRequest({
    required this.id,
    required this.customerUid,
    required this.customerName,
    required this.customerEmail,
    required this.note,
    required this.requestType,
  });
}

/// Admin Panel ke saare Firebase operations — naya customer banana, meter
/// assign karna, pending requests dekhna/poora karna. Login ki tarah hi
/// simple REST API se kaam karta hai, koi extra package nahi chahiye.
class AdminService {
  static const String _apiKey = 'AIzaSyBPYzRRdPnMBtVv_3wBbbAlTEDfHKesu-k';
  static const String _signUpUrl =
      'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$_apiKey';
  static const String _dbUrl =
      'https://finalyearproject-2034b-default-rtdb.asia-southeast1.firebasedatabase.app';

  /// Naya Firebase Authentication account banata hai (sirf email/password),
  /// UID wapas karta hai. Admin ke apne login session par koi asar nahi
  /// padta kyunke ye stateless REST call hai.
  Future<String> _createAuthAccount(String email, String password) async {
    final response = await http.post(
      Uri.parse(_signUpUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'returnSecureToken': true,
      }),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) {
      return data['localId'] as String;
    }
    final errorCode = data['error']?['message'] as String? ?? '';
    if (errorCode.contains('EMAIL_EXISTS')) {
      throw Exception('Ye email pehle se registered hai');
    }
    if (errorCode.contains('WEAK_PASSWORD')) {
      throw Exception('Password kam az kam 6 characters ka hona chahiye');
    }
    throw Exception('Account nahi ban saka, dobara koshish karein');
  }

  /// Naya customer banata hai aur uska pehla meter bhi register kar deta hai.
  Future<void> createCustomerWithMeter({
    required String name,
    required String email,
    required String password,
    required String meterId,
    required String meterName,
  }) async {
    final uid = await _createAuthAccount(email, password);

    // /users/{uid} record banayein
    await http.put(
      Uri.parse('$_dbUrl/users/$uid.json'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'role': 'customer',
        'meters': {meterId: true},
      }),
    );

    // /meters/{meterId} record banayein (ESP32 baad mein 'latest'/'history' likhega)
    await http.put(
      Uri.parse('$_dbUrl/meters/$meterId/name.json'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(meterName),
    );
    await http.put(
      Uri.parse('$_dbUrl/meters/$meterId/ownerId.json'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(uid),
    );
  }

  /// Kisi maujooda customer ke liye naya meter add karta hai (jaise request
  /// poori karte waqt).
  Future<void> addMeterToCustomer({
    required String customerUid,
    required String meterId,
    required String meterName,
  }) async {
    await http.put(
      Uri.parse('$_dbUrl/meters/$meterId/name.json'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(meterName),
    );
    await http.put(
      Uri.parse('$_dbUrl/meters/$meterId/ownerId.json'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(customerUid),
    );
    await http.put(
      Uri.parse('$_dbUrl/users/$customerUid/meters/$meterId.json'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(true),
    );
  }

  /// Sab customers ki list laata hai, unke meters ke sath
  Future<List<AdminCustomer>> fetchCustomers() async {
    final usersRes = await http
        .get(Uri.parse('$_dbUrl/users.json'))
        .timeout(const Duration(seconds: 8));

    if (usersRes.statusCode != 200 || usersRes.body == 'null') return [];

    final usersRaw = jsonDecode(usersRes.body) as Map<String, dynamic>;

    // Sab meters ki latest reading bhi ek sath le aate hain, taake
    // online/offline status pata chal sake
    Map<String, dynamic> metersRaw = {};
    try {
      final metersRes = await http
          .get(Uri.parse('$_dbUrl/meters.json'))
          .timeout(const Duration(seconds: 8));
      if (metersRes.statusCode == 200 && metersRes.body != 'null') {
        metersRaw = jsonDecode(metersRes.body) as Map<String, dynamic>;
      }
    } catch (_) {}

    final List<AdminCustomer> customers = [];

    usersRaw.forEach((uid, value) {
      final data = (value as Map).cast<String, dynamic>();
      if (data['role'] != 'customer') return;

      final metersMap = (data['meters'] as Map?)?.cast<String, dynamic>() ?? {};
      final meterIds = metersMap.keys.toList();

      bool anyOnline = false;
      for (final mId in meterIds) {
        final meterData = (metersRaw[mId] as Map?)?.cast<String, dynamic>();
        final latest = (meterData?['latest'] as Map?)?.cast<String, dynamic>();
        final ts = (latest?['timestamp'] as num?)?.toInt();
        if (ts != null) {
          final age = DateTime.now()
              .difference(DateTime.fromMillisecondsSinceEpoch(ts))
              .inSeconds;
          if (age >= 0 && age < 20) anyOnline = true;
        }
      }

      customers.add(
        AdminCustomer(
          uid: uid,
          name: (data['name'] ?? '').toString(),
          email: (data['email'] ?? '').toString(),
          meterIds: meterIds,
          isOnline: anyOnline,
        ),
      );
    });

    customers.sort((a, b) => a.name.compareTo(b.name));
    return customers;
  }

  /// Pending meter requests laata hai
  Future<List<MeterRequest>> fetchPendingRequests() async {
    try {
      final response = await http
          .get(Uri.parse('$_dbUrl/meterRequests.json'))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200 || response.body == 'null') return [];

      final raw = jsonDecode(response.body) as Map<String, dynamic>;
      final List<MeterRequest> requests = [];

      raw.forEach((id, value) {
        final data = (value as Map).cast<String, dynamic>();
        if (data['status'] != 'pending') return;
        requests.add(
          MeterRequest(
            id: id,
            customerUid: (data['customerUid'] ?? '').toString(),
            customerName: (data['customerName'] ?? '').toString(),
            customerEmail: (data['customerEmail'] ?? '').toString(),
            note: (data['note'] ?? '').toString(),
            requestType: (data['requestType'] ?? 'meter').toString(),
          ),
        );
      });

      return requests;
    } catch (e) {
      return [];
    }
  }

  /// Request ko "poora ho gaya" mark karta hai
  Future<void> markRequestFulfilled(String requestId) async {
    await http.patch(
      Uri.parse('$_dbUrl/meterRequests/$requestId.json'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'status': 'fulfilled'}),
    );
  }

  Future<void> deleteRequest(String requestId) async {
    final response = await http
        .delete(Uri.parse('$_dbUrl/meterRequests/$requestId.json'))
        .timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) {
      throw Exception('Request delete nahi ho saki');
    }
  }
}
