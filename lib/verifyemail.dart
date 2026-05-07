import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'localization/language_controller.dart';
import 'passwordvalidation.dart';
import 'login.dart';

class VerifyEmailPage extends StatefulWidget {
  final String email;
  final String firstName;
  final String lastName;

  const VerifyEmailPage({
    super.key,
    required this.email,
    required this.firstName,
    required this.lastName,
  });

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  static const Color brandRed = Color(0xFFB71C1C);

  final SupabaseClient supabase = Supabase.instance.client;

  // ── Single controller + focus for the card-style OTP input ───────────────
  final TextEditingController _otpCtrl = TextEditingController();
  final FocusNode _otpFocus = FocusNode();

  bool _isSending = false;
  bool _isVerifying = false;

  Future<void> _cleanupPendingByEmail() async {
    final email = widget.email.trim().toLowerCase();
    if (email.isEmpty) return;

    try {
      await supabase.functions.invoke(
        'cancel_pending_signup_email',
        body: {'email': email},
      );
    } catch (_) {
      // Best-effort cleanup.
    }

    try {
      await supabase.auth.signOut();
    } catch (_) {
      // ignore
    }
  }

  @override
  void initState() {
    super.initState();
    _otpCtrl.addListener(() => setState(() {}));
    _otpFocus.addListener(() => setState(() {})); // rebuild on focus change

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      _otpFocus.requestFocus();
      if (widget.email.trim().isNotEmpty) {
        await _sendOtp(showToast: false);
      }
    });
  }

  @override
  void dispose() {
    _otpCtrl.dispose();
    _otpFocus.dispose();
    super.dispose();
  }

  String get _code => _otpCtrl.text.trim();
  bool get _codeComplete => RegExp(r'^\d{6}$').hasMatch(_code);

  void _clearOtp() {
    _otpCtrl.clear();
    _otpFocus.requestFocus();
  }

  // ── Send OTP ──────────────────────────────────────────────────────────────
  Future<void> _sendOtp({bool showToast = true}) async {
    if (_isSending) return;

    final email = widget.email.trim().toLowerCase();
    if (email.isEmpty) return;

    setState(() => _isSending = true);

    try {
      await supabase.auth.signInWithOtp(
        email: email,
        shouldCreateUser: true,
        data: {
          'first_name': widget.firstName,
          'last_name': widget.lastName,
          // Mark this user as created via the multi-step signup flow.
          // We only flip this to true on the final submit step.
          'registration_completed': false,
          'app_language_code':
              Localizations.localeOf(context).languageCode == 'tl'
                  ? 'tl'
                  : 'en',
        },
      );

      if (!mounted) return;

      if (showToast) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              t(
                context,
                'Verification code sent. Check your email inbox/spam.',
                'Naipadala ang verification code. Tingnan ang iyong email inbox/spam.',
              ),
            ),
          ),
        );
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            t(
              context,
              'Error sending code: $e',
              'Nagkaroon ng error sa pagpapadala ng code: $e',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  // ── Verify OTP ────────────────────────────────────────────────────────────
  Future<void> _verifyOtp() async {
    if (_isVerifying) return;

    final email = widget.email.trim().toLowerCase();
    if (email.isEmpty) return;

    if (!_codeComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            t(
              context,
              'Enter a valid 6-digit numeric code.',
              'Maglagay ng wastong 6-digit na numeric code.',
            ),
          ),
        ),
      );
      return;
    }

    setState(() => _isVerifying = true);

    try {
      await supabase.auth.verifyOTP(
        type: OtpType.email,
        email: email,
        token: _code,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CreatePasswordPage(
            email: widget.email.trim().toLowerCase(),
            firstName: widget.firstName,
            lastName: widget.lastName,
          ),
        ),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            t(
              context,
              'Error verifying code: $e',
              'Nagkaroon ng error sa pag-verify ng code: $e',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  // ── OTP Card Widget ───────────────────────────────────────────────────────
  Widget _buildOtpCard() {
    final typed = _otpCtrl.text;
    final focused = _otpFocus.hasFocus;

    return GestureDetector(
      onTap: () => _otpFocus.requestFocus(),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── Card border ─────────────────────────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 72,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: focused ? brandRed : const Color(0xFFB71C1C),
                width: focused ? 1.8 : 1.4,
              ),
            ),
            child: Stack(
              children: [
                // Hidden TextField — absorbs keyboard input
                Positioned.fill(
                  child: Opacity(
                    opacity: 0,
                    child: TextField(
                      controller: _otpCtrl,
                      focusNode: _otpFocus,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      decoration: const InputDecoration(
                        counterText: '',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),

                // ── Digit / dash slots ────────────────────────────────────
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(6, (i) {
                      final isFilled = i < typed.length;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 9),
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 120),
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: isFilled ? 22 : 20,
                            fontWeight: isFilled
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color:
                                isFilled ? Colors.black87 : Colors.black26,
                          ),
                          child: Text(isFilled ? typed[i] : '–'),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),

          // ── Floating "OTP Code" label ────────────────────────────────────
          Positioned(
            top: -10,
            left: 14,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Text(
                t(context, 'OTP Code', 'OTP Code'),
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: brandRed,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = widget.email.trim();

    if (email.isEmpty) {
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

    return WillPopScope(
      onWillPop: () async {
        if (_isSending || _isVerifying) return false;
        await _cleanupPendingByEmail();
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                        Padding(
                          padding:
                              const EdgeInsets.only(top: 70, bottom: 30),
                          child: SizedBox(
                            height: 120,
                            child: FittedBox(
                              fit: BoxFit.contain,
                              child: Image.asset('assets/logo.png'),
                            ),
                          ),
                        ),
                        const Text(
                          'Verify Email Address',
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
                        Row(
                          children: [
                            IconButton(
                              onPressed: (_isSending || _isVerifying)
                                  ? null
                                  : () async {
                                      await _cleanupPendingByEmail();
                                      if (!context.mounted) return;
                                      Navigator.pop(context);
                                    },
                              icon: const Icon(
                                Icons.arrow_back_ios_new,
                                size: 18,
                              ),
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
                        // Step indicator
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
                          padding:
                              const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            t(
                              context,
                              'We just sent a 6-digit code to\n$email\nEnter it below:',
                              'Nagpadala kami ng 6-digit OTP sa\n$email\nIlagay ito sa ibaba:',
                            ),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // ── Card-style OTP input ──────────────────────────
                        _buildOtpCard(),

                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                              onPressed: (_isVerifying || _isSending)
                                  ? null
                                  : _clearOtp,
                              child: Text(
                                t(context, 'Clear', 'Burahin'),
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            TextButton(
                              onPressed: (_isVerifying || _isSending)
                                  ? null
                                  : () => _sendOtp(showToast: true),
                              child: Text(
                                t(context, 'Resend code', 'Magpadala ulit'),
                                style: const TextStyle(
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
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: (_isVerifying || _isSending)
                                ? null
                                : _verifyOtp,
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
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    _codeComplete
                                        ? t(context, 'Verify email',
                                            'I-verify ang email')
                                        : t(context, 'Enter code',
                                            'Ilagay ang code'),
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              t(
                                context,
                                'Already have an account? ',
                                'Mayroon ka nang account? ',
                              ),
                              style: const TextStyle(
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
                                    builder: (_) => const LoginPage(),
                                  ),
                                  (route) => false,
                                );
                              },
                              child: Text(
                                t(context, 'Log in', 'Mag-login'),
                                style: const TextStyle(
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
      ),
    );
  }
}