import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:memoriz_bible/welcome_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // indispensable
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFFCE4EC), // fond doux rose pâle
        primaryColor: const Color(0xFFE91E63), // rose vif pour éléments principaux
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE91E63),
          secondary: const Color(0xFFF8BBD0), // rose clair
          brightness: Brightness.light,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFF333333)), // texte foncé
          titleLarge: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: Color(0xFFE91E63), // titre en rose
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFFE91E63),
          elevation: 0,
          centerTitle: true
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor:  Colors.green, // bouton principal rose
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor:  Colors.green,
            side: const BorderSide(color: Color(0xFFE91E63)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),

      debugShowCheckedModeBanner: false,
      home: const  WelcomePage(),
    );
  }
}
