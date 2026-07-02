import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'routes/app_routes.dart';
import 'themes/app_theme.dart';
import 'controllers/theme_controller.dart';
import 'services/route_observer.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Get.put(ThemeController());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeCtrl = Get.find<ThemeController>();
    return Obx(
      () => GetMaterialApp(
        debugShowCheckedModeBanner: false,
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
