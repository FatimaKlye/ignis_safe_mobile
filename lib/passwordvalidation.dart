import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  final passCtrl = TextEditingController();
  bool _showPassword = false;

  bool _min8 = false;
  bool _hasNumber = false;
  bool _hasSymbol = false;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    passCtrl.addListener(_recalc);
  }

  @override
  void dispose() {
    passCtrl.removeListener(_recalc);
    passCtrl.dispose();
    super.dispose();
  }

  void _recalc() {
    final p = passCtrl.text;

    final min8 = p.length >= 8;
    final hasNum = RegExp(r'\d').hasMatch(p);
    final hasSym =
        RegExp(r'[!@#$%^&*(),.?":{}|<>_\-\[\]\\\/~`+=;]').hasMatch(p);

    if (_min8 != min8 || _hasNumber != hasNum || _hasSymbol != hasSym) {
      setState(() {
        _min8 = min8;
        _hasNumber = hasNum;
        _hasSymbol = hasSym;
      });
    }
  }

  int get _passedRules {
    int n = 0;
    if (_min8) n++;
    if (_hasNumber) n++;
    if (_hasSymbol) n++;
    return n;
  }

  bool get _isEmpty => passCtrl.text.trim().isEmpty;

  double get _progress {
    if (_isEmpty) return 0.0;
    return _passedRules / 3.0;
  }

  Color get _barColor {
    if (_isEmpty) return const Color(0xFFD32F2F);
    if (_passedRules < 3) return const Color(0xFFF9A825);
    return const Color(0xFF2E7D32);
  }

  String get _strengthText {
    if (_isEmpty) return 'Password is weak';
    if (_passedRules <= 1) return 'Password is weak';
    if (_passedRules == 2) return 'Password is medium';
    return 'Password is strong';
  }

  Color get _strengthColor {
    if (_isEmpty) return const Color(0xFFD32F2F);
    if (_passedRules <= 1) return const Color(0xFFD32F2F);
    if (_passedRules == 2) return const Color(0xFFF9A825);
    return const Color(0xFF2E7D32);
  }

  bool get _allOk => _passedRules == 3;

  Future<void> _continueWithSupabase() async {
    if (_isLoading) return;

    if (!_allOk) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password does not meet requirements.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final supabase = Supabase.instance.client;

    try {
      final password = passCtrl.text;

      // After verifyOTP, user is authenticated but may not have a password yet.
      // This sets the password for the current authenticated user.
      final update = await supabase.auth.updateUser(
        UserAttributes(password: password),
      );

      final user = update.user ?? supabase.auth.currentUser;
      if (user == null) {
        throw const AuthException('No active user session. Verify OTP again.');
      }

      // Create/Update profiles row (id = auth user id)
      await supabase.from('profiles').upsert({
        'id': user.id,
        'first_name': widget.firstName.trim(),
        'last_name': widget.lastName.trim(),
        'email': widget.email.trim(),
      });

      if (!mounted) return;

      // Success dialog (same UI behavior as your local-only version)
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
                    // Ensure user ends the registration flow logged-out,
                    // so they must login with email+password next.
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // UI copied from your createpassword.dart (NO layout/styling changes)
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0), // same as verify email
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Header (same as verify email)
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

                        const SizedBox(height: 80),

                        // Section header row (same spacing pattern)
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Create your password',
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

                        // Steps
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 18,
                              height: 3,
                              decoration: BoxDecoration(
                                color: Colors.black26,
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
                                color: brandRed,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 22),

                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Password',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.black54,
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x14000000),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: passCtrl,
                            obscureText: !_showPassword,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 14,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide:
                                    const BorderSide(color: Color(0xFFDDDDDD)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide:
                                    const BorderSide(color: Color(0xFFDDDDDD)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide:
                                    const BorderSide(color: Color(0xFFCCCCCC)),
                              ),
                              suffixIcon: IconButton(
                                onPressed: () =>
                                    setState(() => _showPassword = !_showPassword),
                                icon: Icon(
                                  _showPassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: Colors.black45,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            height: 6,
                            width: double.infinity,
                            child: LinearProgressIndicator(
                              value: _progress,
                              backgroundColor: const Color(0xFFE6E6E6),
                              valueColor: AlwaysStoppedAnimation<Color>(_barColor),
                              minHeight: 6,
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _strengthText,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _strengthColor,
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        _RuleRow(text: '8 characters minimum', ok: _min8),
                        const SizedBox(height: 8),
                        _RuleRow(text: 'a number', ok: _hasNumber),
                        const SizedBox(height: 8),
                        _RuleRow(text: 'a symbol', ok: _hasSymbol),

                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _continueWithSupabase,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: brandRed,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
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
                                    'Continue',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 120),

                        Row(
                          children: const [
                            Expanded(child: Divider(thickness: 1)),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'OR',
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

                        const SizedBox(height: 14),

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
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const LoginPage()),
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

class _RuleRow extends StatelessWidget {
  final String text;
  final bool ok;

  const _RuleRow({required this.text, required this.ok});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.check_circle,
          size: 18,
          color: ok ? const Color(0xFF2E7D32) : const Color(0xFF9E9E9E),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: ok ? const Color(0xFF2E7D32) : Colors.black54,
          ),
        ),
      ],
    );
  }
}