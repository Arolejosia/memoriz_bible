import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:memoriz_bible/prayer/providers/prayer_notes_provider.dart';
import 'package:memoriz_bible/prayer/providers/prayer_timer_provider.dart';
import 'package:memoriz_bible/screens/core/welcome_page.dart';
import 'package:memoriz_bible/screens/public/privacy_page.dart';
import 'package:memoriz_bible/screens/public/support_page.dart';
import 'package:memoriz_bible/screens/public/terms_page.dart';
import 'package:memoriz_bible/services/Bible_service.dart';
import 'package:memoriz_bible/services/bible_validation_service.dart';
import 'package:memoriz_bible/services/feedback_overlay.dart';
import 'package:memoriz_bible/services/notification_service.dart';
import 'package:memoriz_bible/url_strategie_stub.dart';
import 'package:memoriz_bible/widgets/badge_listener_wrapper.dart';
import 'package:provider/provider.dart';
import 'Bibliotheque.dart';
import 'badges/providers/badge_provider.dart';
import 'firebase_options.dart';
import 'models/language_provider.dart';
import 'package:flutter/foundation.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureUrlStrategy();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  BibleService().wakeUpServer();
  if (!kIsWeb) {
    await NotificationService.instance.init();
  }

  runApp(
    MultiProvider(
      providers: [
        // Provider pour l'authentification / Provider for authentication
        StreamProvider<User?>.value(
          value: FirebaseAuth.instance.authStateChanges(),
          initialData: null,
        ),

        // LanguageProvider doit être AVANT VerseLibrary
        // LanguageProvider must be BEFORE VerseLibrary
        ChangeNotifierProvider(
          create: (_) => LanguageProvider(),
        ),

        // VerseLibrary avec support bilingue
        // VerseLibrary with bilingual support
        ChangeNotifierProxyProvider2<User?, LanguageProvider, VerseLibrary>(
          create: (context) {
            final user = context.read<User?>();
            final language = context.read<LanguageProvider>().language;
            return VerseLibrary(user?.uid, language: language);
          },
          update: (context, user, languageProvider, previousLibrary) {
            // Recrée VerseLibrary quand l'utilisateur OU la langue change
            // Recreate VerseLibrary when user OR language changes
            return VerseLibrary(user?.uid, language: languageProvider.language);
          },
        ),

        // ThemeProvider
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
        ),
        ChangeNotifierProxyProvider<User?, PrayerTimerProvider?>(
          create: (context) => null,
          update: (context, user, previous) {
            if (user?.uid != null) {
              return PrayerTimerProvider(userId: user!.uid);
            }
            return null;
          },
        ),
        ChangeNotifierProxyProvider<User?, PrayerNotesProvider?>(
          create: (context) => null,
          update: (context, user, previous) {
            if (user?.uid != null) {
              return PrayerNotesProvider(userId: user!.uid);
            }
            return null;
          },
        ),
        ChangeNotifierProxyProvider<User?, BadgeProvider?>(
          create: (context) => null,
          update: (context, user, previous) {
            if (user?.uid != null) {
              return BadgeProvider(userId: user!.uid);
            }
            return null;
          },
        ),
      ],
      child: const MyApp(),
    ),
  );
}

/// Route generator partagé entre l'écran de chargement et l'app complète.
/// Shared route generator between the loading screen and the full app.
/// [defaultBuilder] définit ce qui s'affiche pour "/" ou toute route inconnue.
Route<dynamic> _generateAppRoute(
    RouteSettings settings,
    Widget Function(BuildContext) defaultBuilder,
    ) {
  switch (settings.name) {
    case '/support':
      return MaterialPageRoute(builder: (_) => const SupportPage());
    case '/privacy':
      return MaterialPageRoute(builder: (_) => const PrivacyPage());
    case '/terms':
      return MaterialPageRoute(builder: (_) => const TermsPage());
    default:
      return MaterialPageRoute(builder: defaultBuilder);
  }
}

const Widget _loadingScreen = Scaffold(
  body: Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text('Chargement... / Loading...'),
      ],
    ),
  ),
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Un seul MaterialApp / Navigator, créé une seule fois.
    // L'attente de l'initialisation de la langue est gérée À L'INTÉRIEUR
    // du builder par défaut (via Consumer), pas en remplaçant tout le MaterialApp.
    // Ça évite de recréer le Navigator (et donc de perdre la route initiale
    // comme /support, /privacy, /terms) quand isInitialized change.
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Memoriz Bible',
          debugShowCheckedModeBanner: false,
          theme: futuristicLightTheme,
          darkTheme: futuristicDarkTheme,
          themeMode: themeProvider.themeMode,
          onGenerateRoute: (settings) => _generateAppRoute(
            settings,
                (_) => Consumer<LanguageProvider>(
              builder: (context, languageProvider, __) {
                if (!languageProvider.isInitialized) {
                  return _loadingScreen;
                }
                return const WelcomePage();
              },
            ),
          ),
        );
      },
    );
  }
}

ThemeData futuristicLightTheme = ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: const Color(0xFFF5F7FA),
  primaryColor: const Color(0xFF2962FF),
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF2962FF),
    primary: const Color(0xFF2962FF),
    secondary: const Color(0xFF00E5FF),
    tertiary: const Color(0xFF18FFFF),
    background: const Color(0xFFF5F7FA),
    brightness: Brightness.light,
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(
      color: Color(0xFF212121),
      fontSize: 16,
    ),
    titleLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.bold,
      letterSpacing: 1.2,
      color: Color(0xFF2962FF),
    ),
    headlineLarge: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w900,
      color: Color(0xFF00E5FF),
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
  scaffoldBackgroundColor: const Color(0xFF0D1117),
  primaryColor: const Color(0xFF00E5FF),
  colorScheme: ColorScheme.dark(
    primary: const Color(0xFF00E5FF),
    secondary: const Color(0xFF2962FF),
    tertiary: const Color(0xFF18FFFF),
    background: const Color(0xFF0D1117),
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(
      color: Color(0xFFEAEAEA),
      fontSize: 16,
    ),
    titleLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.bold,
      letterSpacing: 1.2,
      color: Color(0xFF00E5FF),
    ),
    headlineLarge: TextStyle(
      fontSize: 30,
      fontWeight: FontWeight.w900,
      color: Color(0xFF18FFFF),
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