import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';

import '../models/app_version.dart';
import '../repositories/dashboard_repository.dart';

/// Outcome of a user-initiated "Check for update".
enum UpdateCheckState { upToDate, updateAvailable, failed }

class UpdateCheckResult {
  final UpdateCheckState state;

  /// Version string currently installed on this device.
  final String currentVersion;

  /// Latest version published by the backend, when known.
  final AppVersion? latest;

  /// Populated when [state] is [UpdateCheckState.failed].
  final String? errorMessage;

  const UpdateCheckResult({
    required this.state,
    required this.currentVersion,
    this.latest,
    this.errorMessage,
  });

  bool get hasUpdate => state == UpdateCheckState.updateAvailable;

  /// Store URL for the running platform.
  String get updateUrl {
    if (latest == null) return '';
    return Platform.isAndroid ? latest!.androidUrl : latest!.iosUrl;
  }
}

/// Backs the "Check for update" menu action.
///
/// The latest published version arrives on the dashboard `home` endpoint
/// under `app_version`, so this reuses [DashboardRepository] rather than
/// introducing a second source of truth.
class AppUpdateService {
  AppUpdateService._();
  static final AppUpdateService instance = AppUpdateService._();

  final DashboardRepository _dashboardRepository = DashboardRepository();

  /// Installed version, e.g. "1.0.4".
  Future<String> currentVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return info.version;
    } catch (_) {
      return '';
    }
  }

  /// Installed version with build number, e.g. "1.0.4 (28)".
  Future<String> currentVersionWithBuild() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return info.buildNumber.isEmpty
          ? info.version
          : '${info.version} (${info.buildNumber})';
    } catch (_) {
      return '';
    }
  }

  /// Compares the installed version against the backend's published version.
  Future<UpdateCheckResult> check() async {
    final installed = await currentVersion();

    try {
      final data = await _dashboardRepository.getDashboardData();
      final latest = data.appVersion;

      if (latest == null) {
        // Nothing published — treat as up to date rather than an error.
        return UpdateCheckResult(
          state: UpdateCheckState.upToDate,
          currentVersion: installed,
        );
      }

      final available = _isNewer(latest.version, installed);
      return UpdateCheckResult(
        state:
            available
                ? UpdateCheckState.updateAvailable
                : UpdateCheckState.upToDate,
        currentVersion: installed,
        latest: latest,
      );
    } catch (e) {
      var message = e.toString();
      if (message.startsWith('Exception: ')) {
        message = message.substring(11);
      }
      return UpdateCheckResult(
        state: UpdateCheckState.failed,
        currentVersion: installed,
        errorMessage: message,
      );
    }
  }

  /// True when [candidate] is a higher semantic version than [installed].
  ///
  /// Compares numerically segment by segment so "1.10.0" correctly beats
  /// "1.9.0", which a plain string comparison would get wrong. Unequal
  /// segment counts are handled by treating missing segments as 0.
  bool _isNewer(String candidate, String installed) {
    if (candidate.isEmpty || installed.isEmpty) return false;

    List<int> parse(String v) =>
        v
            .split('+')
            .first // drop any build suffix
            .split('.')
            .map((p) => int.tryParse(p.trim()) ?? 0)
            .toList();

    final a = parse(candidate);
    final b = parse(installed);
    final length = a.length > b.length ? a.length : b.length;

    for (var i = 0; i < length; i++) {
      final left = i < a.length ? a[i] : 0;
      final right = i < b.length ? b[i] : 0;
      if (left > right) return true;
      if (left < right) return false;
    }
    return false; // identical
  }
}
