import 'package:flutter/material.dart';

class CreatePasswordPage extends StatefulWidget {
  final String email;

  const CreatePasswordPage({super.key, required this.email});

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
    final hasSym = RegExp(r'[!@#$%^&*(),.?":{}|<>_\-\[\]\\\/~`+=;]').hasMatch(p);

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

  // Progress value: 0.0, 0.33, 0.66, 1.0
  double get _progress {
    if (_isEmpty) return 0.0;
    return _passedRules / 3.0;
  }

  Color get _barColor {
    if (_isEmpty) return const Color(0xFFD32F2F); // red
    if (_passedRules < 3) return const Color(0xFFF9A825); // yellow
    return const Color(0xFF2E7D32); // green
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

  void _continueLocalOnly() {
    if (!_allOk) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password does not meet requirements.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Accepted (UI only).')),
    );

    // CONNECT LATER: next step
  }

  @override
  Widget build(BuildContext context) {
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
                          borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
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

                  // Progress bar (color changes red/yellow/green)
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

                  // Strength text
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
                      onPressed: _continueLocalOnly,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandRed,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
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
                    children: const [
                      Text(
                        'Already have an account? ',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: Colors.black38,
                        ),
                      ),
                      Text(
                        'Log in',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: brandRed,
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
