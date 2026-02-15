import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart'; // CONNECT LATER (OTP email)
import 'passwordvalidation.dart';
import 'login.dart';

class VerifyEmailPage extends StatefulWidget {
  final String email;

  const VerifyEmailPage({super.key, required this.email});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  static const Color brandRed = Color(0xFFB71C1C);

  // final supabase = Supabase.instance.client; // CONNECT LATER (OTP email)

  final List<TextEditingController> _ctrl =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focus = List.generate(6, (_) => FocusNode());

  bool _isSending = false;   // kept for later wiring
  bool _isVerifying = false; // kept for later wiring

  @override
  void initState() {
    super.initState();

    // CONNECT LATER (auto-send OTP)
    // _sendOtp();
  }

  @override
  void dispose() {
    for (final c in _ctrl) c.dispose();
    for (final f in _focus) f.dispose();
    super.dispose();
  }

  String get _code => _ctrl.map((c) => c.text.trim()).join();

  // CONNECT LATER (OTP send)
  /*
  Future<void> _sendOtp() async {
    setState(() => _isSending = true);
    try {
      await supabase.auth.signInWithOtp(
        email: widget.email,
        emailRedirectTo: null,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP sent to your email.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send OTP.')),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }
  */

  void _verifyLocalOnly() {
  final code = _code.trim();

  if (!RegExp(r'^\d{6}$').hasMatch(code)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Enter a valid 6-digit numeric code.')),
    );
    return;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Accepted (UI only).')),
  );

  // Small delay so user can see the snackbar
  Future.delayed(const Duration(milliseconds: 800), () {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => CreatePasswordPage(email: widget.email),
      ),
    );
  });
}

  void _onDigitChanged(int i, String v) {
    var value = v.trim();
    if (value.isEmpty) return;

    // Keep ONLY digits, and keep only last character typed
    value = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (value.isEmpty) {
      _ctrl[i].clear();
      return;
    }
    if (value.length > 1) value = value.substring(value.length - 1);

    _ctrl[i].text = value;
    _ctrl[i].selection = const TextSelection.collapsed(offset: 1);

    if (i < 5) {
      _focus[i + 1].requestFocus();
    } else {
      FocusScope.of(context).unfocus();
    }
    setState(() {});
  }

  void _onBackspace(int i) {
    if (_ctrl[i].text.isEmpty && i > 0) {
      _focus[i - 1].requestFocus();
      _ctrl[i - 1].selection =
          TextSelection.collapsed(offset: _ctrl[i - 1].text.length);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Guard: this page must have an email
    if (widget.email.trim().isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Email is required before verification.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandRed,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Go back',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
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

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 10),

                  Image.asset(
                    'assets/logo.png',
                    height: 95,
                    fit: BoxFit.contain,
                  ),

                  const SizedBox(height: 14),

                  const Text(
                    'Register',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
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

                  const SizedBox(height: 6),

                  const Text(
                    'Welcome to, IGNIS SAFE',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.black38,
                    ),
                  ),

                  const SizedBox(height: 18),

                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Verify your email',
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
                          color: Colors.black26,
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

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      'We just sent 6-digit code to\n${widget.email}, enter it bellow:',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(6, (i) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: _OtpBox(
                          controller: _ctrl[i],
                          focusNode: _focus[i],
                          onChanged: (v) => _onDigitChanged(i, v),
                          onBackspace: () => _onBackspace(i),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 22),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: (_isVerifying || _isSending) ? null : _verifyLocalOnly,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandRed,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isVerifying
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Verify email',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Wrong email? ',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: Colors.black45,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Text(
                          'Send to different email',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 26),

                  Row(
                    children: const [
                      Expanded(
                        child: Divider(thickness: 1, color: Color(0xFFE0E0E0)),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'OR',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: Colors.black38,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(thickness: 1, color: Color(0xFFE0E0E0)),
                      ),
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
                          MaterialPageRoute(builder: (_) => const LoginPage()),
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

                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onBackspace;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onBackspace,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 56,
      child: RawKeyboardListener(
        focusNode: FocusNode(),
        onKey: (event) {
          if (event.logicalKey.keyLabel == 'Backspace') {
            onBackspace();
          }
        },
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 1,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: const Color(0xFFF3F3F3),
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
            ),
          ),
          onChanged: (v) {
            // Numbers only
            final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
            if (digits != v) {
              controller.text = digits.isEmpty ? '' : digits.substring(digits.length - 1);
              controller.selection = TextSelection.collapsed(offset: controller.text.length);
            }
            onChanged(controller.text);
          },
        ),
      ),
    );
  }
}
