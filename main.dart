import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/onboarding_screen.dart';
import 'screens/scanner_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final bool isEnrolled = prefs.getBool('is_enrolled') ?? false;

  runApp(AttendanceApp(isEnrolled: isEnrolled));
}

class AttendanceApp extends StatelessWidget {
  final bool isEnrolled;
  const AttendanceApp({super.key, required this.isEnrolled});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'University Attendance',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.blueAccent,
        useMaterial3: true,
      ),
      // If already enrolled, lock permanently into ScannerScreen
      home: isEnrolled ? const ScannerScreen() : const OnboardingScreen(),
    );
  }
}
