import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'forgotpass.dart';
import 'login.dart';
import 'verifyemail.dart';

String _t(BuildContext context, String en, String tl) {
  return Localizations.localeOf(context).languageCode == 'tl' ? tl : en;
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  static const Color brandRed = Color(0xFFB71C1C);
  final supabase = Supabase.instance.client;
  static final RegExp _namePattern = RegExp(r"^[A-Za-z]+(?:[ '\-][A-Za-z]+)*$");

  final _formKey = GlobalKey<FormState>();
  final firstNameCtrl = TextEditingController();
  final lastNameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    firstNameCtrl.dispose();
    lastNameCtrl.dispose();
    emailCtrl.dispose();
    super.dispose();
  }

  bool _isValidEmail(String s) {
    final v = s.trim();
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v);
  }

  String? _validateFirstName(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return _t(context, 'First name is required', 'Kailangan ang unang pangalan');
    if (!_namePattern.hasMatch(value.trim())) {
      return _t(context, 'First name should contain letters only', 'Mga titik lamang ang dapat laman ng unang pangalan');
    }
    return null;
  }

  String? _validateLastName(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return _t(context, 'Last name is required', 'Kailangan ang apelyido');
    if (!_namePattern.hasMatch(value.trim())) {
      return _t(context, 'Last name should contain letters only', 'Mga titik lamang ang dapat laman ng apelyido');
    }
    return null;
  }

  String? _validateEmail(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return 'Email is required';
    if (!_isValidEmail(value)) return 'Enter a valid email';
    return null;
  }

  Future<bool> _emailAlreadyExists(String email) async {
    final normalizedEmail = email.trim().toLowerCase();

    final result = await Supabase.instance.client.rpc(
      'email_exists',
      params: {'p_email': normalizedEmail},
    );

    return result == true;
  }

  void _showExistingAccountDialog(String email) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          _t(context, 'This email already has an account', 'Mayroon nang account ang email na ito'),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        content: Text(
          _t(
            context,
            '$email already has an account.\n\nWould you like to reset your password or go to login?',
            '$email ay mayroon nang account.\n\nNais mo bang i-reset ang iyong password o mag-login?',
          ),
          style: const TextStyle(fontWeight: FontWeight.w600, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_t(context, 'Cancel', 'Kanselahin')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ForgotPassPage()),
              );
            },
            child: Text(_t(context, 'Forgot Password', 'Nakalimutan ang Password')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              LoginPage.skipAutoRoute = false;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
            child: Text(_t(context, 'Login', 'Mag-login')),
          ),
        ],
      ),
    );
  }

  Future<void> _continueToVerifyEmail() async {
    final firstName = firstNameCtrl.text.trim();
    final lastName = lastNameCtrl.text.trim();
    final email = emailCtrl.text.trim().toLowerCase();

    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    setState(() => _isLoading = true);

    try {
      final exists = await _emailAlreadyExists(email);

      if (!mounted) return;

      if (exists) {
        _showExistingAccountDialog(email);
        return;
      }

      LoginPage.skipAutoRoute = true;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VerifyEmailPage(
            email: email,
            firstName: firstName,
            lastName: lastName,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            _t(context, 'Could not check email: $e', 'Hindi masuri ang email: $e'),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
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
                inputFormatters: inputFormatters,
                textCapitalization: textCapitalization,
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

  Widget _buildRegisterButton() => SizedBox(
    width: double.infinity,
    height: 50,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: brandRed,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: _isLoading ? null : _continueToVerifyEmail,
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
              _t(context, 'Verify Email Address', 'I-verify ang Email Address'),
              style: const TextStyle(
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
      const SizedBox(height: 55),
      Row(
        children: [
          Expanded(child: Divider(thickness: 1)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              _t(context, 'OR', 'O'),
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
          const Text(
            "Already have an account? ",
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            },
            child: Text(
              _t(context, 'Login', 'Mag-login'),
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
      const SizedBox(height: 10),
    ],
  );

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
                            _t(context, 'Sign Up', 'Mag-sign up'),
                            style: const TextStyle(
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
                            _t(context, 'Welcome to, IGNIS SAFE', 'Maligayang pagdating sa IGNIS SAFE'),
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.black38,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 80),
                          _inputLabel(_t(context, 'FIRST NAME:', 'UNANG PANGALAN:')),
                          _buildValidatedField(
                            hint: _t(context, 'Enter your first name', 'Ilagay ang iyong unang pangalan'),
                            controller: firstNameCtrl,
                            validator: _validateFirstName,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r"[A-Za-z '\-]"),
                              ),
                            ],
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 25),
                          _inputLabel(_t(context, 'LAST NAME:', 'APELYIDO:')),
                          _buildValidatedField(
                            hint: _t(context, 'Enter your last name', 'Ilagay ang iyong apelyido'),
                            controller: lastNameCtrl,
                            validator: _validateLastName,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r"[A-Za-z '\-]"),
                              ),
                            ],
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 25),
                          _inputLabel(_t(context, 'EMAIL ADDRESS:', 'EMAIL ADDRESS:')),
                          _buildValidatedField(
                            hint: _t(context, 'Enter your email address', 'Ilagay ang iyong email address'),
                            controller: emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            validator: _validateEmail,
                            textInputAction: TextInputAction.done,
                          ),
                          const SizedBox(height: 40),
                          _buildRegisterButton(),
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
}
