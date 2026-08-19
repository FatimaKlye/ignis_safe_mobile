import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_version_service.dart';
import '../localization/language_controller.dart';
import 'app_notification.dart';

const Color _updateBrandRed = Color(0xFFB11217);
const List<Color> _updateGradient = [Color(0xFFC9232A), _updateBrandRed];

/// Shows the app-update dialog for a newer build published in Supabase.
///
/// Matches the look of [showAppDialog] (gradient icon badge, rounded 24
/// corners, gradient CTA) and adds the installed/latest version rows plus the
/// download action, because a new APK cannot be delivered by refreshing data.
Future<void> showAppUpdateDialog(
  BuildContext context, {
  required AppUpdateStatus status,
}) async {
  final release = status.latest;
  if (release == null) return;

  final mandatory = release.isMandatory;

  await showDialog<void>(
    context: context,
    barrierDismissible: !mandatory,
    useRootNavigator: true,
    builder: (dialogContext) {
      final compact = MediaQuery.of(dialogContext).size.width < 360;
      final isTagalog =
          Localizations.localeOf(dialogContext).languageCode == 'tl';
      final notes = (isTagalog ? release.releaseNotesTl : null) ??
          release.releaseNotesEn;

      return PopScope(
        canPop: !mandatory,
        child: Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 430),
                padding: EdgeInsets.all(compact ? 18 : 22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 6),
                    Container(
                      width: compact ? 54 : 62,
                      height: compact ? 54 : 62,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: _updateGradient),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.system_update_rounded,
                        color: Colors.white,
                        size: compact ? 27 : 31,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      t(
                        dialogContext,
                        'Update Available',
                        'May Bagong Update',
                      ),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: const Color(0xFF111827),
                        fontSize: compact ? 17 : 19,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      t(
                        dialogContext,
                        'A newer version of IGNIS SAFE is available. Install it to get the latest app improvements.',
                        'May mas bagong bersyon ng IGNIS SAFE. I-install ito para makuha ang pinakabagong pagpapabuti ng app.',
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        color: Color(0xFF4B5563),
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F4F2),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFEEE9E6)),
                      ),
                      child: Column(
                        children: [
                          _VersionRow(
                            label: t(
                              dialogContext,
                              'Installed version',
                              'Naka-install na bersyon',
                            ),
                            value: status.installedLabel,
                          ),
                          const SizedBox(height: 8),
                          _VersionRow(
                            label: t(
                              dialogContext,
                              'Latest version',
                              'Pinakabagong bersyon',
                            ),
                            value: release.displayLabel,
                            highlight: true,
                          ),
                        ],
                      ),
                    ),
                    if (notes != null) ...[
                      const SizedBox(height: 14),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          t(dialogContext, "What's new", 'Ano ang bago'),
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            color: Color(0xFF111827),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 140),
                        child: SingleChildScrollView(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              notes,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                color: Color(0xFF4B5563),
                                fontSize: 12.5,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: _updateGradient,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () => _handleUpdateAction(
                            dialogContext,
                            downloadUrl: release.downloadUrl,
                            mandatory: mandatory,
                          ),
                          child: Text(
                            release.downloadUrl == null
                                ? t(dialogContext, 'OK', 'OK')
                                : t(dialogContext, 'Update Now', 'I-update Na'),
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (!mandatory && release.downloadUrl != null) ...[
                      const SizedBox(height: 6),
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: Text(
                          t(dialogContext, 'Later', 'Mamaya'),
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!mandatory)
                Positioned(
                  top: 8,
                  right: 8,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => Navigator.of(dialogContext).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF3F4F6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: Color(0xFF6B7280),
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

Future<void> _handleUpdateAction(
  BuildContext dialogContext, {
  required String? downloadUrl,
  required bool mandatory,
}) async {
  if (downloadUrl == null) {
    Navigator.of(dialogContext).pop();
    return;
  }

  final uri = Uri.tryParse(downloadUrl);
  var opened = false;

  if (uri != null) {
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }
  }

  if (!dialogContext.mounted) return;

  if (!opened) {
    showAppNotification(
      dialogContext,
      title: t(dialogContext, 'Update Link Unavailable', 'Hindi Mabuksan'),
      message: t(
        dialogContext,
        'The update link could not be opened. Please try again later.',
        'Hindi mabuksan ang link ng update. Pakisubukan muli mamaya.',
      ),
      type: AppNotificationType.error,
    );
    return;
  }

  // A mandatory update keeps the dialog up so the user returns to it after
  // the download page opens.
  if (!mandatory) {
    Navigator.of(dialogContext).pop();
  }
}

class _VersionRow extends StatelessWidget {
  const _VersionRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              color: Color(0xFF6B7280),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Poppins',
            color: highlight ? _updateBrandRed : const Color(0xFF111827),
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
