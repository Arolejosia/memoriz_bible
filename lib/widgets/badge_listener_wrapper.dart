// File: lib/widgets/badge_listener_wrapper.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:memoriz_bible/badges/providers/badge_provider.dart';
import 'package:memoriz_bible/models/badge_model.dart';
import 'package:memoriz_bible/widgets/badge_unlock_dialog.dart';

/// Wrapper à placer autour du contenu principal de l'app (ex: dans WelcomePage
/// ou juste au-dessus de la navigation) pour activer le tracking d'engagement
/// et afficher les popups de badges débloqués.
/// Wrapper to place around the app's main content to enable engagement
/// tracking and show badge unlock popups.
class BadgeListenerWrapper extends StatefulWidget {
  final Widget child;
  const BadgeListenerWrapper({super.key, required this.child});

  @override
  State<BadgeListenerWrapper> createState() => _BadgeListenerWrapperState();
}

class _BadgeListenerWrapperState extends State<BadgeListenerWrapper> {
  StreamSubscription<BadgeModel>? _unlockSub;
  BadgeProvider? _boundProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<BadgeProvider?>();

    // Si le provider a changé (ex: login/logout), on réabonne proprement
    if (provider != _boundProvider) {
      _unlockSub?.cancel();
      _boundProvider = provider;

      if (provider != null) {
        provider.startSession();
        _unlockSub = provider.onBadgeUnlocked.listen((badge) {
          final ctx = context;
          if (mounted) {
            BadgeUnlockDialog.show(ctx, badge);
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _unlockSub?.cancel();
    _boundProvider?.pauseSession();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // On réagit aussi aux changements de provider (ex: connexion utilisateur)
    // pour s'assurer que startSession() est bien appelé après un login.
    context.watch<BadgeProvider?>();
    return widget.child;
  }
}