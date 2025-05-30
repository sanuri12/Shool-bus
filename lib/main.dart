import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:school_bus_app_fresh/splash_screen.dart';
import 'package:school_bus_app_fresh/login_screen.dart';
import 'package:school_bus_app_fresh/bus_driver_home.dart';
import 'package:school_bus_app_fresh/home_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const DriverHomePage(),
        '/parentHome': (context) => const HomeScreen(),
      },
    );
  }
}