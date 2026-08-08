import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'localization/language_controller.dart';
import 'login.dart';
import 'network_error_helper.dart';
import 'widgets/app_notification.dart';

class VerifyEmailPage extends StatefulWidget {
  final String email;
  final String firstName;
  final String lastName;
  final String password;

  const VerifyEmailPage({
    super.key,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.password,
  });

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  static const Color brandRed = Color(0xFFB71C1C);

  final SupabaseClient supabase = Supabase.instance.client;
  final TextEditingController _otpCtrl = TextEditingController();
  final FocusNode _otpFocus = FocusNode();

  bool _isSending = false;
  bool _isVerifying = false;
  bool _signupStarted = false;
  bool _completed = false;

  String get _email => widget.email.trim().toLowerCase();
  String get _code => _otpCtrl.text.trim();
  bool get _codeComplete => RegExp(r'^\d{6}$').hasMatch(_code);

  @override
  void initState() {
    super.initState();
    _otpCtrl.addListener(() => setState(() {}));
    _otpFocus.addListener(() => setState(() {}));

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      _otpFocus.requestFocus();
      if (_email.isNotEmpty) {
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

  void _notify(
    BuildContext context, {
    String? title,
    required String message,
    AppNotificationType type = AppNotificationType.info,
  }) {
    showAppNotification(
      context,
      title: title,
      message: message,
      type: type,
      accentColor: brandRed,
    );
  }

  void _clearOtp() {
    _otpCtrl.clear();
    _otpFocus.requestFocus();
  }

  // Leaving this screen (Back button or the "Login" link) must not delete
  // the pending account - the signup stays unverified in Supabase Auth so
  // the user can come back later and continue verifying the same account
  // instead of it being recreated from scratch. Only sign out of the
  // temporary session created by signUp().
  Future<void> _cleanupPendingByEmail() async {
    if (_completed || _email.isEmpty) return;

    try {
      await supabase.auth.signOut();
    } catch (e) {
      debugPrint('signOut on exit failed: $e');
    }
  }

  Future<void> _showNoticeDialog({
    required String title,
    required String message,
    IconData icon = Icons.error_outline_rounded,
  }) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 30,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(99),
                    onTap: () => Navigator.pop(dialogContext),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 68,
                  width: 68,
                  decoration: BoxDecoration(
                    color: brandRed.withOpacity(0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: brandRed, size: 36),
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                    height: 1.18,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 2,
                  width: 90,
                  decoration: BoxDecoration(
                    color: brandRed,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black.withOpacity(0.60),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandRed,
                      elevation: 4,
                      shadowColor: brandRed.withOpacity(0.35),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      t(context, 'OK', 'Sige'),
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _sendOtp({bool showToast = true}) async {
    if (_isSending || _email.isEmpty) return;

    setState(() => _isSending = true);

    try {
      if (_signupStarted) {
        await supabase.auth.resend(
          type: OtpType.signup,
          email: _email,
        );
      } else {
        await supabase.auth.signOut();
        final signUpResponse = await supabase.auth.signUp(
          email: _email,
          password: widget.password,
          data: {
            'first_name': widget.firstName.trim(),
            'last_name': widget.lastName.trim(),
            'registration_completed': false,
            'app_language_code':
                Localizations.localeOf(context).languageCode == 'tl' ? 'tl' : 'en',
            'signup_source': 'mobile',
          },
        );

        // Supabase does not throw when the email already belongs to a
        // confirmed account - it returns 200 with an empty `identities`
        // list and sends no email at all (anti-enumeration behavior). Left
        // unchecked, the code above would report "sent" even though no OTP
        // was ever dispatched.
        final identities = signUpResponse.user?.identities;
        if (identities != null && identities.isEmpty) {
          if (!mounted) return;
          await _showNoticeDialog(
            title: t(
              context,
              'Email Already Registered',
              'May Account na ang Email',
            ),
            message: t(
              context,
              'This email already has an account. Please login instead, or use Forgot Password if needed.',
              'May account na ang email na ito. Mag-login na lang, o gamitin ang Nakalimutan ang Password kung kailangan.',
            ),
          );
          return;
        }

        _signupStarted = true;
      }

      if (!mounted) return;

      if (showToast) {
        _notify(
          context,
          message: t(
            context,
            'Verification code sent. Check your email inbox/spam.',
            'Naipadala ang verification code. Tingnan ang iyong email inbox/spam.',
          ),
          type: AppNotificationType.success,
        );
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      final message = e.message.toLowerCase();

      if (message.contains('already registered') ||
          message.contains('already exists') ||
          message.contains('user already')) {
        await _showNoticeDialog(
          title: t(context, 'Email Already Registered', 'May Account na ang Email'),
          message: t(
            context,
            'This email already has an account. Please login instead, or use Forgot Password if needed.',
            'May account na ang email na ito. Mag-login na lang, o gamitin ang Nakalimutan ang Password kung kailangan.',
          ),
        );
      } else {
        await _showNoticeDialog(
          title: t(context, 'Could Not Send Code', 'Hindi Maipadala ang Code'),
          message: e.message,
        );
      }
    } catch (e) {
      if (!mounted) return;
      if (isNetworkError(e)) {
        await showNoInternetDialog(context);
      } else {
        await _showNoticeDialog(
          title: t(context, 'Could Not Send Code', 'Hindi Maipadala ang Code'),
          message: t(
            context,
            'Error sending code. Please try again.',
            'May error sa pagpapadala ng code. Subukang muli.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (_isVerifying || _email.isEmpty) return;

    if (!_codeComplete) {
      _notify(
        context,
        message: t(
          context,
          'Enter a valid 6-digit numeric code.',
          'Maglagay ng wastong 6-digit na numeric code.',
        ),
        type: AppNotificationType.error,
      );
      return;
    }

    setState(() => _isVerifying = true);

    try {
      final response = await supabase.auth.verifyOTP(
        type: OtpType.signup,
        email: _email,
        token: _code,
      );

      final user = response.user ?? supabase.auth.currentUser;
      if (user == null) {
        throw const AuthException(
          'Unable to complete account setup. Please verify your email again.',
        );
      }

      await supabase.from('profiles').upsert({
        'id': user.id,
        'first_name': widget.firstName.trim(),
        'last_name': widget.lastName.trim(),
        'email': _email,
        'registration_status': 'completed',
        'app_language_code':
            Localizations.localeOf(context).languageCode == 'tl' ? 'tl' : 'en',
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });

      await supabase.auth.updateUser(
        UserAttributes(
          data: {
            'first_name': widget.firstName.trim(),
            'last_name': widget.lastName.trim(),
            'registration_completed': true,
            'app_language_code':
                Localizations.localeOf(context).languageCode == 'tl' ? 'tl' : 'en',
          },
        ),
      );

      _completed = true;

      if (!mounted) return;

      await _showAccountCreatedDialog();
    } on AuthException catch (e) {
      if (!mounted) return;
      await _showNoticeDialog(
        title: t(context, 'Invalid Code', 'Maling Code'),
        message: e.message,
      );
    } catch (e) {
      if (!mounted) return;
      if (isNetworkError(e)) {
        await showNoInternetDialog(context);
      } else {
        await _showNoticeDialog(
          title: t(context, 'Verification Failed', 'Hindi Na-verify'),
          message: t(
            context,
            'Error verifying code. Please try again.',
            'May error sa pag-verify ng code. Subukang muli.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _showAccountCreatedDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 30,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 72,
                  width: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withOpacity(0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF2E7D32),
                    size: 42,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  t(context, 'Account Created!', 'Nagawa na ang Account!'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  t(
                    context,
                    'Your email has been verified and your account is ready.',
                    'Na-verify na ang iyong email at handa na ang iyong account.',
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: Colors.black.withOpacity(0.60),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandRed,
                      elevation: 4,
                      shadowColor: brandRed.withOpacity(0.35),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      t(context, 'Go to Login', 'Pumunta sa Login'),
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOtpCard() {
    final typed = _otpCtrl.text;
    final focused = _otpFocus.hasFocus;

    return GestureDetector(
      onTap: () => _otpFocus.requestFocus(),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
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
                            fontWeight: isFilled ? FontWeight.w700 : FontWeight.w400,
                            color: isFilled ? Colors.black87 : Colors.black26,
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

  Widget _buildFooter() => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Expanded(child: Divider(thickness: 1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  t(context, 'OR', 'O'),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Expanded(child: Divider(thickness: 1)),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                "${t(context, 'Already have an account?', 'Mayroon ka nang account?')} ",
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),
              TextButton(
                onPressed: (_isSending || _isVerifying)
                    ? null
                    : () async {
                        await _cleanupPendingByEmail();
                        LoginPage.skipAutoRoute = false;
                        if (!context.mounted) return;
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                          (route) => false,
                        );
                      },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  t(context, 'Login', 'Mag-login'),
                  style: const TextStyle(
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

  @override
  Widget build(BuildContext context) {
    if (_email.isEmpty) {
      return Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              t(
                context,
                'Missing email. Please go back to sign up.',
                'Walang email. Bumalik sa sign up.',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Poppins'),
            ),
          ),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        if (_isSending || _isVerifying || _completed) return !_isSending && !_isVerifying;
        await _cleanupPendingByEmail();
        return true;
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 35.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.topCenter,
                      child: SizedBox(
                        width: constraints.maxWidth,
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
                              t(
                                context,
                                'Verify Email Address',
                                'I-verify ang Email Address',
                              ),
                              textAlign: TextAlign.center,
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
                              _email,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.black54,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 10,
                                    offset: Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    height: 58,
                                    width: 58,
                                    decoration: BoxDecoration(
                                      color: brandRed.withOpacity(0.10),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.lock_clock_rounded,
                                      color: brandRed,
                                      size: 30,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    t(
                                      context,
                                      'Enter the 6-digit code sent to your email.',
                                      'Ilagay ang 6-digit code na ipinadala sa iyong email.',
                                    ),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                      height: 1.35,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  _buildOtpCard(),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      TextButton(
                                        onPressed: _otpCtrl.text.isEmpty ? null : _clearOtp,
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 6),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: Text(
                                          t(context, 'Clear', 'Burahin'),
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: _otpCtrl.text.isEmpty
                                                ? Colors.black26
                                                : brandRed,
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: (_isVerifying || _isSending)
                                            ? null
                                            : () => _sendOtp(showToast: true),
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 6),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: Text(
                                          _isSending
                                              ? t(context, 'Sending...', 'Ipinapadala...')
                                              : t(context, 'Resend code', 'Magpadala ulit'),
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
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: (_isVerifying || _isSending) ? null : _verifyOtp,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: brandRed,
                                  disabledBackgroundColor: brandRed.withOpacity(0.55),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
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
                                            ? t(
                                                context,
                                                'Verify Email Address',
                                                'I-verify ang Email Address',
                                              )
                                            : t(context, 'Enter Code', 'Ilagay ang Code'),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ExcludeSemantics(
                              child: IgnorePointer(
                                child: Opacity(
                                  opacity: 0,
                                  child: Text(
                                    t(
                                      context,
                                      'Terms and Privacy Policy',
                                      'Mga Tuntunin at Patakaran sa Privacy',
                                    ),
                                    textAlign: TextAlign.center,
                                    softWrap: true,
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      color: brandRed,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      height: 1.25,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
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
      ),
    );
  }
}
