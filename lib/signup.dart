import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'localization/language_controller.dart';
import 'forgotpass.dart';
import 'login.dart';
import 'verifyemail.dart';
import 'network_error_helper.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  static const Color brandRed = Color(0xFFB71C1C);

  final SupabaseClient supabase = Supabase.instance.client;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  static final RegExp _namePattern = RegExp(
    r"^[A-Za-zÀ-ÖØ-öø-ÿÑñ]+(?:[ '\-.][A-Za-zÀ-ÖØ-öø-ÿÑñ]+)*$",
  );

  final TextEditingController fullNameCtrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();
  final TextEditingController confirmPassCtrl = TextEditingController();

  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  bool _min8 = false;
  bool _hasNumber = false;
  bool _hasSymbol = false;
  bool _hasUpper = false;
  bool _matches = false;

  @override
  void initState() {
    super.initState();
    passCtrl.addListener(_recalculatePasswordRules);
    confirmPassCtrl.addListener(_recalculatePasswordRules);
  }

  @override
  void dispose() {
    fullNameCtrl.dispose();
    emailCtrl.dispose();
    passCtrl.removeListener(_recalculatePasswordRules);
    confirmPassCtrl.removeListener(_recalculatePasswordRules);
    passCtrl.dispose();
    confirmPassCtrl.dispose();
    super.dispose();
  }

  void _recalculatePasswordRules() {
    final password = passCtrl.text;
    final confirm = confirmPassCtrl.text;

    final min8 = password.length >= 8;
    final hasNumber = RegExp(r'\d').hasMatch(password);
    final hasSymbol = RegExp(
      r'[!@#$%^&*(),.?":{}|<>_\-\[\]\\/~`+=;]',
    ).hasMatch(password);
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
    } else if (mounted) {
      setState(() {});
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

  bool get _passwordStarted => passCtrl.text.isNotEmpty;
  bool get _confirmPasswordVisible => _passwordStarted;
  bool get _passwordRulesPassed => _passedRules == 4;
  bool get _allPasswordOk => _passwordRulesPassed && _matches;

  double get _passwordProgress {
    if (!_passwordStarted) return 0.0;
    return _passedRules / 4.0;
  }

  Color get _passwordBarColor {
    if (!_passwordStarted) return const Color(0xFFD32F2F);
    if (_passedRules < 3) return const Color(0xFFF9A825);
    return const Color(0xFF2E7D32);
  }

  String get _passwordStrengthText {
    if (!_passwordStarted || _passedRules <= 1) {
      return t(context, 'Password is weak', 'Mahina ang password');
    }
    if (_passedRules <= 3) {
      return t(context, 'Password is medium', 'Katamtaman ang password');
    }
    return t(context, 'Password is strong', 'Malakas ang password');
  }

  Color get _passwordStrengthColor {
    if (!_passwordStarted || _passedRules <= 1) return const Color(0xFFD32F2F);
    if (_passedRules <= 3) return const Color(0xFFF9A825);
    return const Color(0xFF2E7D32);
  }

  String? _validateFullName(String? v) {
    final value = (v ?? '').trim().replaceAll(RegExp(r'\s+'), ' ');
    if (value.isEmpty) {
      return t(
        context,
        'Full name is required',
        'Kailangan ang buong pangalan',
      );
    }
    if (!_namePattern.hasMatch(value)) {
      return t(
        context,
        'Full name should contain letters only',
        'Ang buong pangalan ay dapat letra lamang',
      );
    }
    return null;
  }

  String? _validateEmail(String? v) {
    final value = (v ?? '').trim().toLowerCase();
    if (value.isEmpty) {
      return t(context, 'Email is required', 'Kailangan ang email');
    }
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@gmail\.com$');
    if (!emailRegex.hasMatch(value)) {
      return t(
        context,
        'Enter a valid Gmail address',
        'Maglagay ng wastong Gmail address',
      );
    }
    return null;
  }

  String? _validatePassword(String? v) {
    final value = v ?? '';
    if (value.isEmpty) {
      return t(context, 'Password is required', 'Kailangan ang password');
    }
    if (!_passwordRulesPassed) {
      return t(
        context,
        'Password does not meet all requirements',
        'Hindi natutugunan ng password ang lahat ng kinakailangan',
      );
    }
    return null;
  }

  String? _validateConfirmPassword(String? v) {
    final value = v ?? '';
    if (!_confirmPasswordVisible) return null;
    if (value.isEmpty) {
      return t(
        context,
        'Confirm your password',
        'Kumpirmahin ang iyong password',
      );
    }
    if (value != passCtrl.text) {
      return t(
        context,
        'Passwords do not match',
        'Hindi magkatugma ang mga password',
      );
    }
    return null;
  }

  ({String firstName, String lastName}) _splitFullName(String fullName) {
    final normalized = fullName.trim().replaceAll(RegExp(r'\s+'), ' ');
    final parts = normalized.split(' ');

    if (parts.length == 1) {
      return (firstName: parts.first, lastName: '');
    }

    return (firstName: parts.first, lastName: parts.sublist(1).join(' '));
  }

  // Possible Edge Function status values:
  // not_found | pending_email_verification | pending_password_setup | completed | expired
  Future<String> _getRegistrationStatus(String email) async {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty) return 'not_found';

    try {
      final res = await supabase.functions.invoke(
        'check_email_status',
        body: {'email': normalized},
      );

      final data = res.data;
      final rawStatus = (data is Map && data['status'] is String)
          ? data['status'] as String
          : 'not_found';

      switch (rawStatus) {
        case 'existing':
        case 'completed':
          return 'completed';
        case 'pending_email_verification':
        case 'pending_password_setup':
        case 'expired':
          return rawStatus;
        case 'not_found':
        default:
          return 'not_found';
      }
    } catch (e) {
      debugPrint('check_email_status failed: $e');
      return 'not_found';
    }
  }

  Future<void> _cleanupPendingRegistration(String email) async {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty) return;

    try {
      await supabase.functions.invoke(
        'cancel_pending_signup_email',
        body: {'email': normalized},
      );
    } catch (e) {
      // Best-effort only. If this fails, the next sign-up attempt will still
      // be guarded by Supabase and the user will see a clear message.
      debugPrint('cancel_pending_signup_email failed: $e');
    }

    try {
      await supabase.auth.signOut();
    } catch (e) {
      debugPrint('signOut during cleanup failed: $e');
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

  Future<bool> _showConfirmEmailDialog(String email) async {
    if (!mounted) return false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
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
                    onTap: () => Navigator.pop(dialogContext, false),
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
                  child: const Icon(
                    Icons.mark_email_read_rounded,
                    color: brandRed,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  t(
                    context,
                    'Confirm Your Email',
                    'Kumpirmahin ang Iyong Email',
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                    height: 1.15,
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
                  email,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  t(
                    context,
                    'Make sure this email is correct. The verification code will be sent here, and this email will be used for your IGNIS SAFE account.',
                    'Siguraduhing tama ang email na ito. Dito ipapadala ang verification code, at ito ang gagamitin para sa iyong IGNIS SAFE account.',
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
                    onPressed: () => Navigator.pop(dialogContext, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandRed,
                      elevation: 4,
                      shadowColor: brandRed.withOpacity(0.35),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      t(context, 'Continue', 'Magpatuloy'),
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: Text(
                    t(context, 'Edit Email', 'Baguhin ang Email'),
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.black.withOpacity(0.45),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    return result ?? false;
  }

  void _showExistingAccountDialog(String email) {
    showDialog(
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
                  child: const Icon(
                    Icons.mark_email_read_rounded,
                    color: brandRed,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  t(
                    context,
                    'Email Already Registered',
                    'May Account na ang Email',
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                    height: 1.15,
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
                  email,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  t(
                    context,
                    'This email is already linked to an existing IGNIS SAFE account.',
                    'Ang email na ito ay nakakonekta na sa isang existing na IGNIS SAFE account.',
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: Colors.black.withOpacity(0.55),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      LoginPage.skipAutoRoute = false;
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                        (route) => false,
                      );
                    },
                    icon: const Icon(
                      Icons.login_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                    label: Text(
                      t(context, 'Go to Login', 'Pumunta sa Login'),
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandRed,
                      elevation: 4,
                      shadowColor: brandRed.withOpacity(0.35),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ForgotPassPage()),
                    );
                  },
                  child: Text(
                    t(context, 'Forgot Password?', 'Nakalimutan ang Password?'),
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.black.withOpacity(0.45),
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

  Future<void> _continueToVerifyEmail() async {
    if (_isLoading) return;

    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok || !_allPasswordOk) {
      await _showNoticeDialog(
        title: t(context, 'Check Your Details', 'Suriin ang Iyong Detalye'),
        message: t(
          context,
          'Complete the full name, Gmail address, password requirements, and confirm password before verifying your email.',
          'Kumpletuhin ang buong pangalan, Gmail address, mga kailangan sa password, at kumpirmasyon ng password bago i-verify ang email.',
        ),
      );
      return;
    }

    final fullName = fullNameCtrl.text.trim().replaceAll(RegExp(r'\s+'), ' ');
    final email = emailCtrl.text.trim().toLowerCase();
    final password = passCtrl.text;
    final splitName = _splitFullName(fullName);

    final confirmed = await _showConfirmEmailDialog(email);
    if (!confirmed) return;

    setState(() => _isLoading = true);

    try {
      final status = await _getRegistrationStatus(email);

      if (!mounted) return;

      if (status == 'completed') {
        _showExistingAccountDialog(email);
        return;
      }

      // A pending, unconfirmed signup is resumed rather than recreated:
      // navigating straight to VerifyEmailPage lets the user continue
      // verifying the same account (Supabase treats a repeat signUp() on an
      // unconfirmed email as a resend, not a new account). Only a truly
      // expired pending record (>24h, see get_registration_status) is
      // cleared out so the user can start fresh.
      if (status == 'expired') {
        await _cleanupPendingRegistration(email);
      }

      if (!mounted) return;

      LoginPage.skipAutoRoute = true;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VerifyEmailPage(
            email: email,
            firstName: splitName.firstName,
            lastName: splitName.lastName,
            password: password,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      if (isNetworkError(e)) {
        await showNoInternetDialog(context);
      } else {
        await _showNoticeDialog(
          title: t(context, 'Could Not Continue', 'Hindi Makapagpatuloy'),
          message: t(
            context,
            'Could not check this email. Please try again.',
            'Hindi masuri ang email na ito. Subukang muli.',
          ),
        );
      }
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
    bool obscureText = false,
    Widget? suffixIcon,
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
                obscureText: obscureText,
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
                  suffixIcon: suffixIcon,
                ),
              ),
            ),
            if (state.errorText != null)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 10),
                child: Text(
                  state.errorText!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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

  Widget _visibilitySuffix({
    required bool visible,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Text(
          visible ? t(context, 'HIDE', 'ITAGO') : t(context, 'SHOW', 'IPAKITA'),
          style: const TextStyle(
            fontFamily: 'Poppins',
            color: brandRed,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _ruleItem(String text, bool passed) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          passed ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 16,
          color: passed ? const Color(0xFF2E7D32) : Colors.black38,
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            color: passed ? const Color(0xFF2E7D32) : Colors.black54,
            fontWeight: passed ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordValidationCard() {
    if (!_passwordStarted) return const SizedBox.shrink();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFEAEAEA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                t(context, 'Password strength', 'Lakas ng password'),
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              Text(
                _passwordStrengthText,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _passwordStrengthColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: _passwordProgress,
              minHeight: 7,
              backgroundColor: const Color(0xFFE6E6E6),
              valueColor: AlwaysStoppedAnimation<Color>(_passwordBarColor),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _ruleItem(t(context, '8 characters', '8 character'), _min8),
              _ruleItem(t(context, '1 number', '1 numero'), _hasNumber),
              _ruleItem(t(context, '1 symbol', '1 simbolo'), _hasSymbol),
              _ruleItem(
                t(context, '1 uppercase', '1 malaking titik'),
                _hasUpper,
              ),
              _ruleItem(t(context, 'Passwords match', 'Magkatugma'), _matches),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterButton() => SizedBox(
    width: double.infinity,
    height: 50,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: brandRed,
        disabledBackgroundColor: brandRed.withOpacity(0.55),
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
              t(context, 'Verify Email Address', 'I-verify ang Email Address'),
              textAlign: TextAlign.center,
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
            onPressed: () {
              LoginPage.skipAutoRoute = false;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
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

  Widget _buildReservedForgotPasswordSlot() => ExcludeSemantics(
    child: IgnorePointer(
      child: Opacity(
        opacity: 0,
        child: Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              t(context, 'Forgot Password?', 'Kalimutan ang Password'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Poppins',
                color: brandRed,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _buildReservedTermsSlot() => ExcludeSemantics(
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
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.symmetric(horizontal: 35.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 48, bottom: 22),
                  child: SizedBox(
                    height: 110,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: Image.asset('assets/logo.png'),
                    ),
                  ),
                ),
                Text(
                  t(context, 'Sign Up', 'Mag-sign up'),
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
                  t(
                    context,
                    'Welcome to, IGNIS SAFE',
                    'Maligayang pagdating sa IGNIS SAFE',
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.black38,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 20),
                _inputLabel(t(context, 'Full Name', 'Buong Pangalan')),
                _buildValidatedField(
                  hint: t(
                    context,
                    'Enter your full name',
                    'Ilagay ang iyong buong pangalan',
                  ),
                  controller: fullNameCtrl,
                  validator: _validateFullName,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r"[A-Za-zÀ-ÖØ-öø-ÿÑñ '\-.]"),
                    ),
                  ],
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 18),
                _inputLabel(t(context, 'Email Address', 'Email Address')),
                _buildValidatedField(
                  hint: t(
                    context,
                    'Enter your email address',
                    'Ilagay ang iyong email address',
                  ),
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 18),
                _inputLabel(t(context, 'Password', 'Password')),
                _buildValidatedField(
                  hint: t(
                    context,
                    'Enter your password',
                    'Ilagay ang iyong password',
                  ),
                  controller: passCtrl,
                  validator: _validatePassword,
                  obscureText: !_showPassword,
                  textInputAction: TextInputAction.next,
                  suffixIcon: _visibilitySuffix(
                    visible: _showPassword,
                    onTap: () {
                      setState(() => _showPassword = !_showPassword);
                    },
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: _passwordStarted
                      ? Padding(
                          key: const ValueKey('password-rules'),
                          padding: const EdgeInsets.only(top: 12),
                          child: _buildPasswordValidationCard(),
                        )
                      : const SizedBox.shrink(
                          key: ValueKey('password-rules-empty'),
                        ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: _confirmPasswordVisible
                      ? Column(
                          key: const ValueKey('confirm-password'),
                          children: [
                            const SizedBox(height: 18),
                            _inputLabel(
                              t(
                                context,
                                'Confirm Password',
                                'Kumpirmahin ang Password',
                              ),
                            ),
                            _buildValidatedField(
                              hint: t(
                                context,
                                'Confirm your password',
                                'Kumpirmahin ang iyong password',
                              ),
                              controller: confirmPassCtrl,
                              validator: _validateConfirmPassword,
                              obscureText: !_showConfirmPassword,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) {
                                if (!_isLoading) {
                                  _continueToVerifyEmail();
                                }
                              },
                              suffixIcon: _visibilitySuffix(
                                visible: _showConfirmPassword,
                                onTap: () {
                                  setState(
                                    () => _showConfirmPassword =
                                        !_showConfirmPassword,
                                  );
                                },
                              ),
                            ),
                          ],
                        )
                      : const SizedBox.shrink(
                          key: ValueKey('confirm-password-empty'),
                        ),
                ),
                const SizedBox(height: 6),
                _buildReservedForgotPasswordSlot(),
                const SizedBox(height: 22),
                _buildRegisterButton(),
                const SizedBox(height: 16),
                _buildReservedTermsSlot(),
                const SizedBox(height: 18),
                _buildFooter(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
