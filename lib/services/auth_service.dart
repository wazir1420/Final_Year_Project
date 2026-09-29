import 'dart:convert';
import 'package:http/http.dart' as http;

/// Firebase Authentication ke REST API se login karta hai (koi firebase_auth
/// package ya native setup nahi chahiye — humare baaki services ki tarah
/// simple HTTP requests hi use ho rahi hain).
class AuthService {
  // Firebase Project Settings > General > Web API Key se mila hua
  static const String _apiKey = 'AIzaSyBPYzRRdPnMBtVv_3wBbbAlTEDfHKesu-k';
  static const String _authUrl =
      'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$_apiKey';

  static const String _dbUrl =
      'https://finalyearproject-2034b-default-rtdb.asia-southeast1.firebasedatabase.app';

  /// Email/password se login karta hai. Kamyaab hone par user ka UID wapas
  /// karta hai. Fail hone par Exception throw karta hai (message user ko
  /// dikhaya ja sakta hai).
  Future<String> signIn(String email, String password) async {
    final response = await http
        .post(
          Uri.parse(_authUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': email,
            'password': password,
            'returnSecureToken': true,
          }),
        )
        .timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200) {
      return data['localId'] as String; // ye Firebase ka UID hai
    }

    // Firebase error codes ko simple Roman Urdu message mein convert karte hain
    final errorCode = data['error']?['message'] as String? ?? '';
    throw Exception(_friendlyError(errorCode));
  }

  String _friendlyError(String code) {
    if (code.contains('EMAIL_NOT_FOUND') ||
        code.contains('INVALID_LOGIN_CREDENTIALS')) {
      return 'Email ya password ghalat hai';
    }
    if (code.contains('INVALID_EMAIL')) {
      return 'Email sahi format mein nahi hai';
    }
    if (code.contains('USER_DISABLED')) {
      return 'Ye account band kar diya gaya hai';
    }
    if (code.contains('TOO_MANY_ATTEMPTS')) {
      return 'Bohat zyada koshish ho gayi, thodi der baad try karein';
    }
    if (code.contains('CONFIGURATION_NOT_FOUND')) {
      return 'Email/Password sign-in Firebase console mein enable nahi hai';
    }
    if (code.contains('API_KEY_INVALID') ||
        code.contains('API key not valid')) {
      return 'API Key ghalat hai';
    }
    return 'Login nahi ho saka, dobara koshish karein';
  }

  /// Login hone ke baad user ka record Realtime Database se laata hai —
  /// isi se pata chalta hai ke role kya hai (admin/customer) aur customer
  /// ke paas kaunse meters hain.
  Future<UserProfile?> fetchUserProfile(String uid) async {
    try {
      final response = await http
          .get(Uri.parse('$_dbUrl/users/$uid.json'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200 && response.body != 'null') {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return UserProfile.fromJson(uid, data);
      }
    } catch (e) {
      // network error waghera
    }
    return null;
  }
}

/// Login hone ke baad user ke baare mein zaroori maloomat
class UserProfile {
  final String uid;
  final String name;
  final String email;
  final String role; // "admin" ya "customer"
  final List<String> meterIds; // customer ke paas jo meters hain

  UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.meterIds,
  });

  bool get isAdmin => role == 'admin';

  factory UserProfile.fromJson(String uid, Map<String, dynamic> data) {
    final metersMap = (data['meters'] as Map?)?.cast<String, dynamic>() ?? {};
    return UserProfile(
      uid: uid,
      name: (data['name'] ?? '').toString(),
      email: (data['email'] ?? '').toString(),
      role: (data['role'] ?? 'customer').toString(),
      meterIds: metersMap.keys.toList(),
    );
  }
}
