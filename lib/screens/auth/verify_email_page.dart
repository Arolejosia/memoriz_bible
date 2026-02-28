// File: lib/auth/verify_email_page.dart
// VERSION AMÉLIORÉE avec protection anti-spam

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/language_provider.dart';
import '../core/home_page.dart';


/// Translations for email verification page
/// Traductions pour la page de vérification d'email
class VerifyEmailTranslations {
  static String t(String key, String lang) {
    final translations = {
      'verify_email': {'fr': 'Vérifiez votre email', 'en': 'Verify your email'},
      'verification_sent': {
        'fr': 'Un email de vérification a été envoyé à :',
        'en': 'A verification email has been sent to:'
      },
      'click_link': {
        'fr': 'Veuillez cliquer sur le lien dans l\'email pour activer votre compte.',
        'en': 'Please click the link in the email to activate your account.'
      },
      'resend_email': {'fr': 'Renvoyer l\'email', 'en': 'Resend email'},
      'resend_in': {'fr': 'Renvoyer dans', 'en': 'Resend in'},
      'seconds': {'fr': 's', 'en': 's'},
      'email_sent': {'fr': 'Email envoyé !', 'en': 'Email sent!'},
      'cancel': {'fr': 'Se déconnecter', 'en': 'Sign out'},
      'email_resent': {
        'fr': '✅ Email renvoyé avec succès !\n📧 Vérifiez vos spams.',
        'en': '✅ Email resent successfully!\n📧 Check your spam folder.'
      },
      'check_spam_warning': {
        'fr': '⚠️ Vérifiez aussi vos SPAMS',
        'en': '⚠️ Also check your SPAM folder'
      },
      'auto_checking': {
        'fr': 'Vérification automatique...',
        'en': 'Auto-checking...'
      },
      'spam_title': {
        'fr': 'Email dans les spams ?',
        'en': 'Email in spam?'
      },
      'spam_step1': {
        'fr': '1. Ouvrez votre dossier Spam/Courrier indésirable',
        'en': '1. Open your Spam/Junk folder'
      },
      'spam_step2': {
        'fr': '2. Cherchez un email de "Firebase" ou "noreply"',
        'en': '2. Look for an email from "Firebase" or "noreply"'
      },
      'spam_step3': {
        'fr': '3. Marquez-le comme "Non spam"',
        'en': '3. Mark it as "Not spam"'
      },
      'spam_step4': {
        'fr': '4. Cliquez sur le lien de vérification',
        'en': '4. Click the verification link'
      },
      'gmail_tip': {
        'fr': '💡 Gmail : Vérifiez aussi "Promotions" et "Social"',
        'en': '💡 Gmail: Also check "Promotions" and "Social"'
      },
      'need_help': {
        'fr': 'Besoin d\'aide ?',
        'en': 'Need help?'
      },
      'help_title': {
        'fr': 'Besoin d\'aide ?',
        'en': 'Need help?'
      },
      'help_content': {
        'fr': 'Si vous ne recevez toujours pas l\'email après avoir vérifié vos spams :\n\n'
            '1. Vérifiez que l\'adresse email est correcte\n'
            '2. Attendez quelques minutes\n'
            '3. Réessayez de renvoyer l\'email\n'
            '4. Contactez le support si le problème persiste',
        'en': 'If you still don\'t receive the email after checking spam:\n\n'
            '1. Verify the email address is correct\n'
            '2. Wait a few minutes\n'
            '3. Try resending the email\n'
            '4. Contact support if the problem persists'
      },
      'understood': {
        'fr': 'Compris',
        'en': 'Got it'
      },
      'verified_manually': {
        'fr': 'J\'ai vérifié mon email',
        'en': 'I verified my email'
      },
      'error_resend': {
        'fr': 'Erreur lors de l\'envoi',
        'en': 'Error sending email'
      },
      'too_many_requests': {
        'fr': 'Trop de tentatives. Réessayez dans quelques minutes.',
        'en': 'Too many attempts. Try again in a few minutes.'
      },
    };
    return translations[key]?[lang] ?? key;
  }
}

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  bool isEmailVerified = false;
  bool _isResending = false;
  bool _isChecking = false;
  int _countdown = 0;
  Timer? timer;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    isEmailVerified = FirebaseAuth.instance.currentUser!.emailVerified;

    if (!isEmailVerified) {
      // Vérifier toutes les 3 secondes
      timer = Timer.periodic(
        const Duration(seconds: 3),
            (_) => checkEmailVerified(),
      );
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> checkEmailVerified() async {
    if (_isChecking) return;

    setState(() => _isChecking = true);

    try {
      await FirebaseAuth.instance.currentUser!.reload();

      setState(() {
        isEmailVerified = FirebaseAuth.instance.currentUser!.emailVerified;
        _isChecking = false;
      });

      if (isEmailVerified) {
        timer?.cancel();
        _countdownTimer?.cancel();

        // Afficher un message de succès
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(child: Text(t('email_resent'))),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Erreur vérification email: $e');
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  Future<void> _resendVerificationEmail() async {
    if (_countdown > 0 || _isResending) return;

    setState(() => _isResending = true);

    try {
      await FirebaseAuth.instance.currentUser!.sendEmailVerification();

      setState(() {
        _isResending = false;
        _countdown = 60; // Empêcher le spam pendant 60 secondes
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(t('email_resent'))),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      // Décompte
      _countdownTimer?.cancel();
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_countdown > 0) {
          setState(() => _countdown--);
        } else {
          timer.cancel();
        }
      });

    } catch (e) {
      setState(() => _isResending = false);

      if (mounted) {
        String errorMessage = t('error_resend');

        if (e.toString().contains('too-many-requests')) {
          errorMessage = t('too_many_requests');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ $errorMessage'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  String t(String key) {
    final lang = context.watch<LanguageProvider>().language;
    return VerifyEmailTranslations.t(key, lang);
  }

  Widget _buildSpamInstruction(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.arrow_right, size: 20, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('help_title')),
        content: Text(t('help_content')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('understood')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return isEmailVerified
        ? const HomePage()
        : Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(t('verify_email')),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
            tooltip: t('cancel'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),

              // Icône animée
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 800),
                builder: (context, double value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.mark_email_unread,
                        size: 80,
                        color: Colors.blue,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),

              // Titre
              Text(
                t('verify_email'),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Conteneur email
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      t('verification_sent'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 15),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.email, size: 18, color: Colors.blue),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              FirebaseAuth.instance.currentUser!.email ?? '',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      t('click_link'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Boutons d'action
              ElevatedButton(
                onPressed: _countdown > 0 ? null : _resendVerificationEmail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: _countdown > 0 ? 0 : 2,
                ),
                child: _isResending
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.refresh),
                    const SizedBox(width: 8),
                    Text(
                      _countdown > 0
                          ? '${t('resend_in')} ${_countdown}${t('seconds')}'
                          : t('resend_email'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Bouton vérifier manuellement
              OutlinedButton(
                onPressed: checkEmailVerified,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: const BorderSide(color: Colors.blue),
                ),
                child: _isChecking
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : Text(
                  t('verified_manually'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Indicateur de vérification automatique
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      t('auto_checking'),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Section SPAM détaillée
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: Colors.orange[700], size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            t('spam_title'),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildSpamInstruction(t('spam_step1')),
                    _buildSpamInstruction(t('spam_step2')),
                    _buildSpamInstruction(t('spam_step3')),
                    _buildSpamInstruction(t('spam_step4')),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.lightbulb_outline,
                              color: Colors.blue[700], size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              t('gmail_tip'),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Bouton aide
              Center(
                child: TextButton(
                  onPressed: _showHelpDialog,
                  child: Text(
                    t('need_help'),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}