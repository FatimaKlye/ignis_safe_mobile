import 'package:flutter/material.dart';

import 'app_content_refresh.dart';
import 'app_version_service.dart';
import 'localization/language_controller.dart';
import 'widgets/app_notification.dart';
import 'widgets/app_update_dialog.dart';

const Color _refreshBrandRed = Color(0xFFB11217);

/// Keeps a second tap on the menu item from starting a parallel refresh while
/// the first one is still running.
bool _refreshInProgress = false;

/// Backs the profile menu's "Refresh & Check Updates" item.
///
/// Re-fetches every screen's Supabase content through
/// [AppContentRefreshRegistry] (so the visible UI updates straight away) and,
/// in parallel, compares the installed build with the latest release published
/// in Supabase. Content is reloaded by the refresh; a newer app binary is not,
/// so that case hands off to the update dialog instead.
Future<void> runAppRefreshAndUpdateCheck(BuildContext context) async {
  if (_refreshInProgress) return;
  _refreshInProgress = true;

  final navigator = Navigator.of(context, rootNavigator: true);
  var loadingDialogOpen = true;

  void closeLoadingDialog() {
    if (!loadingDialogOpen) return;
    loadingDialogOpen = false;
    if (navigator.mounted) navigator.pop();
  }

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (_) => const _RefreshingDialog(),
  );

  try {
    final contentFuture = AppContentRefreshRegistry.refreshAll();

    // Failing to read the release table must not sink the content refresh, so
    // the error is handled here and simply leaves the version unknown.
    final versionFuture = AppVersionService.check().then<AppUpdateStatus?>(
      (status) => status,
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('APP VERSION CHECK ERROR: $error\n$stackTrace');
        return null;
      },
    );

    final results = await Future.wait<Object?>([
      contentFuture,
      versionFuture,
      // Keeps the spinner on screen long enough to read on a fast connection.
      Future<void>.delayed(const Duration(milliseconds: 450)),
    ]);

    final contentResult = results[0] as AppContentRefreshResult;
    final updateStatus = results[1] as AppUpdateStatus?;

    closeLoadingDialog();

    if (!context.mounted) return;

    if (contentResult.failed) {
      showAppNotification(
        context,
        title: t(context, 'Refresh Failed', 'Hindi Na-refresh'),
        message: t(
          context,
          'We could not load the latest content. Check your internet connection and try again.',
          'Hindi na-load ang pinakabagong nilalaman. Pakisuri ang iyong internet at subukang muli.',
        ),
        type: AppNotificationType.error,
      );
      return;
    }

    if (updateStatus != null && updateStatus.updateAvailable) {
      await showAppUpdateDialog(context, status: updateStatus);
      return;
    }

    showAppNotification(
      context,
      title: contentResult.changed
          ? t(context, 'Content Updated', 'Na-update ang Nilalaman')
          : t(context, 'Up to Date', 'Napapanahon'),
      message: contentResult.changed
          ? t(
              context,
              'Latest content loaded successfully.',
              'Matagumpay na na-load ang pinakabagong nilalaman.',
            )
          : t(
              context,
              'IGNIS SAFE is up to date.',
              'Napapanahon ang IGNIS SAFE.',
            ),
      type: AppNotificationType.success,
    );
  } finally {
    closeLoadingDialog();
    _refreshInProgress = false;
  }
}

/// Blocking spinner shown while the refresh and version check run.
class _RefreshingDialog extends StatelessWidget {
  const _RefreshingDialog();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 24),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 2.6,
                  color: _refreshBrandRed,
                ),
              ),
              const SizedBox(width: 16),
              Flexible(
                child: Text(
                  t(
                    context,
                    'Refreshing content…',
                    'Nire-refresh ang nilalaman…',
                  ),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
