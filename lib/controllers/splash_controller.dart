import 'package:get/get.dart';
import '../routes/app_routes.dart';
import '../services/auth_service.dart';

class SplashController extends GetxController {
  // ── Navigation ─────────────────────────────────────────────────────────────
  // Total splash duration before navigating to login.
  // Adjust to match your animation length (loader fills at ~3.4s total).
  static const _splashDuration = Duration(milliseconds: 3600);
  final AuthService _authService = AuthService();

  @override
  void onInit() {
    super.onInit();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final minimumSplashDuration = Future<void>.delayed(_splashDuration);
    var destination = AppRoutes.login;
    Map<String, dynamic>? arguments;

    try {
      final session = await _authService.restoreSession();
      if (session != null) {
        final profile = await _authService.fetchUserProfile(session.uid);
        if (profile != null) {
          if (profile.isAdmin) {
            destination = AppRoutes.adminPanel;
          } else {
            final userName = profile.name.trim().isNotEmpty
                ? profile.name.trim()
                : session.email.split('@').first;
            final userEmail = profile.email.trim().isNotEmpty
                ? profile.email.trim()
                : session.email;
            arguments = {
              'meterIds': profile.meterIds,
              'userName': userName,
              'userEmail': userEmail,
            };

            if (profile.meterIds.length == 1) {
              destination = AppRoutes.dashboard;
              arguments = {
                ...arguments,
                'meterId': profile.meterIds.first,
                'meterName': '',
              };
            } else {
              destination = AppRoutes.metersList;
            }
          }
        }
      }
    } catch (_) {
      // Use the login route if session restoration fails.
    }

    await minimumSplashDuration;
    Get.offAllNamed(destination, arguments: arguments);
  }
}
