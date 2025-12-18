class AppVersion {
  final int id;
  final String version;
  final String minimumRequiredVersion;
  final String releaseNotes;
  final String releaseDate;
  final bool isMandatory;
  final String iosUrl;
  final String androidUrl;

  AppVersion({
    required this.id,
    required this.version,
    required this.minimumRequiredVersion,
    required this.releaseNotes,
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
    releaseDate: json['release_date'] ?? '',
    isMandatory: json['is_mandatory'] ?? false,
    iosUrl: json['ios_url'] ?? '',
    androidUrl: json['android_url'] ?? '',
  );

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
