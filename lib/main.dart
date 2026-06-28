import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'routes/app_routes.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.dashboard,
      defaultTransition: Transition.fadeIn,
      getPages: AppRoutes.pages,
      unknownRoute: GetPage(
        name: '/not-found',
        page: () => const _NotFoundView(),
        transition: Transition.fadeIn,
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
