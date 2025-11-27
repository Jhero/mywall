import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../data/services/admob_service.dart';
import '../../core/utils/debug_logger.dart';

class AdProvider with ChangeNotifier {
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  bool _isInterstitialLoading = false;
  bool _isRewardedLoading = false;
  int _interstitialLoadAttempts = 0;
  int _rewardedLoadAttempts = 0;

  // Getters
  bool get isInterstitialReady => _interstitialAd != null;
  bool get isRewardedReady => _rewardedAd != null;
  bool get isInterstitialLoading => _isInterstitialLoading;
  bool get isRewardedLoading => _isRewardedLoading;

  Future<void> loadInterstitialAd() async {
    if (_isInterstitialLoading || 
        _interstitialLoadAttempts >= AdmobConstants.maxFailedLoadAttempts) return;

    _isInterstitialLoading = true;
    notifyListeners();

    try {
      await InterstitialAd.load(
        adUnitId: AdmobService.interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            _interstitialAd = ad;
            _isInterstitialLoading = false;
            _interstitialLoadAttempts = 0;
            
            _setupInterstitialCallbacks(ad);
            notifyListeners();
            
            DebugLogger.logAdSuccess('Interstitial ad loaded');
          },
          onAdFailedToLoad: (LoadAdError error) {
            _isInterstitialLoading = false;
            _interstitialLoadAttempts++;
            _interstitialAd = null;
            notifyListeners();
            
            DebugLogger.logAdError('Interstitial ad failed to load', error: error);
          },
        ),
      );
    } catch (e) {
      _isInterstitialLoading = false;
      _interstitialLoadAttempts++;
      notifyListeners();
      
      DebugLogger.logAdError('Error loading interstitial ad', error: e);
    }
  }

  Future<void> showInterstitialAd() async {
    if (_interstitialAd != null) {
      await _interstitialAd!.show();
    } else {
      DebugLogger.logAdError('Interstitial ad not ready');
      await loadInterstitialAd();
    }
  }

  Future<void> loadRewardedAd() async {
    if (_isRewardedLoading || 
        _rewardedLoadAttempts >= AdmobConstants.maxFailedLoadAttempts) return;

    _isRewardedLoading = true;
    notifyListeners();

    try {
      await RewardedAd.load(
        adUnitId: AdmobService.rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (RewardedAd ad) {
            _rewardedAd = ad;
            _isRewardedLoading = false;
            _rewardedLoadAttempts = 0;
            
            _setupRewardedCallbacks(ad);
            notifyListeners();
            
            DebugLogger.logAdSuccess('Rewarded ad loaded');
          },
          onAdFailedToLoad: (LoadAdError error) {
            _isRewardedLoading = false;
            _rewardedLoadAttempts++;
            _rewardedAd = null;
            notifyListeners();
            
            DebugLogger.logAdError('Rewarded ad failed to load', error: error);
          },
        ),
      );
    } catch (e) {
      _isRewardedLoading = false;
      _rewardedLoadAttempts++;
      notifyListeners();
      
      DebugLogger.logAdError('Error loading rewarded ad', error: e);
    }
  }

  Future<void> showRewardedAd({
    required Function(RewardItem) onRewardEarned,
  }) async {
    if (_rewardedAd != null) {
      _rewardedAd!.setImmersiveMode(true);
      await _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          onRewardEarned(reward);
        },
      );
    } else {
      DebugLogger.logAdError('Rewarded ad not ready');
      await loadRewardedAd();
    }
  }

  void _setupInterstitialCallbacks(InterstitialAd ad) {
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        DebugLogger.logAdEvent('Interstitial ad showed full screen content');
      },
      onAdDismissedFullScreenContent: (ad) {
        DebugLogger.logAdEvent('Interstitial ad dismissed');
        ad.dispose();
        _interstitialAd = null;
        notifyListeners();
        loadInterstitialAd(); // Pre-load next ad
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        DebugLogger.logAdError('Interstitial ad failed to show', error: error);
        ad.dispose();
        _interstitialAd = null;
        notifyListeners();
        loadInterstitialAd(); // Pre-load next ad
      },
    );
  }

  void _setupRewardedCallbacks(RewardedAd ad) {
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        DebugLogger.logAdEvent('Rewarded ad showed full screen content');
      },
      onAdDismissedFullScreenContent: (ad) {
        DebugLogger.logAdEvent('Rewarded ad dismissed');
        ad.dispose();
        _rewardedAd = null;
        notifyListeners();
        loadRewardedAd(); // Pre-load next ad
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        DebugLogger.logAdError('Rewarded ad failed to show', error: error);
        ad.dispose();
        _rewardedAd = null;
        notifyListeners();
        loadRewardedAd(); // Pre-load next ad
      },
    );
  }

  @override
  void dispose() {
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    super.dispose();
  }
}