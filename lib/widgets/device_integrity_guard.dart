import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/constant.dart';
import '../localization/language.dart';
import '../localization/language_logic.dart';
import '../services/device_integrity_service.dart';

/// Shows a one-time warning at app launch when the device appears rooted
/// (Android) or jailbroken (iOS).
///
/// Advisory only: the user acknowledges and continues. No features are
/// restricted.
class DeviceIntegrityGuard {
  DeviceIntegrityGuard._();

  /// Call once after the first frame of the first screen shown post-launch.
  /// Does nothing on a healthy device, or if the warning was already shown
  /// this session.
  static Future<void> showLaunchWarningIfNeeded(
    BuildContext context, [
    Language? language,
  ]) async {
    final service = DeviceIntegrityService.instance;
    if (!service.shouldShowWarning) return;

    // Mark before awaiting so a rebuild cannot queue a second dialog.
    service.markWarningShown();

    final resolved = language ?? await _currentLanguage();
    if (!context.mounted) return;

    HapticFeedback.mediumImpact();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.gpp_maybe_rounded,
                    size: 44,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  resolved.deviceNotSecure,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  resolved.deviceNotSecureWarning,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    elevation: 0,
                  ),
                  child: Text(resolved.iUnderstand),
                ),
              ),
            ],
          ),
    );
  }

  static Future<Language> _currentLanguage() async {
    try {
      final logic = LanguageLogic();
      await logic.initialize();
      return logic.language;
    } catch (_) {
      return Language(); // English fallback
    }
  }
}
