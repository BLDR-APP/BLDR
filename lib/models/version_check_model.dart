class VersionCheckModel {
  final String minimumVersion;

  const VersionCheckModel({required this.minimumVersion});

  factory VersionCheckModel.fromJson(Map<String, dynamic> json) {
    return VersionCheckModel(
      minimumVersion: json['minimum_version'] as String,
    );
  }
}
