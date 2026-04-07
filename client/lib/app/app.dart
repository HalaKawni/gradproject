import 'package:client/app/navigation/app_router.dart';
import 'package:client/app/navigation/app_routes.dart';
import 'package:flutter/material.dart';

class LearnyApp extends StatelessWidget {
  const LearnyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.login,
      onGenerateRoute: AppRouter.onGenerateRoute,
      onUnknownRoute: AppRouter.onUnknownRoute,
    );
  }
}
