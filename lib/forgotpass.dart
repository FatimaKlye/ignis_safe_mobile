import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'localization/language_controller.dart';
import 'network_error_helper.dart';
import 'widgets/app_notification.dart';
import 'widgets/password_changed_dialog.dart';
import 'widgets/password_requirements.dart';

/// Where [ForgotPassPage] was opened from. Profile keeps the signed-in email
/// fixed and both entry points use a top-left back action.
enum ForgotPassEntrySource { login, profile }

class ForgotPassPage extends StatefulWidget {
  const ForgotPassPage({
    super.key,
    this.entrySource = ForgotPassEntrySource.login,
  });

  final ForgotPassEntrySource entrySource;

  @override
  State<ForgotPassPage> createState() => _ForgotPassPageState();
}

enum _ForgotStage { email, otp, password }

class _ForgotPassPageState extends State<ForgotPassPage> {
  static const Color brandRed = Color(0xFFB71C1C);

  final _formKey = GlobalKey<FormState>();
  final SupabaseClient supabase = Supabase.instance.client;

  final _emailCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  _ForgotStage _stage = _ForgotStage.email;

  bool _isLoading = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  bool get _isProfileMode =>
      widget.entrySource == ForgotPassEntrySource.profile;

  /// In Profile mode the reset is locked to the signed-in account so the
  /// recovery OTP can never switch the session to a different user.
  String? get _sessionEmail => supabase.auth.currentUser?.email;

  @override
  void initState() {
    super.initState();
    if (_isProfileMode) {
      _emailCtrl.text = _sessionEmail ?? '';
    }
    _newPasswordCtrl.addListener(_onNewPasswordChanged);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    _newPasswordCtrl.removeListener(_onNewPasswordChanged);
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
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

  String _authErrorMessage(String message) {
    final isTl = Localizations.localeOf(context).languageCode == 'tl';
    if (!isTl) return message;

    final lower = message.toLowerCase();
    if (lower.contains('expired') || lower.contains('invalid')) {
      return 'Hindi wasto o paso na ang OTP. Pakisubukang muli.';
    }
    if (lower.contains('rate') || lower.contains('too many')) {
      return 'Masyadong maraming pagsubok. Maghintay sandali bago subukang muli.';
    }
    if (lower.contains('email')) {
      return 'Pakisuri ang email address at subukang muli.';
    }
    if (lower.contains('password')) {
      return 'Hindi ma-update ang password. Pakisuri ang bagong password at subukang muli.';
    }
    return 'May problema sa authentication. Pakisubukang muli.';
  }

  Future<bool> _accountExistsForPasswordReset(String email) async {
    final normalizedEmail = email.trim().toLowerCase();

    // Recommended: create the SQL RPC function shown below this file.
    // This checks Supabase Auth securely from the database side.
    try {
      final result = await supabase.rpc(
        'account_exists_for_password_reset',
        params: {'p_email': normalizedEmail},
      );

      if (result is bool) return result;
      if (result is String) return result.toLowerCase() == 'true';
      if (result is num) return result == 1;
    } on PostgrestException {
      // If the RPC is not installed yet, fall back to the profiles table.
      // Keep the fallback so existing projects can still work while setting up SQL.
    } catch (e) {
      if (isNetworkError(e)) {
        return false;
      }
      return false;
    }

    try {
      final rows = await supabase
          .from('profiles')
          .select('id')
          .eq('email', normalizedEmail)
          .limit(1);

      return rows.isNotEmpty;
    } on PostgrestException {
      // Do not send a reset OTP when the app cannot verify the account.
      return false;
    } catch (e) {
      if (isNetworkError(e)) {
        return false;
      }
      return false;
    }
  }

  Future<void> _showAccountNotFoundDialog() async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            t(context, 'Account not found', 'Hindi nahanap ang account'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            t(
              context,
              'This email is not registered in our app. Please check the email or create an account first.',
              'Hindi rehistrado ang email na ito sa aming app. Pakisuri ang email o gumawa muna ng account.',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'Poppins', height: 1.4),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                t(context, 'Try Again', 'Subukang Muli'),
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  color: brandRed,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String? _validateEmail(String? value) {
    final email = (value ?? '').trim().toLowerCase();
    if (email.isEmpty) {
      return t(
        context,
        'Please enter your email.',
        'Mangyaring ilagay ang iyong email.',
      );
    }
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@gmail\.com$');
    if (!emailRegex.hasMatch(email)) {
      return t(
        context,
        'Please enter a valid Gmail address.',
        'Mangyaring maglagay ng wastong Gmail address.',
      );
    }
    return null;
  }

  String? _validateOtp(String? value) {
    final otp = value?.trim() ?? '';
    if (otp.isEmpty)
      return t(context, 'Please enter the OTP.', 'Mangyaring ilagay ang OTP.');
    if (otp.length != 6)
      return t(
        context,
        'OTP must be 6 digits.',
        'Ang OTP ay dapat 6 na digit.',
      );
    return null;
  }

  /// Rebuilds the password requirements checklist while the user types.
  void _onNewPasswordChanged() {
    if (mounted) setState(() {});
  }

  /// Checked against the trimmed value because that is what gets saved.
  PasswordRules get _newPasswordRules =>
      PasswordRules.check(_newPasswordCtrl.text.trim());

  String? _validatePassword(String? value) {
    final password = value?.trim() ?? '';
    if (password.isEmpty) {
      return t(
        context,
        'Please enter a new password.',
        'Mangyaring maglagay ng bagong password.',
      );
    }
    if (!PasswordRules.check(password).allPassed) {
      return t(
        context,
        'Password does not meet all requirements',
        'Hindi natutugunan ng password ang lahat ng kinakailangan',
      );
    }
    return null;
  }

  Future<void> _sendOtp() async {
    if (_isProfileMode) {
      _emailCtrl.text = _sessionEmail ?? '';
    }

    final emailError = _validateEmail(_emailCtrl.text);
    if (emailError != null) {
      _notify(context, message: emailError, type: AppNotificationType.error);
      return;
    }

    final email = _emailCtrl.text.trim().toLowerCase();

    setState(() => _isLoading = true);

    try {
      final accountExists = await _accountExistsForPasswordReset(email);

      if (!mounted) return;

      if (!accountExists) {
        await _showAccountNotFoundDialog();
        return;
      }

      await supabase.auth.resetPasswordForEmail(email);

      if (!mounted) return;

      setState(() => _stage = _ForgotStage.otp);

      _notify(
        context,
        message: t(
          context,
          'OTP sent to your email. Please check your inbox.',
          'Naipadala ang OTP sa iyong email. Pakitingnan ang iyong inbox.',
        ),
        type: AppNotificationType.success,
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      _notify(
        context,
        message: _authErrorMessage(e.message),
        type: AppNotificationType.error,
      );
    } catch (e) {
      if (!mounted) return;
      if (isNetworkError(e)) {
        await showNoInternetDialog(context);
      } else {
        _notify(
          context,
          message: t(
            context,
            'Failed to send OTP. Please try again.',
            'Hindi naipadala ang OTP. Pakisubukang muli.',
          ),
          type: AppNotificationType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    final otpError = _validateOtp(_otpCtrl.text);
    if (otpError != null) {
      _notify(context, message: otpError, type: AppNotificationType.error);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await supabase.auth.verifyOTP(
        email: _emailCtrl.text.trim(),
        token: _otpCtrl.text.trim(),
        type: OtpType.recovery,
      );

      final hasSession =
          response.session != null || supabase.auth.currentSession != null;

      if (!hasSession) {
        throw Exception(
          t(
            context,
            'OTP verification did not create a session.',
            'Ang pag-verify ng OTP ay hindi nakagawa ng session.',
          ),
        );
      }

      if (!mounted) return;

      setState(() => _stage = _ForgotStage.password);

      _notify(
        context,
        message: t(
          context,
          'OTP verified. You can now set a new password.',
          'Naverify na ang OTP. Maaari ka nang magtakda ng bagong password.',
        ),
        type: AppNotificationType.success,
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      _notify(
        context,
        message: _authErrorMessage(e.message),
        type: AppNotificationType.error,
      );
    } catch (e) {
      if (!mounted) return;
      if (isNetworkError(e)) {
        await showNoInternetDialog(context);
      } else {
        _notify(
          context,
          message: t(
            context,
            'Invalid or expired OTP.',
            'Hindi wasto o paso na ang OTP.',
          ),
          type: AppNotificationType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Signs out after a successful password update. Never throws: gotrue clears
  /// the local session before calling the server, so a failed server-side
  /// revoke must not be reported as a failed password update.
  Future<void> _signOutAfterPasswordChange() async {
    try {
      await supabase.auth.signOut();
    } catch (e) {
      debugPrint('Sign out after password change failed: $e');
    }
  }

  Future<void> _updatePassword() async {
    final passwordError = _validatePassword(_newPasswordCtrl.text);
    if (passwordError != null) {
      _notify(context, message: passwordError, type: AppNotificationType.error);
      return;
    }

    if (_confirmPasswordCtrl.text.trim().isEmpty) {
      _notify(
        context,
        message: t(
          context,
          'Please confirm your password.',
          'Mangyaring kumpirmahin ang iyong password.',
        ),
        type: AppNotificationType.error,
      );
      return;
    }

    if (_newPasswordCtrl.text.trim() != _confirmPasswordCtrl.text.trim()) {
      _notify(
        context,
        message: t(
          context,
          'Passwords do not match.',
          'Hindi magkatugma ang mga password.',
        ),
        type: AppNotificationType.error,
      );
      return;
    }

    setState(() => _isLoading = true);

    // Captured before the async gap so the post-update modal and redirect
    // still run even if this route is dismissed while the request is in flight.
    final navigator = Navigator.of(context, rootNavigator: true);

    var passwordUpdated = false;
    try {
      await supabase.auth.updateUser(
        UserAttributes(password: _newPasswordCtrl.text.trim()),
      );
      passwordUpdated = true;
    } on AuthException catch (e) {
      if (!mounted) return;
      _notify(
        context,
        message: _authErrorMessage(e.message),
        type: AppNotificationType.error,
      );
    } catch (e) {
      if (!mounted) return;
      if (isNetworkError(e)) {
        await showNoInternetDialog(context);
      } else {
        _notify(
          context,
          message: t(
            context,
            'Unable to update password.',
            'Hindi ma-update ang password.',
          ),
          type: AppNotificationType.error,
        );
      }
    } finally {
      // On success the page stays locked until the stack is replaced below.
      if (mounted && !passwordUpdated) setState(() => _isLoading = false);
    }

    if (!passwordUpdated) return;

    // Password changed: show the modal, then end the session for both Login
    // and Profile entry points and clear the stack so Back cannot return to
    // Profile/Home.
    await showPasswordChangedAndLogout(
      navigator,
      signOut: _signOutAfterPasswordChange,
    );
  }

  Widget _buildEmailStep() {
    return Column(
      children: [
        Text(
          _isProfileMode
              ? t(context,
                  'For your security, we will send a verification code to your account email before changing your password.',
                  'Para sa iyong seguridad, magpapadala kami ng verification code sa email ng iyong account bago palitan ang password.')
              : t(context,
                  'Enter your registered email address and we will send you a password reset OTP.',
                  'Ilagay ang iyong rehistradong email address at padadalhan ka namin ng OTP para sa pag-reset ng password.'),
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
          controller: _emailCtrl,
          readOnly: _isProfileMode,
          keyboardType: TextInputType.emailAddress,
          validator: _validateEmail,
          decoration: InputDecoration(
            labelText: t(context, 'Email', 'Email'),
            hintText: t(context, 'Enter your email', 'Ilagay ang iyong email'),
            prefixIcon: const Icon(Icons.email_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.black12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: brandRed, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _sendOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: brandRed,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    t(context, 'Send OTP', 'Ipadala ang OTP'),
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpStep() {
    return Column(
      children: [
        Text(
          t(
            context,
            'We sent a 6-digit OTP to ${_emailCtrl.text.trim()}.',
            'Nagpadala kami ng 6-digit OTP sa ${_emailCtrl.text.trim()}.',
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: Colors.black54,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),
        TextFormField(
          controller: _otpCtrl,
          validator: _validateOtp,
          keyboardType: TextInputType.number,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: 8,
          ),
          decoration: InputDecoration(
            counterText: '',
            labelText: t(context, 'OTP Code', 'Code ng OTP'),
            hintText: '------',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.black12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: brandRed, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _verifyOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: brandRed,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    t(context, 'Verify OTP', 'I-verify ang OTP'),
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
          onPressed: _isLoading ? null : _sendOtp,
          child: Text(
            t(context, 'Resend OTP', 'Ipadala muli ang OTP'),
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              color: brandRed,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordStep() {
    return Column(
      children: [
        Text(
          t(
            context,
            'Enter your new password.',
            'Ilagay ang bago mong password.',
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
          controller: _newPasswordCtrl,
          obscureText: !_showNewPassword,
          validator: _validatePassword,
          decoration: InputDecoration(
            labelText: t(context, 'New Password', 'Bagong Password'),
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _showNewPassword ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () {
                setState(() => _showNewPassword = !_showNewPassword);
              },
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.black12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: brandRed, width: 1.5),
            ),
          ),
        ),
        PasswordRequirementsCard(
          rules: _newPasswordRules,
          visible: _newPasswordCtrl.text.isNotEmpty,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _confirmPasswordCtrl,
          obscureText: !_showConfirmPassword,
          decoration: InputDecoration(
            labelText: t(
              context,
              'Confirm Password',
              'Kumpirmahin ang Password',
            ),
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _showConfirmPassword ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () {
                setState(() => _showConfirmPassword = !_showConfirmPassword);
              },
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.black12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: brandRed, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _updatePassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: brandRed,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    t(context, 'Update Password', 'I-update ang Password'),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    String title = _isProfileMode
        ? t(context, 'Change Password', 'Palitan ang Password')
        : t(context, 'Forgot Password', 'Nakalimutan ang Password');
    if (_stage == _ForgotStage.otp) {
      title = _isProfileMode
          ? t(context, 'Verify Your Email', 'I-verify ang Iyong Email')
          : t(context, 'Verify OTP', 'I-verify ang OTP');
    }
    if (_stage == _ForgotStage.password) {
      title = _isProfileMode
          ? t(context, 'Change Password', 'Palitan ang Password')
          : t(context, 'Reset Password', 'I-reset ang Password');
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 35.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 70,
                                  bottom: 30,
                                ),
                                child: SizedBox(
                                  height: 120,
                                  child: FittedBox(
                                    fit: BoxFit.contain,
                                    child: Image.asset('assets/logo.png'),
                                  ),
                                ),
                              ),
                              Text(
                                title,
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
                              const SizedBox(height: 12),

                              if (_stage == _ForgotStage.email)
                                _buildEmailStep(),
                              if (_stage == _ForgotStage.otp) _buildOtpStep(),
                              if (_stage == _ForgotStage.password)
                                _buildPasswordStep(),

                              const SizedBox(height: 18),

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
            Positioned(
              left: 18,
              top: 8,
              child: IconButton(
                tooltip: t(context, 'Back', 'Bumalik'),
                onPressed: _isLoading ? null : () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded, color: brandRed),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
