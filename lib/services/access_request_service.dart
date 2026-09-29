import 'dart:convert';
import 'package:http/http.dart' as http;

class AccessRequestService {
  static const String _dbUrl =
      'https://finalyearproject-2034b-default-rtdb.asia-southeast1.firebasedatabase.app';

  Future<void> submit({
    required String name,
    required String email,
    required String message,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_dbUrl/meterRequests.json'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'customerUid': '',
            'customerName': name,
            'customerEmail': email,
            'note': message.isEmpty ? 'Account access request' : message,
            'requestType': 'account_access',
            'status': 'pending',
            'createdAt': DateTime.now().millisecondsSinceEpoch,
          }),
        )
        .timeout(const Duration(seconds: 8));

    if (response.statusCode != 200) {
      throw Exception('Could not send request. Please try again.');
    }
  }
}
