import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../localization/app_text.dart';
import '../localization/language_controller.dart';

const Color _brandRed = Color(0xFFB11217);
const List<String> _languageCodes = ['en', 'tl'];

/// Opens a simple English / Filipino selector. The choice is applied
/// immediately and saved through [LanguageController].
Future<void> showLanguagePicker(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (sheetContext) {
      final controller = sheetContext.watch<LanguageController>();
      final selectedCode = controller.locale.languageCode;

      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  sheetContext.tr('language'),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    color: Color(0xFF22242A),
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              for (final code in _languageCodes)
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  title: Text(
                    LanguageController.languageName(code),
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: selectedCode == code
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: selectedCode == code
                          ? _brandRed
                          : const Color(0xFF22242A),
                    ),
                  ),
                  trailing: Icon(
                    selectedCode == code
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: selectedCode == code
                        ? _brandRed
                        : const Color(0xFFB7B9C0),
                  ),
                  selected: selectedCode == code,
                  onTap: () {
                    controller.setLanguage(code);
                    Navigator.of(sheetContext).pop();
                  },
                ),
            ],
          ),
        ),
      );
    },
  );
}

/// Minimal "English | Filipino" switch for screens where a full selector
/// would be distracting, such as Login.
class CompactLanguageToggle extends StatelessWidget {
  const CompactLanguageToggle({super.key, this.color = _brandRed});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LanguageController>();
    final selectedCode = controller.locale.languageCode;

    return Semantics(
      label: context.tr('language'),
      container: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.language_rounded, size: 16, color: color),
          const SizedBox(width: 4),
          for (var i = 0; i < _languageCodes.length; i++) ...[
            if (i > 0)
              const Text(
                '|',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Colors.black26,
                ),
              ),
            _LanguageOption(
              label: LanguageController.languageName(_languageCodes[i]),
              selected: selectedCode == _languageCodes[i],
              color: color,
              onTap: () => controller.setLanguage(_languageCodes[i]),
            ),
          ],
        ],
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: selected ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 36),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Center(
              widthFactor: 1,
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? color : Colors.black45,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
