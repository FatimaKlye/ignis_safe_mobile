import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'forgotpass.dart';
import 'login.dart';

class CreatePasswordPage extends StatefulWidget {
  final String email;
  final String firstName;
  final String lastName;

  const CreatePasswordPage({
    super.key,
    required this.email,
    required this.firstName,
    required this.lastName,
  });

  @override
  State<CreatePasswordPage> createState() => _CreatePasswordPageState();
}

class _CreatePasswordPageState extends State<CreatePasswordPage> {
  static const Color brandRed = Color(0xFFB71C1C);

  final SupabaseClient supabase = Supabase.instance.client;

  final TextEditingController passCtrl = TextEditingController();
  final TextEditingController confirmPassCtrl = TextEditingController();

  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _isLoading = false;

  bool _min8 = false;
  bool _hasNumber = false;
  bool _hasSymbol = false;
  bool _hasUpper = false;
  bool _matches = false;

  @override
  void initState() {
    super.initState();
    passCtrl.addListener(_recalc);
    confirmPassCtrl.addListener(_recalc);
  }

  @override
  void dispose() {
    passCtrl.removeListener(_recalc);
    confirmPassCtrl.removeListener(_recalc);
    passCtrl.dispose();
    confirmPassCtrl.dispose();
    super.dispose();
  }

  void _recalc() {
    final password = passCtrl.text;
    final confirm = confirmPassCtrl.text;

    final min8 = password.length >= 8;
    final hasNumber = RegExp(r'\d').hasMatch(password);
    final hasSymbol =
        RegExp(r'[!@#$%^&*(),.?":{}|<>_\-\[\]\\/~`+=;]').hasMatch(password);
    final hasUpper = RegExp(r'[A-Z]').hasMatch(password);
    final matches = confirm.isNotEmpty && password == confirm;

    if (_min8 != min8 ||
        _hasNumber != hasNumber ||
        _hasSymbol != hasSymbol ||
        _hasUpper != hasUpper ||
        _matches != matches) {
      setState(() {
        _min8 = min8;
        _hasNumber = hasNumber;
        _hasSymbol = hasSymbol;
        _hasUpper = hasUpper;
        _matches = matches;
      });
    }
  }

  int get _passedRules {
    int count = 0;
    if (_min8) count++;
    if (_hasNumber) count++;
    if (_hasSymbol) count++;
    if (_hasUpper) count++;
    return count;
  }

  bool get _isEmpty => passCtrl.text.trim().isEmpty;

  double get _progress {
    if (_isEmpty) return 0.0;
    return _passedRules / 4.0;
  }

  Color get _barColor {
    if (_isEmpty) return const Color(0xFFD32F2F);
    if (_passedRules < 3) return const Color(0xFFF9A825);
    return const Color(0xFF2E7D32);
  }

  String get _strengthText {
    if (_isEmpty) return 'Password is weak';
    if (_passedRules <= 1) return 'Password is weak';
    if (_passedRules <= 3) return 'Password is medium';
    return 'Password is strong';
  }

  Color get _strengthColor {
    if (_isEmpty) return const Color(0xFFD32F2F);
    if (_passedRules <= 1) return const Color(0xFFD32F2F);
    if (_passedRules <= 3) return const Color(0xFFF9A825);
    return const Color(0xFF2E7D32);
  }

  bool get _allOk => _passedRules == 4 && _matches;

  Future<void> _showPopup(String message, {String title = 'Notice'}) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showExistingAccountDialog(String email) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'This email already has an account',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: Text(
          '$email already has an account.\n\nWould you like to reset your password or go to login?',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ForgotPassPage()),
              );
            },
            child: const Text('Forgot Password'),
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
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  Future<void> _continueWithSupabase() async {
    if (_isLoading) return;

    if (!_matches) {
      await _showPopup(
        'Passwords do not match.',
        title: 'Invalid Password',
      );
      return;
    }

    if (!_allOk) {
      await _showPopup(
        'Password does not meet all requirements.',
        title: 'Invalid Password',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final password = passCtrl.text;

      final currentUser = supabase.auth.currentUser;

      if (currentUser == null) {
        throw const AuthException(
          'No active session found. Please verify your email again.',
        );
      }

      final updateResponse = await supabase.auth.updateUser(
        UserAttributes(password: password),
      );

      final user = updateResponse.user ?? supabase.auth.currentUser;
      if (user == null) {
        throw const AuthException(
          'Unable to complete account setup. Please verify your email again.',
        );
      }

      await supabase.from('profiles').upsert({
        'id': user.id,
        'first_name': widget.firstName.trim(),
        'last_name': widget.lastName.trim(),
        'email': widget.email.trim().toLowerCase(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF2E7D32),
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'Account Created!',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your account has been successfully created.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandRed,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    LoginPage.skipAutoRoute = false;
                    await supabase.auth.signOut();

                    if (!context.mounted) return;

                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                      (route) => false,
                    );
                  },
                  child: const Text(
                    'Go to Login',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();

      if (msg.contains('already registered') || msg.contains('already exists')) {
        if (mounted) {
          _showExistingAccountDialog(widget.email.trim().toLowerCase());
        }
      } else {
        await _showPopup(e.message, title: 'Account Setup Failed');
      }
    } catch (e) {
      await _showPopup(
        'Something went wrong while creating your account.\n\n$e',
        title: 'Account Setup Failed',
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _ruleItem(String text, bool passed) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          passed ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 18,
          color: passed ? const Color(0xFF2E7D32) : Colors.black38,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: passed ? const Color(0xFF2E7D32) : Colors.black54,
              fontWeight: passed ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _passwordField({
    required String hint,
    required TextEditingController controller,
    required bool obscureText,
    required String suffixText,
    required VoidCallback onSuffixTap,
    TextInputAction? textInputAction,
    ValueChanged<String>? onSubmitted,
  }) {
    return Container(
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
        obscureText: obscureText,
        textInputAction: textInputAction,
        onSubmitted: onSubmitted,
        style: const TextStyle(fontFamily: 'Poppins'),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontFamily: 'Poppins'),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
          suffixIcon: InkWell(
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
          ),
        ),
      ),
    );
  }

  Widget _inputLabel(String label) {
    return Align(
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
  }

  @override
  Widget build(BuildContext context) {
    final email = widget.email.trim().toLowerCase();

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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
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
                        const Text(
                          'Create Password',
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
                        const Text(
                          'Welcome to, IGNIS SAFE',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.black38,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 60),
                        Row(
                          children: [
                            IconButton(
                              onPressed: _isLoading
                                  ? null
                                  : () => Navigator.pop(context),
                              icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Set your password',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 18,
                              height: 3,
                              decoration: BoxDecoration(
                                color: brandRed,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            const SizedBox(width: 18),
                            Container(
                              width: 18,
                              height: 3,
                              decoration: BoxDecoration(
                                color: brandRed,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            const SizedBox(width: 18),
                            Container(
                              width: 18,
                              height: 3,
                              decoration: BoxDecoration(
                                color: Colors.black26,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Text(
                          email,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 28),
                        _inputLabel('PASSWORD:'),
                        _passwordField(
                          hint: 'Enter your password',
                          controller: passCtrl,
                          obscureText: !_showPassword,
                          suffixText: _showPassword ? 'HIDE' : 'SHOW',
                          onSuffixTap: () {
                            setState(() => _showPassword = !_showPassword);
                          },
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 20),
                        _inputLabel('CONFIRM PASSWORD:'),
                        _passwordField(
                          hint: 'Confirm your password',
                          controller: confirmPassCtrl,
                          obscureText: !_showConfirmPassword,
                          suffixText: _showConfirmPassword ? 'HIDE' : 'SHOW',
                          onSuffixTap: () {
                            setState(() {
                              _showConfirmPassword = !_showConfirmPassword;
                            });
                          },
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) {
                            if (!_isLoading) {
                              _continueWithSupabase();
                            }
                          },
                        ),
                        const SizedBox(height: 22),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F8F8),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFEAEAEA)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Password strength',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: LinearProgressIndicator(
                                  value: _progress,
                                  minHeight: 8,
                                  backgroundColor: const Color(0xFFE6E6E6),
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(_barColor),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _strengthText,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _strengthColor,
                                ),
                              ),
                              const SizedBox(height: 14),
                              _ruleItem('At least 8 characters', _min8),
                              const SizedBox(height: 8),
                              _ruleItem('At least 1 number', _hasNumber),
                              const SizedBox(height: 8),
                              _ruleItem('At least 1 symbol', _hasSymbol),
                              const SizedBox(height: 8),
                              _ruleItem('At least 1 uppercase letter', _hasUpper),
                              const SizedBox(height: 8),
                              _ruleItem('Passwords match', _matches),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: brandRed,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: _isLoading ? null : _continueWithSupabase,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Create Account',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Already have an account? ',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: Colors.black38,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                LoginPage.skipAutoRoute = false;
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const LoginPage(),
                                  ),
                                  (route) => false,
                                );
                              },
                              child: const Text(
                                'Log in',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: brandRed,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
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