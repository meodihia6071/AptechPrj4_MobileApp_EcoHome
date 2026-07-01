import 'package:flutter/material.dart';
import 'core/constants/app_colors.dart';
import 'features/auth/presentation/screens/login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EcoHome',
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.neutralBg,
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}