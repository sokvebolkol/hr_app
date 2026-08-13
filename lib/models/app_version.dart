class AppVersion {
  final int id;
  final String version;
  final String minimumRequiredVersion;

  /// Legacy single-language field. The backend still sends it for older app
  /// builds, so it's kept as the fallback when the localized fields are
  /// missing.
  final String releaseNotes;
  final String? releaseNotesEn;
  final String? releaseNotesKh;

  final String releaseDate;
  final bool isMandatory;
  final String iosUrl;
  final String androidUrl;

  AppVersion({
    required this.id,
    required this.version,
    required this.minimumRequiredVersion,
    required this.releaseNotes,
    this.releaseNotesEn,
    this.releaseNotesKh,
    required this.releaseDate,
    required this.isMandatory,
    required this.iosUrl,
    required this.androidUrl,
  });

  factory AppVersion.fromJson(Map<String, dynamic> json) => AppVersion(
    id: json['id'] ?? 0,
    version: json['version'] ?? '1.0.0',
    minimumRequiredVersion: json['minimum_required_version'] ?? '1.0.0',
    releaseNotes: json['release_notes'] ?? '',
    releaseNotesEn: json['release_notes_en']?.toString(),
    releaseNotesKh: json['release_notes_kh']?.toString(),
    releaseDate: json['release_date'] ?? '',
    isMandatory: json['is_mandatory'] ?? false,
    iosUrl: json['ios_url'] ?? '',
    androidUrl: json['android_url'] ?? '',
  );

  /// Release notes for the given language code ("EN" / "KH", as returned by
  /// [Language.code]). Falls back to the other localized field, then to the
  /// legacy [releaseNotes], so older API responses still render.
  String releaseNotesFor(String languageCode) {
    final isKhmer = languageCode.toUpperCase() == 'KH';
    final preferred = isKhmer ? releaseNotesKh : releaseNotesEn;
    final alternate = isKhmer ? releaseNotesEn : releaseNotesKh;

    for (final candidate in [preferred, alternate, releaseNotes]) {
      if (candidate != null && candidate.trim().isNotEmpty) return candidate;
    }
    return '';
  }

  // Helper method to compare versions
  bool isVersionGreaterThan(String currentVersion) {
    try {
      final minParts =
          minimumRequiredVersion.split('.').map(int.parse).toList();
      final currentParts = currentVersion.split('.').map(int.parse).toList();

      for (int i = 0; i < minParts.length && i < currentParts.length; i++) {
        if (minParts[i] > currentParts[i]) return true;
        if (minParts[i] < currentParts[i]) return false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
