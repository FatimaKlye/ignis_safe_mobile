import 'package:flutter/material.dart';
import 'login.dart';
import 'verifyemail.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  static const Color brandRed = Color(0xFFB71C1C);

  final _formKey = GlobalKey<FormState>();

  final firstNameCtrl = TextEditingController();
  final lastNameCtrl = TextEditingController();
  final emailUserCtrl = TextEditingController(); // only before @gmail.com

  @override
  void dispose() {
    firstNameCtrl.dispose();
    lastNameCtrl.dispose();
    emailUserCtrl.dispose();
    super.dispose();
  }

  String? _validateRequired(String? v, String msg) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return msg;
    return null;
  }

  String? _validateEmailUser(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return 'Email is required';

    // Only allow a safe set of characters for the Gmail username part
    final ok = RegExp(r'^[a-zA-Z0-9._%+\-]+$').hasMatch(value);
    if (!ok) return 'Use letters/numbers only';
    return null;
  }

  void _goToVerifyEmail() {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    final fullEmail = '${emailUserCtrl.text.trim()}@gmail.com';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VerifyEmailPage(email: fullEmail),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 10),

                    Image.asset(
                      'assets/logo.png',
                      height: 250,
                      width: screenW * 0.9,
                      fit: BoxFit.contain,
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      'Register',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 8),

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
                      ),
                    ),

                    const SizedBox(height: 26),

                    const _Label(text: 'FIRST NAME:', color: brandRed),
                    const SizedBox(height: 8),
                    _ShadowField(
                      child: TextFormField(
                        controller: firstNameCtrl,
                        keyboardType: TextInputType.name,
                        validator: (v) =>
                            _validateRequired(v, 'First name is required'),
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                        decoration: _inputDecoration('Enter your first name'),
                      ),
                    ),

                    const SizedBox(height: 18),

                    const _Label(text: 'LAST NAME:', color: brandRed),
                    const SizedBox(height: 8),
                    _ShadowField(
                      child: TextFormField(
                        controller: lastNameCtrl,
                        keyboardType: TextInputType.name,
                        validator: (v) =>
                            _validateRequired(v, 'Last name is required'),
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                        decoration: _inputDecoration('Enter your last name'),
                      ),
                    ),

                    const SizedBox(height: 18),

                    const _Label(text: 'EMAIL ADDRESS:', color: brandRed),
                    const SizedBox(height: 8),
                    _ShadowField(
                      child: TextFormField(
                        controller: emailUserCtrl,
                        keyboardType: TextInputType.emailAddress,
                        validator: _validateEmailUser,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                        decoration: _inputDecoration('Enter your email').copyWith(
                          suffixText: '@gmail.com',
                          suffixStyle: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 26),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _goToVerifyEmail,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brandRed,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Create account',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    Row(
                      children: const [
                        Expanded(
                          child: Divider(
                            thickness: 1,
                            color: Color(0xFFE0E0E0),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'OR',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.black38,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            thickness: 1,
                            color: Color(0xFFE0E0E0),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          'Already have an account? ',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.black38,
                          ),
                        ),
                        _HoverLogin(),
                      ],
                    ),

                    const SizedBox(height: 6),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Colors.black26,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFDDDDDD), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFDDDDDD), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFCCCCCC), width: 1),
      ),
    );
  }
}

class _HoverLogin extends StatefulWidget {
  const _HoverLogin();

  @override
  State<_HoverLogin> createState() => _HoverLoginState();
}

class _HoverLoginState extends State<_HoverLogin> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _hover ? const Color(0xFFEAEAEA) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Log in',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFFB71C1C),
            ),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  final Color color;

  const _Label({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _ShadowField extends StatelessWidget {
  final Widget child;

  const _ShadowField({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: child,
    );
  }
}
