import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../data/services/admob_service.dart';
import '../../core/utils/debug_logger.dart';
import 'package:mywall/core/constants/admob_constants.dart';

class AdProvider with ChangeNotifier {
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  bool _isInterstitialLoading = false;
  bool _isRewardedLoading = false;
  int _interstitialLoadAttempts = 0;
  int _rewardedLoadAttempts = 0;
  bool _isDisposed = false;

  // Getters
  bool get isInterstitialReady => _interstitialAd != null && !_isDisposed;
  bool get isRewardedReady => _rewardedAd != null && !_isDisposed;
  bool get isInterstitialLoading => _isInterstitialLoading;
  bool get isRewardedLoading => _isRewardedLoading;

  AdProvider() {
    _initialize();
  }

  /// Initialize ads with error handling
  Future<void> _initialize() async {
    try {
      DebugLogger.logAdEvent('AdProvider initializing...');
      
      // Pre-load interstitial ad
      await loadInterstitialAd();
      
      // Pre-load rewarded ad
      loadRewardedAd();
      
      DebugLogger.logAdSuccess('AdProvider initialized successfully');
    } catch (e) {
      DebugLogger.logAdError('Error initializing AdProvider', error: e);
      // Don't throw, let app continue without ads
    }
  }

  /// Load Interstitial Ad with retry mechanism
  Future<void> loadInterstitialAd() async {
    if (_isDisposed) {
      DebugLogger.logAdError('AdProvider is disposed, cannot load ad');
      return;
    }

    if (_isInterstitialLoading) {
      DebugLogger.logAdEvent('Interstitial ad already loading');
      return;
    }

    if (_interstitialLoadAttempts >= AdmobConstants.maxFailedLoadAttempts) {
      DebugLogger.logAdError(
        'Max load attempts reached for interstitial ad ($_interstitialLoadAttempts)',
      );
      return;
    }

    _isInterstitialLoading = true;
    _safeNotifyListeners();

    try {
      await InterstitialAd.load(
        adUnitId: AdmobService.interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            if (_isDisposed) {
              ad.dispose();
              return;
            }

            _interstitialAd = ad;
            _isInterstitialLoading = false;
            _interstitialLoadAttempts = 0;
            
            _setupInterstitialCallbacks(ad);
            _safeNotifyListeners();
            
            DebugLogger.logAdSuccess('Interstitial ad loaded successfully');
          },
          onAdFailedToLoad: (LoadAdError error) {
            if (_isDisposed) return;

            _isInterstitialLoading = false;
            _interstitialLoadAttempts++;
            _interstitialAd = null;
            _safeNotifyListeners();
            
            DebugLogger.logAdError(
              'Interstitial ad failed to load (attempt $_interstitialLoadAttempts)',
              error: error,
            );

            // Retry after delay if not max attempts
            if (_interstitialLoadAttempts < AdmobConstants.maxFailedLoadAttempts) {
              Future.delayed(const Duration(seconds: 5), () {
                if (!_isDisposed) {
                  loadInterstitialAd();
                }
              });
            }
          },
        ),
      );
    } catch (e) {
      if (_isDisposed) return;

      _isInterstitialLoading = false;
      _interstitialLoadAttempts++;
      _safeNotifyListeners();
      
      DebugLogger.logAdError('Exception loading interstitial ad', error: e);
    }
  }

  /// Show Interstitial Ad with fallback
  Future<void> showInterstitialAd({VoidCallback? onAdDismissed}) async {
    if (_isDisposed) {
      DebugLogger.logAdError('AdProvider is disposed, cannot show ad');
      onAdDismissed?.call();
      return;
    }

    try {
      if (_interstitialAd != null) {
        // Update callback to include user's onAdDismissed
        _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
          onAdShowedFullScreenContent: (ad) {
            DebugLogger.logAdEvent('Interstitial ad showed full screen content');
          },
          onAdDismissedFullScreenContent: (ad) {
            DebugLogger.logAdEvent('Interstitial ad dismissed');
            ad.dispose();
            _interstitialAd = null;
            _safeNotifyListeners();
            
            onAdDismissed?.call();

            // Pre-load next ad
            if (!_isDisposed) {
              loadInterstitialAd();
            }
          },
          onAdFailedToShowFullScreenContent: (ad, error) {
            DebugLogger.logAdError('Interstitial ad failed to show', error: error);
            ad.dispose();
            _interstitialAd = null;
            _safeNotifyListeners();
            
            onAdDismissed?.call();

            // Pre-load next ad
            if (!_isDisposed) {
              loadInterstitialAd();
            }
          },
          onAdClicked: (ad) => DebugLogger.logAdEvent('Interstitial ad clicked'),
          onAdImpression: (ad) => DebugLogger.logAdEvent('Interstitial ad impression recorded'),
        );

        await _interstitialAd!.show();
        DebugLogger.logAdEvent('Showing interstitial ad');
      } else {
        DebugLogger.logAdError('Interstitial ad not ready, loading...');
        onAdDismissed?.call();
        await loadInterstitialAd();
      }
    } catch (e) {
      DebugLogger.logAdError('Error showing interstitial ad', error: e);
      // Dispose and reload
      _interstitialAd?.dispose();
      _interstitialAd = null;
      _safeNotifyListeners();
      onAdDismissed?.call();
      await loadInterstitialAd();
    }
  }

  /// Load Rewarded Ad with retry mechanism
  Future<void> loadRewardedAd() async {
    if (_isDisposed) {
      DebugLogger.logAdError('AdProvider is disposed, cannot load ad');
      return;
    }

    if (_isRewardedLoading) {
      DebugLogger.logAdEvent('Rewarded ad already loading');
      return;
    }

    if (_rewardedLoadAttempts >= AdmobConstants.maxFailedLoadAttempts) {
      DebugLogger.logAdError(
        'Max load attempts reached for rewarded ad ($_rewardedLoadAttempts)',
      );
      return;
    }

    _isRewardedLoading = true;
    _safeNotifyListeners();

    try {
      await RewardedAd.load(
        adUnitId: AdmobService.rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (RewardedAd ad) {
            if (_isDisposed) {
              ad.dispose();
              return;
            }

            _rewardedAd = ad;
            _isRewardedLoading = false;
            _rewardedLoadAttempts = 0;
            
            _setupRewardedCallbacks(ad);
            _safeNotifyListeners();
            
            DebugLogger.logAdSuccess('Rewarded ad loaded successfully');
          },
          onAdFailedToLoad: (LoadAdError error) {
            if (_isDisposed) return;

            _isRewardedLoading = false;
            _rewardedLoadAttempts++;
            _rewardedAd = null;
            _safeNotifyListeners();
            
            DebugLogger.logAdError(
              'Rewarded ad failed to load (attempt $_rewardedLoadAttempts)',
              error: error,
            );

            // Retry after delay if not max attempts
            if (_rewardedLoadAttempts < AdmobConstants.maxFailedLoadAttempts) {
              Future.delayed(const Duration(seconds: 5), () {
                if (!_isDisposed) {
                  loadRewardedAd();
                }
              });
            }
          },
        ),
      );
    } catch (e) {
      if (_isDisposed) return;

      _isRewardedLoading = false;
      _rewardedLoadAttempts++;
      _safeNotifyListeners();
      
      DebugLogger.logAdError('Exception loading rewarded ad', error: e);
    }
  }

  /// Show Rewarded Ad with callback
  Future<void> showRewardedAd({
    required Function(RewardItem) onRewardEarned,
    Function()? onAdDismissed,
  }) async {
    if (_isDisposed) {
      DebugLogger.logAdError('AdProvider is disposed, cannot show ad');
      onAdDismissed?.call();
      return;
    }

    try {
      if (_rewardedAd != null) {
        // Update callback to include user's onAdDismissed
        _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
          onAdShowedFullScreenContent: (ad) {
            DebugLogger.logAdEvent('Rewarded ad showed full screen content');
          },
          onAdDismissedFullScreenContent: (ad) {
            DebugLogger.logAdEvent('Rewarded ad dismissed');
            ad.dispose();
            _rewardedAd = null;
            _safeNotifyListeners();
            
            onAdDismissed?.call();

            // Pre-load next ad
            if (!_isDisposed) {
              loadRewardedAd();
            }
          },
          onAdFailedToShowFullScreenContent: (ad, error) {
            DebugLogger.logAdError('Rewarded ad failed to show', error: error);
            ad.dispose();
            _rewardedAd = null;
            _safeNotifyListeners();
            
            onAdDismissed?.call();

            // Pre-load next ad
            if (!_isDisposed) {
              loadRewardedAd();
            }
          },
          onAdClicked: (ad) => DebugLogger.logAdEvent('Rewarded ad clicked'),
          onAdImpression: (ad) => DebugLogger.logAdEvent('Rewarded ad impression recorded'),
        );

        _rewardedAd!.setImmersiveMode(true);
        await _rewardedAd!.show(
          onUserEarnedReward: (ad, reward) {
            DebugLogger.logAdSuccess(
              'User earned reward: ${reward.amount} ${reward.type}',
            );
            onRewardEarned(reward);
          },
        );
        DebugLogger.logAdEvent('Showing rewarded ad');
      } else {
        DebugLogger.logAdError('Rewarded ad not ready, loading...');
        onAdDismissed?.call();
        await loadRewardedAd();
      }
    } catch (e) {
      DebugLogger.logAdError('Error showing rewarded ad', error: e);
      // Dispose and reload
      _rewardedAd?.dispose();
      _rewardedAd = null;
      _safeNotifyListeners();
      onAdDismissed?.call();
      await loadRewardedAd();
    }
  }

  /// Setup Interstitial Ad Callbacks
  void _setupInterstitialCallbacks(InterstitialAd ad) {
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        DebugLogger.logAdEvent('Interstitial ad showed full screen content');
      },
      onAdDismissedFullScreenContent: (ad) {
        DebugLogger.logAdEvent('Interstitial ad dismissed');
        ad.dispose();
        _interstitialAd = null;
        _safeNotifyListeners();
        
        // Pre-load next ad
        if (!_isDisposed) {
          loadInterstitialAd();
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        DebugLogger.logAdError('Interstitial ad failed to show', error: error);
        ad.dispose();
        _interstitialAd = null;
        _safeNotifyListeners();
        
        // Pre-load next ad
        if (!_isDisposed) {
          loadInterstitialAd();
        }
      },
      onAdClicked: (ad) {
        DebugLogger.logAdEvent('Interstitial ad clicked');
      },
      onAdImpression: (ad) {
        DebugLogger.logAdEvent('Interstitial ad impression recorded');
      },
    );
  }

  /// Setup Rewarded Ad Callbacks
  void _setupRewardedCallbacks(RewardedAd ad) {
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        DebugLogger.logAdEvent('Rewarded ad showed full screen content');
      },
      onAdDismissedFullScreenContent: (ad) {
        DebugLogger.logAdEvent('Rewarded ad dismissed');
        ad.dispose();
        _rewardedAd = null;
        _safeNotifyListeners();
        
        // Pre-load next ad
        if (!_isDisposed) {
          loadRewardedAd();
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        DebugLogger.logAdError('Rewarded ad failed to show', error: error);
        ad.dispose();
        _rewardedAd = null;
        _safeNotifyListeners();
        
        // Pre-load next ad
        if (!_isDisposed) {
          loadRewardedAd();
        }
      },
      onAdClicked: (ad) {
        DebugLogger.logAdEvent('Rewarded ad clicked');
      },
      onAdImpression: (ad) {
        DebugLogger.logAdEvent('Rewarded ad impression recorded');
      },
    );
  }

  /// Safe notify listeners that checks disposal state
  void _safeNotifyListeners() {
    if (!_isDisposed) {
      try {
        notifyListeners();
      } catch (e) {
        DebugLogger.logAdError('Error notifying listeners', error: e);
      }
    }
  }

  /// Reset load attempts (useful after successful show)
  void resetLoadAttempts() {
    _interstitialLoadAttempts = 0;
    _rewardedLoadAttempts = 0;
    DebugLogger.logAdEvent('Load attempts reset');
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    
    _isDisposed = true;
    
    try {
      _interstitialAd?.dispose();
      _interstitialAd = null;
      
      _rewardedAd?.dispose();
      _rewardedAd = null;
      
      DebugLogger.logAdEvent('AdProvider disposed');
    } catch (e) {
      DebugLogger.logAdError('Error disposing AdProvider', error: e);
    }
    
    super.dispose();
  }
}