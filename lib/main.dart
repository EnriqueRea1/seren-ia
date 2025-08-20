import 'package:flutter/material.dart';
import 'Pages/login.dart';
import 'Pages/signup.dart';
import 'Pages/result_page.dart';
import 'Pages/bai.dart';
import 'Pages/bdi.dart';
import 'Pages/pss.dart';
import 'Pages/questionnaire_page.dart';
import 'Pages/recomendaciones.dart';
import 'Pages/profile.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SerenIA',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        cardColor: Colors.grey[900],
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          bodyMedium: TextStyle(fontSize: 16, color: Colors.white70),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: Colors.white),
        ),
      ),
      initialRoute: 'login',
      routes: {
        'login': (context) => const LoginPage(),
        'signup': (context) => const SignUpPage(),
        'bai': (context) => const BaiPageView(),
        'bdi': (context) => const BdiPageView(),
        'pss': (context) => const PssPageView(),
        'result': (context) => ResultPage(
              total: 0,
              level: 0, 
              carrera: '',
              cuestionario: '', // Placeholder values
            ),
        'questionnaire': (context) => const QuestionnairePage(),
        'recomendaciones': (context) => const RecomendacionesPage(),
        'profile': (context) => const ProfilePage(),

      },
    );
  }
}