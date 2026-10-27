import 'package:flutter/foundation.dart';

/// Tells the Home dashboards that their data is out of date.
///
/// Fired after the user successfully submits a leave request or an
/// attendance adjustment. Each dashboard listens and reloads its data
/// quietly in the background, so the Home screen is already up to date
/// when the user navigates back, without a manual pull-to-refresh.
class DashboardRefreshSignal extends ChangeNotifier {
  DashboardRefreshSignal._();

  static final DashboardRefreshSignal instance = DashboardRefreshSignal._();

  /// Marks Home data as stale and notifies the listening dashboards.
  void notifyDataChanged() => notifyListeners();
}
