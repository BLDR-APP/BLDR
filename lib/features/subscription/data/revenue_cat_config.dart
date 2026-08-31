enum RevenueCatPlatform { ios, android, unsupported }

class RevenueCatConfig {
  final bool billingEnabled;
  final String iosPublicSdkKey;
  final String androidPublicSdkKey;

  const RevenueCatConfig({
    required this.billingEnabled,
    required this.iosPublicSdkKey,
    required this.androidPublicSdkKey,
  });

  factory RevenueCatConfig.fromMap(Map<String, dynamic> values) {
    final rawFlag = values['REVENUECAT_BILLING_ENABLED'];
    final enabled = rawFlag == true ||
        (rawFlag is String && rawFlag.toLowerCase() == 'true');
    return RevenueCatConfig(
      billingEnabled: enabled,
      iosPublicSdkKey:
          (values['REVENUECAT_IOS_PUBLIC_SDK_KEY'] as String? ?? '').trim(),
      androidPublicSdkKey:
          (values['REVENUECAT_ANDROID_PUBLIC_SDK_KEY'] as String? ?? '').trim(),
    );
  }

  String keyFor(RevenueCatPlatform platform) => switch (platform) {
        RevenueCatPlatform.ios => iosPublicSdkKey,
        RevenueCatPlatform.android => androidPublicSdkKey,
        RevenueCatPlatform.unsupported => '',
      };
}
