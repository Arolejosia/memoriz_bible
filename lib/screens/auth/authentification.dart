// File: lib/auth/authentification.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:provider/provider.dart';
import '../../models/language_provider.dart';
import '../core/home_page.dart';


/// Translations for authentication page
/// Traductions pour la page d'authentification
class AuthTranslations {
  static String t(String key, String lang) {
    final translations = {
      'login': {'fr': 'Connexion', 'en': 'Login'},
      'signup': {'fr': 'Inscription', 'en': 'Sign Up'},
      'full_name': {'fr': 'Nom complet', 'en': 'Full Name'},
      'phone_number': {'fr': 'Numéro de téléphone', 'en': 'Phone Number'},
      'invalid_number': {'fr': 'Numéro invalide', 'en': 'Invalid number'},
      'birth_date': {'fr': 'Date de naissance', 'en': 'Birth Date'},
      'email': {'fr': 'Email', 'en': 'Email'},
      'password': {'fr': 'Mot de passe', 'en': 'Password'},
      'sign_in': {'fr': 'Se connecter', 'en': 'Sign In'},
      'register': {'fr': 'S\'inscrire', 'en': 'Register'},
      'forgot_password': {'fr': 'Mot de passe oublié ?', 'en': 'Forgot password?'},
      'no_account': {'fr': 'Pas encore de compte ? S\'inscrire', 'en': 'No account yet? Sign up'},
      'have_account': {'fr': 'Déjà un compte ? Se connecter', 'en': 'Already have an account? Sign in'},
      'fill_all_fields': {'fr': 'Veuillez remplir tous les champs obligatoires.', 'en': 'Please fill in all required fields.'},
      'signup_success': {'fr': 'Inscription réussie ! Vérifiez votre boîte de réception (et vos spams).', 'en': 'Registration successful! Check your inbox (and spam folder).'},
      'user_not_found': {'fr': 'Aucun utilisateur trouvé pour cet email.', 'en': 'No user found for this email.'},
      'wrong_password': {'fr': 'Mot de passe incorrect.', 'en': 'Incorrect password.'},
      'weak_password': {'fr': 'Le mot de passe doit contenir au moins 6 caractères.', 'en': 'Password must be at least 6 characters.'},
      'email_in_use': {'fr': 'Un compte existe déjà pour cet email.', 'en': 'An account already exists for this email.'},
      'invalid_email': {'fr': 'L\'adresse email n\'est pas valide.', 'en': 'The email address is not valid.'},
      'error_occurred': {'fr': 'Une erreur est survenue. Veuillez réessayer.', 'en': 'An error occurred. Please try again.'},
      'enter_email_reset': {'fr': 'Veuillez entrer votre adresse e-mail pour réinitialiser le mot de passe.', 'en': 'Please enter your email address to reset your password.'},
      'reset_email_sent': {'fr': 'Un e-mail de réinitialisation a été envoyé. Vérifiez votre boîte de réception (ou vos spams).', 'en': 'A password reset email has been sent. Check your inbox (or spam folder).'},
    };
    return translations[key]?[lang] ?? key;
  }
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  // Controllers / Contrôleurs
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  String _fullPhoneNumber = '';
  DateTime? _birthDate;

  // Interface states / États de l'interface
  bool _isLogin = true;
  String _errorMessage = '';
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (FirebaseAuth.instance.currentUser != null) {
        print("User already logged in, redirecting to HomePage.");
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
                (route) => false,
          );
        }
      }
    });
  }

  String t(String key) {
    final lang = context.read<LanguageProvider>().language;
    return AuthTranslations.t(key, lang);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(2000),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _birthDate) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  Future<void> _authenticate() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      if (_isLogin) {
        // --- LOGIN / CONNEXION ---
        if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
          throw FormatException(t('fill_all_fields'));
        }

        UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // ✅ Vérifier si l'email est vérifié
        if (userCredential.user != null && !userCredential.user!.emailVerified) {
          // ⚠️ IMPORTANT : Déconnecter l'utilisateur
          await FirebaseAuth.instance.signOut();

          if (mounted) {
            final lang = context.read<LanguageProvider>().language;
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                icon: const Icon(Icons.mark_email_unread, color: Colors.orange, size: 50),
                title: Text(
                  lang == 'fr' ? '⚠️ Email non vérifié' : '⚠️ Email not verified',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      lang == 'fr'
                          ? 'Vous devez vérifier votre email avant de vous connecter.'
                          : 'You must verify your email before logging in.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.email, color: Colors.orange, size: 24),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              lang == 'fr'
                                  ? 'Vérifiez votre boîte de réception et vos SPAMS.'
                                  : 'Check your inbox and SPAM folder.',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.orange,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      lang == 'fr'
                          ? '💡 Astuce : Vous pouvez renvoyer l\'email en vous reconnectant.'
                          : '💡 Tip: You can resend the email by logging in again.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
                actions: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      minimumSize: const Size(double.infinity, 45),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      lang == 'fr' ? 'OK, compris' : 'OK, got it',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            );
          }

          // ✅ Ne pas continuer la connexion
          return;
        }
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
                (route) => false,
          );
        }
      }else {
        // --- SIGNUP / INSCRIPTION ---
        if (_fullNameController.text.isEmpty ||
            _emailController.text.isEmpty ||
            _passwordController.text.isEmpty) {
          throw FormatException(t('fill_all_fields'));
        }

        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        final user = userCredential.user;
        if (user != null) {
          // Enregistrer les données dans Firestore
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'fullName': _fullNameController.text.trim(),
            'phone': _fullPhoneNumber.isEmpty ? null : _fullPhoneNumber,
            'birthDate': _birthDate,
            'email': _emailController.text.trim(),
            'createdAt': FieldValue.serverTimestamp(),
          });

          // Essayer d'envoyer l'email de vérification
          bool emailSent = false;
          String emailError = '';

          try {
            await user.sendEmailVerification();
            emailSent = true;
          } catch (e) {
            emailError = e.toString();
            print('❌ Erreur envoi email: $e');
          }

          // Déconnecter l'utilisateur
          await FirebaseAuth.instance.signOut();

          // Afficher le résultat
          if (mounted) {
            if (emailSent) {
              // SUCCÈS
              await showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => AlertDialog(
                  icon: const Icon(Icons.check_circle, color: Colors.green, size: 60),
                  title: const Text(
                    '✅ Inscription réussie !',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Un email de vérification a été envoyé à :',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _emailController.text.trim(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning_amber, color: Colors.orange, size: 24),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '⚠️ Vérifiez vos SPAMS !',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Cliquez sur le lien dans l\'email pour activer votre compte, puis reconnectez-vous.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                  actions: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        minimumSize: const Size(double.infinity, 45),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          _isLogin = true;
                          _fullNameController.clear();
                          _fullPhoneNumber = '';
                          _emailController.clear();
                          _passwordController.clear();
                          _birthDate = null;
                        });
                      },
                      child: const Text(
                        'OK, compris',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              );
            } else {
              // ERREUR
              await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  icon: const Icon(Icons.error_outline, color: Colors.red, size: 60),
                  title: const Text(
                    '❌ Erreur d\'envoi',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'L\'email de vérification n\'a pas pu être envoyé.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          emailError,
                          style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '💡 Votre compte a été créé. Reconnectez-vous pour renvoyer l\'email.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          _isLogin = true;
                          _emailController.clear();
                          _passwordController.clear();
                        });
                      },
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            }
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found': message = t('user_not_found'); break;
        case 'wrong-password': message = t('wrong_password'); break;
        case 'weak-password': message = t('weak_password'); break;
        case 'email-already-in-use': message = t('email_in_use'); break;
        case 'invalid-email': message = t('invalid_email'); break;
        default: message = t('error_occurred');
      }
      setState(() => _errorMessage = message);
    } on FormatException catch (e) {
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resetPassword() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t('enter_email_reset')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t('reset_email_sent')),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = t('error_occurred');
      if (e.code == 'user-not-found') {
        message = t('user_not_found');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(_isLogin ? t('login') : t('signup')),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_isLogin) ...[
                TextField(
                  controller: _fullNameController,
                  decoration: InputDecoration(
                    labelText: '${t('full_name')} *',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                IntlPhoneField(
                  decoration: InputDecoration(
                    labelText: t('phone_number'),
                    border: const OutlineInputBorder(),
                  ),
                  initialCountryCode: 'FR',
                  invalidNumberMessage: t('invalid_number'),
                  onChanged: (phone) {
                    _fullPhoneNumber = phone.completeNumber;
                  },
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    _birthDate == null
                        ? t('birth_date')
                        : "${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}",
                    style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                  ),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  onPressed: () => _selectDate(context),
                ),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: '${t('email')} *',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  labelText: '${t('password')} *',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: _isLoading ? null : _authenticate,
                child: _isLoading
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                    : Text(_isLogin ? t('sign_in') : t('register')),
              ),
              if (_isLogin)
                TextButton(
                  onPressed: _isLoading ? null : _resetPassword,
                  child: Text(t('forgot_password')),
                ),
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () {
                  setState(() {
                    _isLogin = !_isLogin;
                    _errorMessage = '';
                  });
                },
                child: Text(_isLogin ? t('no_account') : t('have_account')),
              ),
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_errorMessage, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                ),
            ],
          ),
        ),
      ),
    );
  }
}