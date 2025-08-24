import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:memoriz_bible/screens/core/welcome_page.dart';
import 'package:memoriz_bible/services/feedback_overlay.dart';
import 'package:memoriz_bible/services/notification_service.dart';

import 'package:provider/provider.dart';
import 'Bibliotheque.dart';




void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // indispensable
  await NotificationService.instance.init();


  runApp(
    // Utilisez MultiProvider pour gérer l'utilisateur et la bibliothèque
    MultiProvider(
      providers: [
        // Ce provider fournit l'état de connexion (User ou null)
        StreamProvider<User?>.value(
          value: FirebaseAuth.instance.authStateChanges(),
          initialData: null,
        ),
        // Ce provider REÇOIT l'utilisateur et CRÉE la VerseLibrary avec le bon ID
        ChangeNotifierProxyProvider<User?, VerseLibrary>(
          create: (_) => VerseLibrary(null), // Création initiale avec un utilisateur nul
          update: (_, user, previousLibrary) => VerseLibrary(user?.uid),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Memoriz Bible',
            debugShowCheckedModeBanner: false,
            theme: futuristicLightTheme,
            darkTheme: futuristicDarkTheme,
            themeMode: themeProvider.themeMode, // system prioritaire
            home:  WelcomePage(),
          );
        },
      ),
    );



  }



}
 ThemeData futuristicLightTheme = ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: const Color(0xFFF5F7FA), // gris très clair futuriste
  primaryColor: const Color(0xFF2962FF), // bleu techno principal
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF2962FF),
    primary: const Color(0xFF2962FF),  // bleu royal
    secondary: const Color(0xFF00E5FF), // bleu néon
    tertiary: const Color(0xFF18FFFF),  // cyan lumineux
    background: const Color(0xFFF5F7FA),
    brightness: Brightness.light,
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(
      color: Color(0xFF212121), // texte noir/gris foncé
      fontSize: 16,
    ),
    titleLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.bold,
      letterSpacing: 1.2,
      color: Color(0xFF2962FF), // titres bleus
    ),
    headlineLarge: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w900,
      color: Color(0xFF00E5FF), // effet néon
      shadows: [
        Shadow(color: Color(0xFF2962FF), blurRadius: 12),
      ],
    ),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: Color(0xFF2962FF),
    elevation: 0,
    centerTitle: true,
    titleTextStyle: TextStyle(
      fontSize: 30,
      fontWeight: FontWeight.bold,
      color: Color(0xFF2962FF),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF2962FF),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.1,
      ),
      elevation: 6,
      shadowColor: Color(0xFF00E5FF),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFF2962FF),
      side: const BorderSide(color: Color(0xFF2962FF), width: 1.6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      textStyle: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
  cardTheme: CardThemeData(
    color: Colors.white,
    elevation: 6,
    shadowColor: const Color(0xFF2962FF).withOpacity(0.2),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
    ),
    margin: const EdgeInsets.all(12),
  ),
  chipTheme: ChipThemeData(
    backgroundColor: const Color(0xFFE3F2FD),
    selectedColor: const Color(0xFF2962FF),
    disabledColor: Colors.grey.shade300,
    labelStyle: const TextStyle(
      color: Color(0xFF212121),
      fontWeight: FontWeight.bold,
    ),
    secondaryLabelStyle: const TextStyle(
      color: Colors.white,
    ),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  dividerTheme: const DividerThemeData(
    color: Color(0xFFB0BEC5),
    thickness: 1,
    space: 16,
  ),
);
ThemeData futuristicDarkTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF0D1117), // gris-noir profond
  primaryColor: const Color(0xFF00E5FF), // bleu néon
  colorScheme: ColorScheme.dark(
    primary: const Color(0xFF00E5FF),
    secondary: const Color(0xFF2962FF),
    tertiary: const Color(0xFF18FFFF),
    background: const Color(0xFF0D1117),
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(
      color: Color(0xFFEAEAEA), // texte gris clair
      fontSize: 16,
    ),
    titleLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.bold,
      letterSpacing: 1.2,
      color: Color(0xFF00E5FF), // bleu néon pour les titres
    ),
    headlineLarge: TextStyle(
      fontSize: 30,
      fontWeight: FontWeight.w900,
      color: Color(0xFF18FFFF), // cyan lumineux
      shadows: [
        Shadow(color: Color(0xFF00E5FF), blurRadius: 18),
      ],
    ),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF161B22),
    foregroundColor: Color(0xFF00E5FF),
    elevation: 2,
    centerTitle: true,
    titleTextStyle: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Color(0xFF00E5FF),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF00E5FF),
      foregroundColor: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.1,
      ),
      elevation: 8,
      shadowColor: Color(0xFF18FFFF),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFF00E5FF),
      side: const BorderSide(color: Color(0xFF00E5FF), width: 1.6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      textStyle: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
  cardTheme: CardThemeData(
    color: const Color(0xFF161B22),
    elevation: 6,
    shadowColor: const Color(0xFF00E5FF).withOpacity(0.3),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
    ),
    margin: const EdgeInsets.all(12),
  ),
  chipTheme: ChipThemeData(
    backgroundColor: const Color(0xFF21262D),
    selectedColor: const Color(0xFF00E5FF),
    disabledColor: Colors.grey.shade700,
    labelStyle: const TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
    ),
    secondaryLabelStyle: const TextStyle(color: Colors.black),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  dividerTheme: const DividerThemeData(
    color: Color(0xFF2D333B),
    thickness: 1,
    space: 16,
  ),
);


