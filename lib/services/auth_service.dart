import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

/// Firebase Authentication ke REST API se login karta hai (koi firebase_auth
/// package ya native setup nahi chahiye — humare baaki services ki tarah
/// simple HTTP requests hi use ho rahi hain).
class AuthService {
  // Firebase Project Settings > General > Web API Key se mila hua
  static const String _apiKey = 'AIzaSyBPYzRRdPnMBtVv_3wBbbAlTEDfHKesu-k';
  static const String _authUrl =
      'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$_apiKey';
  static const String _refreshUrl =
      'https://securetoken.googleapis.com/v1/token?key=$_apiKey';
  static const String _refreshTokenKey = 'firebase_refresh_token';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String _dbUrl =
      'https://finalyearproject-2034b-default-rtdb.asia-southeast1.firebasedatabase.app';

  /// Email/password se login karta hai. Kamyaab hone par user ka UID wapas
  /// karta hai. Fail hone par Exception throw karta hai (message user ko
  /// dikhaya ja sakta hai).
  Future<AuthSession> signIn(String email, String password) async {
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
      return AuthSession(
        uid: data['localId']?.toString() ?? '',
        email: data['email']?.toString() ?? email,
        refreshToken: data['refreshToken']?.toString() ?? '',
      );
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

  Future<void> saveSession(AuthSession session) async {
    await _storage.write(key: _refreshTokenKey, value: session.refreshToken);
  }

  Future<AuthSession?> restoreSession() async {
    try {
      final refreshToken = await _storage
          .read(key: _refreshTokenKey)
          .timeout(const Duration(seconds: 3));
      if (refreshToken == null || refreshToken.isEmpty) return null;

      final response = await http
          .post(
            Uri.parse(_refreshUrl),
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: {
              'grant_type': 'refresh_token',
              'refresh_token': refreshToken,
            },
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        final session = AuthSession(
          uid: data['user_id']?.toString() ?? '',
          email: data['email']?.toString() ?? '',
          refreshToken: data['refresh_token']?.toString() ?? '',
        );
        if (session.uid.isEmpty || session.refreshToken.isEmpty) {
          await clearSession();
          return null;
        }
        await saveSession(session);
        return session;
      }

      final errorCode = data['error']?['message']?.toString() ?? '';
      if (errorCode.contains('INVALID_GRANT') ||
          errorCode.contains('USER_DISABLED')) {
        await clearSession();
      }
    } catch (e) {
      // Keep the saved token when the failure may only be a network issue.
    }
    return null;
  }

  Future<void> clearSession() => _storage.delete(key: _refreshTokenKey);

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

class AuthSession {
  final String uid;
  final String email;
  final String refreshToken;

  const AuthSession({
    required this.uid,
    required this.email,
    required this.refreshToken,
  });
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
