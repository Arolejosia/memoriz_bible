import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:provider/provider.dart';
import '../auth/auth_gate.dart';
import 'intro_page.dart';
import '../../models/language_provider.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late AnimationController _backgroundController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _backgroundAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _backgroundController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _backgroundAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.linear),
    );

    _fadeController.forward();
    _pulseController.repeat(reverse: true);
    _backgroundController.repeat();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.of(context).size;

    // 🔤 Récupération de la langue
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isEnglish = languageProvider.language == 'en';

    // Textes bilingues
    final verseText = isEnglish
        ? 'Your word is a lamp to my feet and a light to my path.\nPsalm 119:105'
        : 'Ta parole est une lampe à mes pieds, une lumière sur mon sentier.\nPsaume 119:105';

    final startText = isEnglish ? "Let's Go!" : "Commençons !";
    final signInText = isEnglish ? "I ALREADY HAVE AN ACCOUNT" : "J'AI DÉJÀ UN COMPTE";

    return Scaffold(

      body: Stack(
        children: [
          // --- FOND ANIMÉ ---
          AnimatedBuilder(
            animation: _backgroundAnimation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(
                        theme.scaffoldBackgroundColor,
                        colorScheme.surface,
                        _backgroundAnimation.value,
                      )!,
                      Color.lerp(
                        colorScheme.surface,
                        colorScheme.primary.withOpacity(0.1),
                        _backgroundAnimation.value,
                      )!,
                      Color.lerp(
                        colorScheme.primary.withOpacity(0.05),
                        colorScheme.tertiary.withOpacity(0.1),
                        _backgroundAnimation.value,
                      )!,
                    ],
                  ),
                ),
              );
            },
          ),

          // --- PARTICULES FLOTTANTES ---
          ...List.generate(
            20,
                (index) => AnimatedBuilder(
              animation: _backgroundAnimation,
              builder: (context, child) {
                return Positioned(
                  left: (size.width * (index * 0.1 + 0.1) +
                      50 *
                          math.sin(_backgroundAnimation.value * 2 * math.pi + index)) %
                      size.width,
                  top: (size.height * (index * 0.05) +
                      30 *
                          math.cos(_backgroundAnimation.value * 2 * math.pi + index)) %
                      size.height,
                  child: Container(
                    width: 2 + (index % 3),
                    height: 2 + (index % 3),
                    decoration: BoxDecoration(
                      color: colorScheme.onSurface
                          .withOpacity(0.1 + (index % 3) * 0.1),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // --- CONTENU ---
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),

                  // --- LOGO ---
                  GestureDetector(
                    onLongPress: () {
                      Navigator.of(context).pushNamed('/admin/generate');
                    },
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  Colors.white.withOpacity(0.3),
                                  Colors.blue.shade100.withOpacity(0.2),
                                  Colors.transparent,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.5),
                                  blurRadius: 40,
                                  spreadRadius: 15,
                                ),
                              ],
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.blueAccent.withOpacity(0.7),
                                  width: 4,
                                ),
                              ),
                              child: Image.asset(
                                'assets/logo.png',
                                height: 200,
                                color: Colors.pinkAccent.withOpacity(0.95),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 40),

                  // --- VERSET ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: Colors.white.withOpacity(0.85),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.9),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.shade200.withOpacity(0.4),
                            blurRadius: 25,
                            spreadRadius: 5,
                          ),
                          BoxShadow(
                            color: Colors.white.withOpacity(0.6),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Text(
                        verseText,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: const Color(0xFF2C5AA0),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 1.6,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // --- BOUTON PRINCIPAL ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          gradient: LinearGradient(
                            colors: [
                              colorScheme.primary,
                              colorScheme.secondary,
                              colorScheme.tertiary,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withOpacity(0.4),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>  MemorizationIntroPage(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child: Text(
                            startText,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: colorScheme.onPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // --- BOUTON SECONDAIRE ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: colorScheme.primary.withOpacity(0.5),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withOpacity(0.1),
                              blurRadius: 15,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: BackdropFilter(
                            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => const AuthGate()),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                backgroundColor:
                                colorScheme.onSurface.withOpacity(0.1),
                                side: BorderSide.none,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                              ),
                              child: Text(
                                signInText,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: colorScheme.onSurface,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const Spacer(),
                ],
              ),
            ),
          ),

          // --- BOUTON DE LANGUE ---
          Positioned(
            top: 40,
            right: 16,
            child: SafeArea(
              child: IconButton(
                icon: Text(languageProvider.flagEmoji, style: const TextStyle(fontSize: 22)),
                tooltip: isEnglish ? "Change language" : "Changer de langue",
                onPressed: () => languageProvider.toggleLanguage(),
              ),
            ),
          ),

        ],
      ),
    );
  }
}
