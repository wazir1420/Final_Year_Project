import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';

import 'routes/app_routes.dart';
import 'themes/app_theme.dart';
import 'controllers/theme_controller.dart';
import 'controllers/language_controller.dart';
import 'translations/app_translations.dart';
import 'services/route_observer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Get.put(ThemeController());

  final languageCtrl = Get.put(LanguageController());
  await languageCtrl.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeCtrl = Get.find<ThemeController>();
    final languageCtrl = Get.find<LanguageController>();
    return Obx(
      () => GetMaterialApp(
        debugShowCheckedModeBanner: false,
        translations: AppTranslations(),
        locale: languageCtrl.locale.value,
        fallbackLocale: LanguageController.english,
        supportedLocales: const [
          LanguageController.english,
          LanguageController.urdu,
        ],
        // Urdu ke liye right-to-left layout in delegates se aata hai.
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeCtrl.isDarkRx.value ? ThemeMode.dark : ThemeMode.light,
        navigatorObservers: [routeObserver],
        initialRoute: AppRoutes.splash,
        defaultTransition: Transition.fadeIn,
        getPages: AppRoutes.pages,
        unknownRoute: GetPage(
          name: '/not-found',
          page: () => const _NotFoundView(),
          transition: Transition.fadeIn,
        ),
      ),
    );
  }
}

class _NotFoundView extends StatelessWidget {
  const _NotFoundView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page not found')),
      body: const Center(
        child: Text('Route not found. Please return to the dashboard.'),
      ),
    );
  }
}
