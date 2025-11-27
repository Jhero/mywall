import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants/admob_constants.dart';
import '../../core/utils/debug_logger.dart';

class AdmobService {
  static final AdmobService _instance = AdmobService._internal();
  factory AdmobService() => _instance;
  AdmobService._internal();

  static bool get _isTestMode => kDebugMode;

  // Ad Unit ID Getters
  static String get bannerAdUnitId => _isTestMode 
      ? AdmobConstants.testBannerAdUnitId 
      : AdmobConstants.realBannerAdUnitId;

  static String get interstitialAdUnitId => _isTestMode 
      ? AdmobConstants.testInterstitialAdUnitId 
      : AdmobConstants.realInterstitialAdUnitId;

  static String get rewardedAdUnitId => _isTestMode 
      ? AdmobConstants.testRewardedAdUnitId 
      : AdmobConstants.realRewardedAdUnitId;

  static String get nativeAdUnitId => _isTestMode 
      ? AdmobConstants.testNativeAdUnitId 
      : AdmobConstants.realNativeAdUnitId;

  Future<void> initialize() async {
    try {
      DebugLogger.logAdLoading('Initializing Mobile Ads SDK');
      
      await MobileAds.instance.initialize();
      
      final RequestConfiguration requestConfiguration = RequestConfiguration(
        testDeviceIds: _isTestMode ? ['TEST_DEVICE_ID'] : [],
        tagForChildDirectedTreatment: TagForChildDirectedTreatment.unspecified,
        maxAdContentRating: MaxAdContentRating.g,
      );
      
      MobileAds.instance.updateRequestConfiguration(requestConfiguration);
      
      DebugLogger.logAdSuccess('Mobile Ads SDK initialized successfully');
    } catch (e) {
      DebugLogger.logAdError('Failed to initialize Mobile Ads SDK', error: e);
      rethrow;
    }
  }

  BannerAd createBannerAd({
    AdSize? adSize,
    AdRequest? adRequest,
    void Function(Ad)? onAdLoaded,
    void Function(Ad, LoadAdError)? onAdFailedToLoad,
  }) {
    final bannerAd = BannerAd(
      adUnitId: bannerAdUnitId,
      size: adSize ?? AdSize.banner,
      request: adRequest ?? const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          DebugLogger.logAdSuccess('Banner ad loaded', adType: 'BANNER');
          onAdLoaded?.call(ad);
        },
        onAdFailedToLoad: (ad, error) {
          DebugLogger.logAdError('Banner ad failed to load', 
            adType: 'BANNER', error: error);
          onAdFailedToLoad?.call(ad, error);
          ad.dispose();
        },
        onAdOpened: (ad) => DebugLogger.logAdEvent('Banner ad opened', adType: 'BANNER'),
        onAdClosed: (ad) => DebugLogger.logAdEvent('Banner ad closed', adType: 'BANNER'),
        onAdImpression: (ad) => DebugLogger.logAdEvent('Banner ad impression', adType: 'BANNER'),
      ),
    );

    return bannerAd;
  }
}