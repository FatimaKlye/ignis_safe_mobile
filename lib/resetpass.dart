import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login.dart';
import 'widgets/app_notification.dart';

String _t(BuildContext context, String en, String tl) {
  return Localizations.localeOf(context).languageCode == 'tl' ? tl : en;
}

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  static const Color brandRed = Color(0xFFB71C1C);

  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _isSaving = false;

  final SupabaseClient supabase = Supabase.instance.client;

  String _authErrorMessage(String message) {
    final isTl = Localizations.localeOf(context).languageCode == 'tl';
    if (!isTl) return message;

    final lower = message.toLowerCase();
    if (lower.contains('expired') || lower.contains('invalid')) {
      return 'Hindi wasto o paso na ang recovery link o OTP. Pakisubukang muli.';
    }
    if (lower.contains('rate') || lower.contains('too many')) {
      return 'Masyadong maraming pagsubok. Maghintay sandali bago subukang muli.';
    }
    if (lower.contains('password')) {
      return 'Hindi ma-update ang password. Pakisuri ang bagong password at subukang muli.';
    }
    return 'Hindi ma-update ang password. Pakisubukang muli.';
  }

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _goToLogin() async {
    try {
      await supabase.auth.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
    }

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;

    final currentSession = supabase.auth.currentSession;
    if (currentSession == null) {
      if (!mounted) return;
      await showAppDialog(
        context,
        message: _t(
          context,
          'Your reset session is missing or expired. Please request a new OTP.',
          'Wala o paso na ang iyong reset session. Humingi muli ng bagong OTP.',
        ),
        type: AppNotificationType.warning,
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await supabase.auth.updateUser(
        UserAttributes(password: _passwordCtrl.text.trim()),
      );

      await supabase.auth.signOut();

      if (!mounted) return;

      showAppNotification(
        context,
        message: _t(
          context,
          'Password updated successfully. Please log in again.',
          'Matagumpay na na-update ang password. Mag-login muli.',
        ),
        type: AppNotificationType.success,
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      showAppNotification(
        context,
        message: _authErrorMessage(e.message),
        type: AppNotificationType.error,
      );
    } catch (_) {
      if (!mounted) return;
      showAppNotification(
        context,
        message: _t(
          context,
          'Unable to update password.',
          'Hindi ma-update ang password.',
        ),
        type: AppNotificationType.error,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String? _validatePassword(String? value) {
    final password = value?.trim() ?? '';
    if (password.isEmpty) {
      return _t(
        context,
        'Please enter a new password.',
        'Mangyaring maglagay ng bagong password.',
      );
    }
    if (password.length < 8) {
      return _t(
        context,
        'Password must be at least 8 characters.',
        'Ang password ay dapat may hindi bababa sa 8 character.',
      );
    }
    if (!RegExp(r'\d').hasMatch(password)) {
      return _t(
        context,
        'Password must contain a number.',
        'Ang password ay dapat may numero.',
      );
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>_\-\\/\[\]=+]').hasMatch(password)) {
      return _t(
        context,
        'Password must contain a symbol.',
        'Ang password ay dapat may simbolo.',
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 35.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 70, bottom: 30),
                            child: SizedBox(
                              height: 120,
                              child: FittedBox(
                                fit: BoxFit.contain,
                                child: Image.asset('assets/logo.png'),
                              ),
                            ),
                          ),
                          Text(
                            _t(
                              context,
                              'Reset Password',
                              'I-reset ang Password',
                            ),
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 2,
                            width: 150,
                            decoration: BoxDecoration(
                              color: brandRed,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _t(
                              context,
                              'Create a new password for your account.',
                              'Gumawa ng bagong password para sa iyong account.',
                            ),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              color: Colors.black54,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 32),
                          TextFormField(
                            controller: _passwordCtrl,
                            obscureText: !_showPassword,
                            decoration: InputDecoration(
                              labelText: _t(
                                context,
                                'New Password',
                                'Bagong Password',
                              ),
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _showPassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(
                                    () => _showPassword = !_showPassword,
                                  );
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            validator: _validatePassword,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _confirmPasswordCtrl,
                            obscureText: !_showConfirmPassword,
                            decoration: InputDecoration(
                              labelText: _t(
                                context,
                                'Confirm Password',
                                'Kumpirmahin ang Password',
                              ),
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _showConfirmPassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _showConfirmPassword =
                                        !_showConfirmPassword;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            validator: (value) {
                              if ((value ?? '').trim().isEmpty) {
                                return _t(
                                  context,
                                  'Please confirm your password.',
                                  'Mangyaring kumpirmahin ang iyong password.',
                                );
                              }
                              if (value!.trim() != _passwordCtrl.text.trim()) {
                                return _t(
                                  context,
                                  'Passwords do not match.',
                                  'Hindi magkatugma ang mga password.',
                                );
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 22),
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _updatePassword,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: brandRed,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      _t(
                                        context,
                                        'Update Password',
                                        'I-update ang Password',
                                      ),
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: _goToLogin,
                            child: Text(
                              _t(context, 'Back to Login', 'Bumalik sa Login'),
                            ),
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
