import 'dart:io';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

/// Result of a device integrity check.
class DeviceIntegrityResult {
  /// True when the device shows signs of root (Android) or jailbreak (iOS).
  final bool isCompromised;

  /// Human-readable signals that tripped, for logging/diagnostics.
  /// Deliberately NOT shown to the end user, to avoid handing an attacker
  /// a checklist of what to hide.
  final List<String> signals;

  const DeviceIntegrityResult({
    required this.isCompromised,
    this.signals = const [],
  });

  static const DeviceIntegrityResult trusted = DeviceIntegrityResult(
    isCompromised: false,
  );
}

/// Detects rooted (Android) / jailbroken (iOS) devices.
///
/// Policy: detection is **advisory only**. The app shows a one-time warning
/// at launch and otherwise behaves normally. No features are restricted.
///
/// Implementation notes:
/// - No third-party dependency. Uses `dart:io` filesystem probes plus
///   `device_info_plus`, which the app already depends on.
/// - This is a **deterrent**, not a guarantee. A determined attacker on a
///   rooted device can hide these artefacts or patch the app. Treat it as
///   defence in depth alongside server-side checks, never as the only
///   control.
/// - Checks are skipped in debug builds so developers and emulators are
///   not blocked during development.
class DeviceIntegrityService {
  DeviceIntegrityService._();
  static final DeviceIntegrityService instance = DeviceIntegrityService._();

  DeviceIntegrityResult? _cached;
  bool _warningShown = false;

  /// Last known result. Defaults to trusted until [evaluate] has run.
  DeviceIntegrityResult get status => _cached ?? DeviceIntegrityResult.trusted;

  bool get isCompromised => status.isCompromised;

  /// True when the launch warning still needs to be shown this session.
  /// Prevents the alert reappearing on every navigation.
  bool get shouldShowWarning => isCompromised && !_warningShown;

  void markWarningShown() => _warningShown = true;

  /// Runs the checks once and caches the result for the session.
  /// Safe to call repeatedly.
  Future<DeviceIntegrityResult> evaluate({bool forceRefresh = false}) async {
    if (_cached != null && !forceRefresh) return _cached!;

    final signals = <String>[];
    try {
      if (Platform.isAndroid) {
        signals.addAll(await _androidSignals());
      } else if (Platform.isIOS) {
        signals.addAll(await _iosSignals());
      }
    } catch (e) {
      // A failed probe must never brick the app — fail open.
      debugPrint('Device integrity check error: $e');
    }

    _cached = DeviceIntegrityResult(
      isCompromised: signals.isNotEmpty,
      signals: signals,
    );

    // Always log the outcome so a "why didn't it warn?" question is
    // answerable from the device log rather than by guesswork.
    debugPrint(
      '🔐 Device integrity: '
      '${_cached!.isCompromised ? "COMPROMISED" : "clean"} '
      'signals=${_cached!.signals}',
    );
    return _cached!;
  }

  /// Forces the compromised state on for UI testing. Debug builds only —
  /// the call is ignored in release so it cannot be abused.
  @visibleForTesting
  void debugSimulateCompromised() {
    if (!kDebugMode) return;
    _cached = const DeviceIntegrityResult(
      isCompromised: true,
      signals: ['debug_simulated'],
    );
    _warningShown = false;
  }

  // ───────────────────────────── Android ──────────────────────────────

  static const List<String> _suBinaries = [
    '/system/bin/su',
    '/system/xbin/su',
    '/sbin/su',
    '/su/bin/su',
    '/system/su',
    '/system/bin/.ext/.su',
    '/system/usr/we-need-root/su',
    '/system/xbin/mu',
    '/data/local/su',
    '/data/local/bin/su',
    '/data/local/xbin/su',
    '/system/sd/xbin/su',
    '/system/bin/failsafe/su',
  ];

  static const List<String> _magiskArtefacts = [
    '/sbin/magisk',
    '/sbin/.magisk',
    '/data/adb/magisk',
    '/data/adb/modules',
    '/cache/.disable_magisk',
    '/dev/.magisk.unblock',
  ];

  static const List<String> _rootApps = [
    '/system/app/Superuser.apk',
    '/system/app/SuperSU',
    '/data/data/com.topjohnwu.magisk',
    '/data/data/eu.chainfire.supersu',
    '/data/data/com.noshufou.android.su',
    '/data/data/com.koushikdutta.superuser',
    '/data/data/com.thirdparty.superuser',
  ];

  static const List<String> _otherRootIndicators = [
    '/system/xbin/busybox',
    '/system/bin/busybox',
    '/system/xbin/daemonsu',
    '/system/etc/init.d/99SuperSUDaemon',
  ];

  Future<List<String>> _androidSignals() async {
    final signals = <String>[];

    // Direct filesystem probes. Note: on Android 11+ SELinux blocks stat()
    // on most /system paths, so these frequently return false even on a
    // rooted device. Kept because they still fire on older devices.
    if (_anyPathExists(_suBinaries)) signals.add('su_binary');
    if (_anyPathExists(_magiskArtefacts)) signals.add('magisk');
    if (_anyPathExists(_rootApps)) signals.add('root_manager_app');
    if (_anyPathExists(_otherRootIndicators)) signals.add('root_tooling');

    // Shell-based probes. These survive the Android 11+ restrictions above
    // because the shell resolves PATH itself rather than us stat'ing files.
    if (await _shellFindsSu()) signals.add('su_on_path');
    if (await _shellFindsMagisk()) signals.add('magisk_on_path');

    // Custom/dev builds are signed with test-keys rather than release-keys.
    // Skipped on emulators, which always report test-keys.
    try {
      final info = await DeviceInfoPlugin().androidInfo;
      if (info.isPhysicalDevice &&
          info.tags.toLowerCase().contains('test-keys')) {
        signals.add('test_keys_build');
      }
    } catch (_) {
      // device_info unavailable — other signals still apply.
    }

    return signals;
  }

  /// Asks the shell to resolve `su` on PATH. Works on modern Android where
  /// direct `File('/system/bin/su').existsSync()` is denied.
  Future<bool> _shellFindsSu() async {
    for (final cmd in ['which su', 'command -v su']) {
      try {
        final result = await Process.run('sh', [
          '-c',
          cmd,
        ]).timeout(const Duration(seconds: 3));
        final out = '${result.stdout}'.trim();
        if (result.exitCode == 0 && out.isNotEmpty && out.contains('su')) {
          return true;
        }
      } catch (_) {
        // sh unavailable or timed out — try the next form.
      }
    }
    return false;
  }

  /// Looks for Magisk's binary/daemon without requesting root, so the user
  /// is never prompted by a superuser dialog.
  Future<bool> _shellFindsMagisk() async {
    try {
      final result = await Process.run('sh', [
        '-c',
        'which magisk || ls /data/adb/magisk 2>/dev/null',
      ]).timeout(const Duration(seconds: 3));
      final out = '${result.stdout}'.trim();
      return out.isNotEmpty && out.toLowerCase().contains('magisk');
    } catch (_) {
      return false;
    }
  }

  // ─────────────────────────────── iOS ────────────────────────────────

  static const List<String> _jailbreakPaths = [
    // Package managers / alternative app stores
    '/Applications/Cydia.app',
    '/Applications/Sileo.app',
    '/Applications/Zebra.app',
    '/Applications/Installer.app',
    '/Applications/blackra1n.app',
    // Tweak injection frameworks
    '/Library/MobileSubstrate/MobileSubstrate.dylib',
    '/Library/MobileSubstrate/DynamicLibraries',
    '/usr/lib/libsubstrate.dylib',
    '/usr/lib/TweakInject',
    // Shells and daemons that should not exist on a stock device
    '/bin/bash',
    '/bin/sh',
    '/usr/sbin/sshd',
    '/usr/bin/ssh',
    '/usr/libexec/ssh-keysign',
    // APT / package infrastructure
    '/etc/apt',
    '/private/var/lib/apt',
    '/private/var/lib/cydia',
    '/private/var/stash',
    '/private/var/tmp/cydia.log',
  ];

  Future<List<String>> _iosSignals() async {
    final signals = <String>[];

    if (_anyPathExists(_jailbreakPaths)) signals.add('jailbreak_artefact');
    if (await _canEscapeSandbox()) signals.add('sandbox_escape');

    return signals;
  }

  /// A stock iOS app cannot write outside its own container. If this
  /// succeeds, the sandbox has been broken.
  Future<bool> _canEscapeSandbox() async {
    final name = 'chk_${Random().nextInt(1 << 32)}.tmp';
    final probe = File('/private/$name');
    try {
      await probe.writeAsString('.', flush: true);
      // Wrote outside the sandbox — clean up and report.
      try {
        await probe.delete();
      } catch (_) {}
      return true;
    } catch (_) {
      return false; // Expected on a healthy device.
    }
  }

  // ────────────────────────────── Helpers ─────────────────────────────

  bool _anyPathExists(List<String> paths) {
    for (final path in paths) {
      try {
        if (File(path).existsSync() || Directory(path).existsSync()) {
          return true;
        }
      } catch (_) {
        // Permission denied is not a positive signal — keep checking.
      }
    }
    return false;
  }
}
