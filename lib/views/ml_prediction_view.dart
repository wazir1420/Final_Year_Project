import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MlPredictionView extends StatelessWidget {
  const MlPredictionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('ml_title'.tr)),
      body: Center(child: Text('ml_coming_soon'.tr)),
    );
  }
}
