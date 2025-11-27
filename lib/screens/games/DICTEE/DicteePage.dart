import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/language_provider.dart';
import '../../../models/verse_model.dart';

import 'DicteeMultiplayerPage.dart';
import 'DicteeSoloPage.dart';
import 'dictee_translations.dart';

class DicteePage extends StatelessWidget {
  final Verse? verse;
  final String? roomCode;
  final bool isSandbox;
  final bool isMultiplayer;

  const DicteePage({
    Key? key,
    this.verse,
    this.roomCode,
    this.isSandbox = false,
    this.isMultiplayer = false,
  }) : super(key: key);

  const DicteePage.solo({
    Key? key,
    required Verse verse,
    bool isSandbox = false,
  }) : this(
    key: key,
    verse: verse,
    isSandbox: isSandbox,
    isMultiplayer: false,
  );

  const DicteePage.multiplayer({
    Key? key,
    required String roomCode,
  }) : this(
    key: key,
    roomCode: roomCode,
    isMultiplayer: true,
  );

  // ✅ COMME RÉCITATION : Helper avec context.read
  String t(BuildContext context, String key) {
    final lang = context.read<LanguageProvider>().language;
    return DicteeTranslations.t(key, lang);
  }

  @override
  Widget build(BuildContext context) {
    final currentLanguage = context.watch<LanguageProvider>().language;
    // Validation des paramètres
    if (isMultiplayer) {
      if (roomCode == null || roomCode!.isEmpty) {
        return _buildErrorScaffold(
          context,
          t(context, 'room_code_missing'),
        );
      }
      // ✅ COMME RÉCITATION : Ne plus passer la langue
      return DicteeMultiplayerPage(
        roomCode: roomCode!,

      );
    } else {
      if (verse == null) {
        return _buildErrorScaffold(
          context,
          t(context, 'verse_missing'),
        );
      }
      // ✅ COMME RÉCITATION : Ne plus passer la langue
      return DicteeSoloPage(
        verse: verse!,
        isSandbox: isSandbox,
          language: currentLanguage,
      );
    }
  }

  Widget _buildErrorScaffold(BuildContext context, String errorMessage) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t(context, 'error')),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                errorMessage,
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.arrow_back),
              label: Text(t(context, 'back')),
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DicteeNavigator {
  static Future<T?> pushSolo<T extends Object?>(
      BuildContext context, {
        required Verse verse,
        bool isSandbox = false,
      }) {
    return Navigator.push<T>(
      context,
      MaterialPageRoute(
        builder: (context) => DicteePage.solo(
          verse: verse,
          isSandbox: isSandbox,
        ),
      ),
    );
  }

  static Future<T?> pushMultiplayer<T extends Object?>(
      BuildContext context, {
        required String roomCode,
      }) {
    return Navigator.push<T>(
      context,
      MaterialPageRoute(
        builder: (context) => DicteePage.multiplayer(
          roomCode: roomCode,
        ),
      ),
    );
  }
}