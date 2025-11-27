class AdmobConstants {
  // Test Ad Unit IDs (untuk development)
  static const String testBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const String testInterstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';
  static const String testRewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';
  static const String testNativeAdUnitId = 'ca-app-pub-3940256099942544/2247696110';

  // Real Ad Unit IDs (untuk production)
  static String get realBannerAdUnitId {
    const envId = Environment.admobBannerId;
    return envId.isNotEmpty ? envId : testBannerAdUnitId;
  }

  static String get realInterstitialAdUnitId {
    const envId = Environment.admobInterstitialId;
    return envId.isNotEmpty ? envId : testInterstitialAdUnitId;
  }

  static String get realRewardedAdUnitId {
    const envId = Environment.admobRewardedId;
    return envId.isNotEmpty ? envId : testRewardedAdUnitId;
  }

  static String get realNativeAdUnitId {
    const envId = Environment.admobNativeId;
    return envId.isNotEmpty ? envId : testNativeAdUnitId;
  }

  // Configuration
  static const int maxFailedLoadAttempts = 3;
  static const Duration adLoadTimeout = Duration(seconds: 10);
  static const Duration interstitialInterval = Duration(minutes: 2);
}