import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'signup.dart';
import 'home.dart';
import 'terms.dart';
import 'forgotpass.dart';
import 'localization/app_text.dart';
import 'localization/language_controller.dart';
import 'network_error_helper.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  static bool skipAutoRoute = false;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const Color brandRed = Color(0xFFB71C1C);

  final SupabaseClient supabase = Supabase.instance.client;

  final _formKey = GlobalKey<FormState>();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  bool _isLoading = false;
  bool _showPassword = false;

  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    _listenAuthChanges();
  }

  void _listenAuthChanges() {
    _authSub = supabase.auth.onAuthStateChange.listen((data) {
      if (!mounted) return;
      if (LoginPage.skipAutoRoute) return;

      final event = data.event;
      final session = data.session;
      debugPrint('Auth event: $event, session exists: ${session != null}');
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  void _goNext() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const IgnisHomePage()),
      (route) => false,
    );
  }

  bool _isValidEmail(String s) {
    final v = s.trim();
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v);
  }

  String? _validateEmail(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return context.tr('email_required');
    if (!_isValidEmail(value)) return context.tr('email_invalid');
    return null;
  }

  String? _validatePassword(String? v) {
    final value = v ?? '';
    if (value.isEmpty) return context.tr('password_required');
    if (value.length < 8) return context.tr('password_min_8');
    return null;
  }

  Future<void> _ensureProfile(User user) async {
    final email = (user.email ?? '').trim().toLowerCase();
    final languageCode = context.read<LanguageController>().locale.languageCode;

    try {
      await supabase.from('profiles').upsert({
        'id': user.id,
        'email': email.isEmpty ? null : email,
        'first_name': user.userMetadata?['first_name'],
        'last_name': user.userMetadata?['last_name'],
        'app_language_code': languageCode == 'tl' ? 'tl' : 'en',
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error ensuring profile: $e');
    }
  }

  Future<bool> _hasAcceptedTerms(String userId) async {
    try {
      final row = await supabase
          .from('profiles')
          .select('terms_accepted')
          .eq('id', userId)
          .maybeSingle();

      return (row?['terms_accepted'] ?? false) == true;
    } catch (e) {
      debugPrint('Error checking terms acceptance: $e');
      return false;
    }
  }

  Future<void> _handlePostLogin(User user) async {
    await _ensureProfile(user);

    final accepted = await _hasAcceptedTerms(user.id);

    if (!mounted) return;

    if (!accepted) {
      final agreed = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => TermsAndConditionsPage(userId: user.id),
        ),
      );

      if (!mounted) return;

      if (agreed == true) {
        _goNext();
      } else {
        try {
          await supabase.auth.signOut();
        } catch (e) {
          debugPrint('Error signing out: $e');
        }
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.tr('must_accept_terms'))));
      }
      return;
    }

    _goNext();
  }

  Future<void> _login() async {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    final email = emailCtrl.text.trim().toLowerCase();
    final password = passCtrl.text;

    setState(() => _isLoading = true);

    try {
      final res = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;

      final user = res.user;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('login_failed'))),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('login_success'))),
      );

      await _handlePostLogin(user);
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      if (isNetworkError(e)) {
        await showNoInternetDialog(context);
        return;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('unexpected_error'))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ignore: unused_element
  Future<void> _googleSignIn() async {
    try {
      await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'com.ignissafe://login-callback',
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      if (isNetworkError(e)) {
        await showNoInternetDialog(context);
        return;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('google_signin_failed'))),
        );
      }
    }
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
                            context.tr('login'),
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
                          const SizedBox(height: 8),
                          Text(
                            context.tr('welcome_to_ignis_safe'),
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.black38,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _languageSelector(),
                          const SizedBox(height: 24),
                          _inputLabel(context.tr('email_address')),
                          _buildValidatedField(
                            hint: context.tr('enter_email'),
                            controller: emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            validator: _validateEmail,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 25),
                          _inputLabel(context.tr('password')),
                          _buildValidatedField(
                            hint: context.tr('enter_password'),
                            controller: passCtrl,
                            validator: _validatePassword,
                            textInputAction: TextInputAction.done,
                            isPassword: true,
                            showPassword: _showPassword,
                            suffixText: _showPassword
                                ? context.tr('hide')
                                : context.tr('show'),
                            onSuffixTap: () =>
                                setState(() => _showPassword = !_showPassword),
                            onSubmitted: (_) => _isLoading ? null : _login(),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const ForgotPassPage(),
                                  ),
                                );
                              },
                              child: Text(
                                context.tr('forgot_password'),
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  color: brandRed,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                          _buildLoginButton(),
                          const SizedBox(height: 20),
                          const SizedBox(height: 10),
                          _buildFooter(),
                          const SizedBox(height: 20),
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

  Widget _inputLabel(String label) => Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            color: brandRed,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      );

  Widget _buildValidatedField({
    required String hint,
    required TextEditingController controller,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    ValueChanged<String>? onSubmitted,
    bool isPassword = false,
    bool showPassword = false,
    String? suffixText,
    VoidCallback? onSuffixTap,
  }) {
    final obscure = isPassword && !showPassword;

    return FormField<String>(
      validator: (_) => validator(controller.text),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: controller,
                keyboardType: keyboardType,
                textInputAction: textInputAction,
                onSubmitted: onSubmitted,
                obscureText: obscure,
                style: const TextStyle(fontFamily: 'Poppins'),
                onChanged: (_) => state.didChange(controller.text),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: const TextStyle(fontFamily: 'Poppins'),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  suffixIcon: suffixText != null
                      ? InkWell(
                          onTap: onSuffixTap,
                          child: Padding(
                            padding: const EdgeInsets.all(15),
                            child: Text(
                              suffixText,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                color: brandRed,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                      : null,
                ),
              ),
            ),
            if (state.errorText != null)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 10),
                child: Text(
                  state.errorText!,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: Colors.red,
                    height: 1.2,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildLoginButton() => SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: brandRed,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: _isLoading ? null : () async { await _login(); },
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  context.tr('login'),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      );

  Widget _buildFooter() => Column(
        children: [
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () async {
              final user = supabase.auth.currentUser;
              final agreed = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => TermsAndConditionsPage(
                    userId: user?.id,
                    readOnly: user == null,
                  ),
                ),
              );
              if (agreed == true && mounted && user != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.tr('terms_accepted'))),
                );
              }
            },
            child: Text(
              context.tr('terms_privacy'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                color: brandRed,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: Divider(thickness: 1)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  context.tr('or'),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(child: Divider(thickness: 1)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "${context.tr('no_account')} ",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RegisterPage()),
                  );
                },
                child: Text(
                  context.tr('sign_up'),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: brandRed,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ],
      );

  Widget _languageSelector() {
    final languageController = context.watch<LanguageController>();

    Widget buildOption({
      required String code,
      required String labelKey,
    }) {
      final selected = languageController.locale.languageCode == code;
      return Expanded(
        child: OutlinedButton(
          onPressed: () => languageController.setLanguage(code),
          style: OutlinedButton.styleFrom(
            backgroundColor: selected ? brandRed : Colors.white,
            side: BorderSide(color: selected ? brandRed : Colors.black26),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            context.tr(labelKey),
            style: TextStyle(
              fontFamily: 'Poppins',
              color: selected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _inputLabel('${context.tr('language')}:'),
        const SizedBox(height: 8),
        Row(
          children: [
            buildOption(code: 'tl', labelKey: 'tagalog'),
            const SizedBox(width: 10),
            buildOption(code: 'en', labelKey: 'english'),
          ],
        ),
      ],
    );
  }
}
