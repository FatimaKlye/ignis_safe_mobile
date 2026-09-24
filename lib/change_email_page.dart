import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'localization/language_controller.dart';
import 'network_error_helper.dart';
import 'widgets/app_notification.dart';
import 'widgets/email_changed_dialog.dart';
import 'widgets/top_close_button.dart';

/// Dedicated Change Email flow, opened from Profile > Edit Profile > Security.
/// Mirrors the staged email -> OTP pattern used by ForgotPassPage so the
/// two flows feel consistent, but confirms the new address via Supabase's
/// `emailChange` OTP instead of the `recovery` OTP.
///
/// With Supabase "Secure email change" enabled, the change only completes
/// after BOTH addresses are confirmed: one code goes to the new email and a
/// different code goes to the current email. Each code is verified against
/// the address it was sent to. The first accepted code returns no session,
/// so the page then asks for the second code.
class ChangeEmailPage extends StatefulWidget {
  const ChangeEmailPage({super.key});

  @override
  State<ChangeEmailPage> createState() => _ChangeEmailPageState();
}

enum _ChangeEmailStage { email, otp }

/// Which inbox the code currently being entered was sent to.
enum _OtpTarget { newEmail, currentEmail }

class _ChangeEmailPageState extends State<ChangeEmailPage> {
  static const Color brandRed = Color(0xFFB71C1C);

  /// gotrue throws a plain [AuthException] with this message (and no HTTP
  /// status) when `/verify` succeeds but returns no session. For
  /// `email_change` that is the Secure Email Change response meaning "this
  /// code was accepted, now confirm the other address".
  static const String _awaitingOtherConfirmationMessage =
      'An error occurred on token verification.';

  final _formKey = GlobalKey<FormState>();
  final SupabaseClient supabase = Supabase.instance.client;

  final _emailCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();

  _ChangeEmailStage _stage = _ChangeEmailStage.email;
  bool _isLoading = false;
  String? _pendingEmail;
  String? _currentEmail;
  _OtpTarget _otpTarget = _OtpTarget.newEmail;

  /// Set once the server has accepted one code but still needs the other,
  /// which means Secure Email Change is enabled on the project.
  bool _requiresBothConfirmations = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _otpCtrl.dispose();
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
    if (lower.contains('registered') || lower.contains('already')) {
      return 'Ginagamit na ang email na ito ng ibang account.';
    }
    if (lower.contains('email')) {
      return 'Pakisuri ang email address at subukang muli.';
    }
    return 'May problema sa authentication. Pakisubukang muli.';
  }

  String? _validateEmail(String? value) {
    final email = (value ?? '').trim().toLowerCase();
    if (email.isEmpty) {
      return t(
        context,
        'Please enter your new email.',
        'Mangyaring ilagay ang iyong bagong email.',
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
    final currentEmail = supabase.auth.currentUser?.email?.trim().toLowerCase();
    if (currentEmail != null && email == currentEmail) {
      return t(
        context,
        'This is already your current email address.',
        'Ito na ang kasalukuyan mong email address.',
      );
    }
    return null;
  }

  String? _validateOtp(String? value) {
    final otp = value?.trim() ?? '';
    if (otp.isEmpty) {
      return t(context, 'Please enter the OTP.', 'Mangyaring ilagay ang OTP.');
    }
    if (otp.length != 6) {
      return t(
        context,
        'OTP must be 6 digits.',
        'Ang OTP ay dapat 6 na digit.',
      );
    }
    return null;
  }

  bool _isInvalidOrExpiredOtp(AuthException e) {
    if (e.code == 'otp_expired') return true;
    final lower = e.message.toLowerCase();
    return lower.contains('expired') || lower.contains('invalid');
  }

  /// True when gotrue reports a successful `/verify` that returned no
  /// session, i.e. Secure Email Change accepted this code and is waiting for
  /// the code sent to the other address. Real verification failures come back
  /// as [AuthApiException] with an HTTP status.
  bool _isAwaitingOtherConfirmation(AuthException e) {
    return e.runtimeType == AuthException &&
        e.statusCode == null &&
        e.message == _awaitingOtherConfirmationMessage;
  }

  Future<void> _sendOtp() async {
    final emailError = _validateEmail(_emailCtrl.text);
    if (emailError != null) {
      _notify(context, message: emailError, type: AppNotificationType.error);
      return;
    }

    final currentEmail = supabase.auth.currentUser?.email?.trim().toLowerCase();
    if (currentEmail == null || currentEmail.isEmpty) {
      _notify(
        context,
        message: t(
          context,
          'Your session has expired. Please log in again.',
          'Nag-expire na ang iyong session. Mangyaring mag-log in muli.',
        ),
        type: AppNotificationType.error,
      );
      return;
    }

    final newEmail = _emailCtrl.text.trim().toLowerCase();

    setState(() => _isLoading = true);

    try {
      // Only requests the change: auth.users.email stays the same until the
      // required code(s) are verified, so nothing displayed changes yet.
      await supabase.auth.updateUser(UserAttributes(email: newEmail));

      if (!mounted) return;

      _otpCtrl.clear();
      setState(() {
        _pendingEmail = newEmail;
        _currentEmail = currentEmail;
        _otpTarget = _OtpTarget.newEmail;
        _stage = _ChangeEmailStage.otp;
      });

      _notify(
        context,
        message: t(
          context,
          'OTP sent to your new email. Please check your inbox.',
          'Naipadala ang OTP sa iyong bagong email. Pakitingnan ang iyong inbox.',
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

  /// Resends the pending email-change codes. For `email_change` resends,
  /// Supabase looks the user up by their CURRENT email and mails fresh codes
  /// to the pending address (and to the current one when Secure Email Change
  /// is on). Fresh codes also reset any half-finished confirmation, so the
  /// flow restarts at the new-email code.
  Future<void> _resendOtp() async {
    final currentEmail = _currentEmail;
    final newEmail = _pendingEmail;
    if (currentEmail == null || newEmail == null) return;

    setState(() => _isLoading = true);

    try {
      await supabase.auth.resend(
        type: OtpType.emailChange,
        email: currentEmail,
      );

      if (!mounted) return;

      _otpCtrl.clear();
      setState(() => _otpTarget = _OtpTarget.newEmail);

      _notify(
        context,
        message: _requiresBothConfirmations
            ? t(
                context,
                'New OTPs sent to $newEmail and $currentEmail. Earlier codes no longer work.',
                'Naipadala ang mga bagong OTP sa $newEmail at $currentEmail. Hindi na gagana ang mga naunang code.',
              )
            : t(
                context,
                'A new OTP was sent to $newEmail. Earlier codes no longer work.',
                'Naipadala ang bagong OTP sa $newEmail. Hindi na gagana ang mga naunang code.',
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
            'Failed to resend OTP. Please try again.',
            'Hindi naipadala muli ang OTP. Pakisubukang muli.',
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

    final newEmail = _pendingEmail;
    final currentEmail = _currentEmail;
    if (newEmail == null || currentEmail == null) return;

    // Supabase hashes each email-change code with the address it was sent
    // to, so each code must be verified against that same address.
    final verifyEmail = _otpTarget == _OtpTarget.newEmail
        ? newEmail
        : currentEmail;

    // Captured before the async gap so the post-change logout still runs even
    // if this route is popped while the code is being verified.
    final navigator = Navigator.of(context, rootNavigator: true);

    setState(() => _isLoading = true);

    // Set only once Supabase confirms the change is fully complete.
    String? changedEmail;
    try {
      await supabase.auth.verifyOTP(
        email: verifyEmail,
        token: _otpCtrl.text.trim(),
        type: OtpType.emailChange,
      );

      // Every required confirmation is done. Read the user back from the
      // server so success is only reported once auth.users really holds the
      // new address.
      final refreshed = await supabase.auth.getUser();
      final user = refreshed.user;
      final confirmedEmail = user?.email?.trim().toLowerCase();

      if (user == null || confirmedEmail != newEmail) {
        if (!mounted) return;
        _notify(
          context,
          message: t(
            context,
            'Your email could not be updated. Please tap Resend OTP and try again.',
            'Hindi na-update ang iyong email. Pakipindot ang Ipadala muli ang OTP at subukang muli.',
          ),
          type: AppNotificationType.error,
        );
        return;
      }

      await _syncProfileEmail(user.id, newEmail);
      changedEmail = newEmail;
    } on AuthException catch (e) {
      if (!mounted) return;

      if (_isAwaitingOtherConfirmation(e)) {
        // Secure Email Change: this code was accepted, but the other address
        // still has to be confirmed before the email actually changes.
        final nextTarget = _otpTarget == _OtpTarget.newEmail
            ? _OtpTarget.currentEmail
            : _OtpTarget.newEmail;
        _otpCtrl.clear();
        setState(() {
          _requiresBothConfirmations = true;
          _otpTarget = nextTarget;
        });
        _notify(
          context,
          title: t(context, 'Code Accepted', 'Tinanggap ang Code'),
          message: nextTarget == _OtpTarget.currentEmail
              ? t(
                  context,
                  'For your security, also enter the OTP sent to your current email, $currentEmail.',
                  'Para sa iyong seguridad, ilagay din ang OTP na ipinadala sa iyong kasalukuyang email, $currentEmail.',
                )
              : t(
                  context,
                  'Now enter the OTP sent to your new email, $newEmail.',
                  'Ngayon, ilagay ang OTP na ipinadala sa iyong bagong email, $newEmail.',
                ),
          type: AppNotificationType.success,
        );
        return;
      }

      _notify(
        context,
        message: _isInvalidOrExpiredOtp(e)
            ? t(
                context,
                'Invalid or expired OTP. Please check the latest code in your email or tap Resend OTP.',
                'Hindi wasto o paso na ang OTP. Pakitingnan ang pinakabagong code sa iyong email o pindutin ang Ipadala muli ang OTP.',
              )
            : _authErrorMessage(e.message),
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
            'Could not verify the OTP. Please try again.',
            'Hindi ma-verify ang OTP. Pakisubukang muli.',
          ),
          type: AppNotificationType.error,
        );
      }
    } finally {
      // On success the page stays locked until the stack is replaced below.
      if (mounted && changedEmail == null) {
        setState(() => _isLoading = false);
      }
    }

    if (changedEmail == null) return;

    // Email change fully confirmed: show the modal, end the session and clear
    // the stack so Back cannot return to Profile/Home. The user must log in
    // again with the new email.
    await showEmailChangedAndLogout(
      navigator,
      newEmail: changedEmail,
      signOut: _signOutAfterEmailChange,
    );
  }

  Future<void> _signOutAfterEmailChange() async {
    try {
      await supabase.auth.signOut();
    } catch (e) {
      debugPrint('Sign out after email change failed: $e');
    }
  }

  /// Mirrors the confirmed auth email into `profiles.email`, which the
  /// profile screens display. Runs only after verification succeeded. The
  /// auth change is already final by then, so a failure here is logged
  /// rather than reported as a failed email change.
  Future<void> _syncProfileEmail(String userId, String newEmail) async {
    try {
      await supabase
          .from('profiles')
          .update({
            'email': newEmail,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', userId);
    } catch (e) {
      debugPrint('Failed to sync profiles.email after email change: $e');
    }
  }

  Widget _buildEmailStep() {
    return Column(
      children: [
        Text(
          t(
            context,
            'Enter your new email address and we will send you a verification OTP.',
            'Ilagay ang iyong bagong email address at padadalhan ka namin ng OTP para sa pag-verify.',
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
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          validator: _validateEmail,
          decoration: InputDecoration(
            labelText: t(context, 'New Email', 'Bagong Email'),
            hintText: t(
              context,
              'Enter your new email',
              'Ilagay ang iyong bagong email',
            ),
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
          height: 54,
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

  Widget _buildOtpStep() {
    final newEmail = _pendingEmail ?? _emailCtrl.text.trim();
    final currentEmail = _currentEmail ?? '';
    final String description;
    if (_otpTarget == _OtpTarget.currentEmail) {
      description = t(
        context,
        'Your new email is confirmed. For your security, enter the 6-digit OTP we sent to your current email, $currentEmail.',
        'Nakumpirma na ang iyong bagong email. Para sa iyong seguridad, ilagay ang 6-digit OTP na ipinadala namin sa iyong kasalukuyang email, $currentEmail.',
      );
    } else if (_requiresBothConfirmations) {
      description = t(
        context,
        'Enter the 6-digit OTP we sent to your new email, $newEmail. You will then confirm your current email too.',
        'Ilagay ang 6-digit OTP na ipinadala namin sa iyong bagong email, $newEmail. Pagkatapos, kukumpirmahin mo rin ang iyong kasalukuyang email.',
      );
    } else {
      description = t(
        context,
        'We sent a 6-digit OTP to $newEmail.',
        'Nagpadala kami ng 6-digit OTP sa $newEmail.',
      );
    }

    return Column(
      children: [
        Text(
          description,
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
          height: 54,
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
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _isLoading ? null : _resendOtp,
          child: Text(
            t(context, 'Resend OTP', 'Ipadala muli ang OTP'),
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              color: brandRed,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    String title = t(context, 'Change Email', 'Palitan ang Email');
    if (_stage == _ChangeEmailStage.otp) {
      title = _otpTarget == _OtpTarget.currentEmail
          ? t(
              context,
              'Verify Current Email',
              'I-verify ang Kasalukuyang Email',
            )
          : t(context, 'Verify New Email', 'I-verify ang Bagong Email');
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

                              if (_stage == _ChangeEmailStage.email)
                                _buildEmailStep(),
                              if (_stage == _ChangeEmailStage.otp)
                                _buildOtpStep(),

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
            // Close back to Edit Profile. Only pops this route, so the
            // signed-in session stays untouched.
            TopCloseButtonOverlay(
              color: brandRed,
              onTap: _isLoading ? null : () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
