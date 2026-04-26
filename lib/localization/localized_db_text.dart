import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'language_controller.dart';

class LocalizedDbText {
  static String currentLanguage(BuildContext context) {
    try {
      return Provider.of<LanguageController>(
        context,
        listen: false,
      ).locale.languageCode;
    } catch (_) {
      try {
        return Localizations.localeOf(context).languageCode;
      } catch (_) {
        return 'en';
      }
    }
  }

  static bool isTagalog(BuildContext context) {
    return currentLanguage(context) == 'tl';
  }

  static String pick(
    BuildContext context,
    Map<String, dynamic> row,
    String englishColumn,
    String tagalogColumn, {
    String fallback = '',
  }) {
    final useTagalog = isTagalog(context);

    final preferred = useTagalog ? row[tagalogColumn] : row[englishColumn];
    final preferredText = (preferred ?? '').toString().trim();

    if (preferredText.isNotEmpty) {
      return preferredText;
    }

    final englishText = (row[englishColumn] ?? '').toString().trim();

    if (englishText.isNotEmpty) {
      return englishText;
    }

    final tagalogText = (row[tagalogColumn] ?? '').toString().trim();

    if (tagalogText.isNotEmpty) {
      return tagalogText;
    }

    return fallback;
  }

  static String moduleLabel(BuildContext context, int moduleNo) {
    return isTagalog(context) ? 'MODYUL $moduleNo' : 'MODULE $moduleNo';
  }
}
