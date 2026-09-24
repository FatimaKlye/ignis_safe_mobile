import 'package:flutter/material.dart';
import '../localization/language_controller.dart';

/// Password strength rules shared by Sign Up and Reset Password:
/// 8+ characters, 1 uppercase, 1 number and 1 symbol.
@immutable
class PasswordRules {
  const PasswordRules._({
    required this.min8,
    required this.hasUpper,
    required this.hasNumber,
    required this.hasSymbol,
  });

  factory PasswordRules.check(String password) {
    return PasswordRules._(
      min8: password.length >= 8,
      hasUpper: _upperPattern.hasMatch(password),
      hasNumber: _numberPattern.hasMatch(password),
      hasSymbol: _symbolPattern.hasMatch(password),
    );
  }

  static final RegExp _upperPattern = RegExp(r'[A-Z]');
  static final RegExp _numberPattern = RegExp(r'\d');
  static final RegExp _symbolPattern = RegExp(
    r'[!@#$%^&*(),.?":{}|<>_\-\[\]\\/~`+=;]',
  );

  final bool min8;
  final bool hasUpper;
  final bool hasNumber;
  final bool hasSymbol;

  bool get allPassed => min8 && hasUpper && hasNumber && hasSymbol;

  @override
  bool operator ==(Object other) =>
      other is PasswordRules &&
      other.min8 == min8 &&
      other.hasUpper == hasUpper &&
      other.hasNumber == hasNumber &&
      other.hasSymbol == hasSymbol;

  @override
  int get hashCode => Object.hash(min8, hasUpper, hasNumber, hasSymbol);
}

/// Live password requirements checklist. Hidden until [visible] is true
/// (the user has started typing), then animates in below the password field.
class PasswordRequirementsCard extends StatelessWidget {
  const PasswordRequirementsCard({
    super.key,
    required this.rules,
    required this.visible,
  });

  final PasswordRules rules;
  final bool visible;

  static const Color _passedColor = Color(0xFF2E7D32);

  Widget _ruleItem(String text, bool passed) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          passed ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 16,
          color: passed ? _passedColor : Colors.black38,
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            color: passed ? _passedColor : Colors.black54,
            fontWeight: passed ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCard(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEAEAEA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t(context, 'Password requirements', 'Mga kailangan sa password'),
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _ruleItem(
                t(context, '8+ characters', '8+ na character'),
                rules.min8,
              ),
              _ruleItem(
                t(context, '1 uppercase', '1 malaking titik'),
                rules.hasUpper,
              ),
              _ruleItem(t(context, '1 number', '1 numero'), rules.hasNumber),
              _ruleItem(t(context, '1 symbol', '1 simbolo'), rules.hasSymbol),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: visible
          ? Padding(
              key: const ValueKey('password-rules'),
              padding: const EdgeInsets.only(top: 10),
              child: _buildCard(context),
            )
          : const SizedBox.shrink(key: ValueKey('password-rules-empty')),
    );
  }
}
