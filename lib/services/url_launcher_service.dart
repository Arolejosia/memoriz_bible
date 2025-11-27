// Fichier: lib/services/url_launcher_service.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class UrlLauncherService {
  /// Lance une URL (email, web, etc.)
  static Future<void> launchUri(BuildContext context, Uri uri) async {
    try {
      final canLaunch = await canLaunchUrl(uri);

      if (canLaunch) {
        await launchUrl(uri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Impossible d\'ouvrir: ${uri.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'ouverture du lien: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Lance directement un email au support
  static Future<void> contactSupport(BuildContext context, {
    String? subject,
    String? body,
  }) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'aroletella@gmail.com',
      queryParameters: {
        if (subject != null) 'subject': subject,
        if (body != null) 'body': body,
      },
    );

    await launchUri(context, emailUri);
  }
}