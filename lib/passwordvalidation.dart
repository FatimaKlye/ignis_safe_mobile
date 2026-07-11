import 'package:flutter/material.dart';
import 'login.dart';
import 'signup.dart';

String _t(BuildContext context, String en, String tl) {
  return Localizations.localeOf(context).languageCode == 'tl' ? tl : en;
}

/// Compatibility page only.
///
/// The password setup step is now merged into RegisterPage. This file remains
/// so older imports/routes do not break, but it no longer creates or updates a
/// Supabase account on its own.
class CreatePasswordPage extends StatelessWidget {
  final String email;
  final String firstName;
  final String lastName;

  const CreatePasswordPage({
    super.key,
    required this.email,
    required this.firstName,
    required this.lastName,
  });

  static const Color brandRed = Color(0xFFB71C1C);

  @override
  Widget build(BuildContext context) {
    final displayEmail = email.trim().toLowerCase();

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 35.0),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: 120,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: Image.asset('assets/logo.png'),
                  ),
                ),
                const SizedBox(height: 26),
                Container(
                  height: 72,
                  width: 72,
                  decoration: BoxDecoration(
                    color: brandRed.withOpacity(0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.password_rounded,
                    color: brandRed,
                    size: 38,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _t(
                    context,
                    'Password Step Moved',
                    'Nalipat na ang Password Step',
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 2,
                  width: 120,
                  decoration: BoxDecoration(
                    color: brandRed,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  displayEmail.isEmpty
                      ? _t(
                          context,
                          'Password validation is now completed directly on the Sign Up page before email verification.',
                          'Ginagawa na ngayon ang password validation sa Sign Up page bago ang email verification.',
                        )
                      : _t(
                          context,
                          'Password validation is now completed directly on the Sign Up page before email verification for $displayEmail.',
                          'Ginagawa na ngayon ang password validation sa Sign Up page bago ang email verification para sa $displayEmail.',
                        ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black.withOpacity(0.60),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 26),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterPage()),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandRed,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      _t(context, 'Back to Sign Up', 'Bumalik sa Sign Up'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextButton(
                  onPressed: () {
                    LoginPage.skipAutoRoute = false;
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                      (route) => false,
                    );
                  },
                  child: Text(
                    _t(context, 'Go to Login', 'Pumunta sa Login'),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      color: brandRed,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
